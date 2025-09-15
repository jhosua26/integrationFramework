/**
 * @description Integration Framework - Version 8
 * @author Jhosua R. Arda
 * @version 8.0
 * @purpose This framework is being used in Accenture projects and freelancing work.
 *          DO NOT MODIFY this class as it is part of the framework.
 *          Modifying this class will destroy the framework functionality.
 * 
 * Manages retry logic with exponential backoff for integration operations
 */
public class RetryManager {
    
    private static final Integer DEFAULT_MAX_RETRIES = 3;
    private static final Integer DEFAULT_BASE_DELAY_MS = 1000; // 1 second
    private static final Integer MAX_DELAY_MS = 30000; // 30 seconds
    private static final Double BACKOFF_MULTIPLIER = 2.0;
    
    private final IIntegrationLogger logger;
    private final Integer maxRetries;
    private final Integer baseDelayMs;
    private final FrameworkErrorHandler errorHandler;
    
    private static RetryManager instance;
    
    /**
     * Gets the singleton instance of RetryManager
     * 
     * Returns a shared instance with default settings (3 retries, 1 second base delay).
     * Use this for most scenarios unless you need custom retry settings.
     */
    public static RetryManager getInstance() {
        if (instance == null) {
            instance = new RetryManager(
                IntegrationLogger.getInstance(),
                new FrameworkErrorHandler(),
                3, // maxRetries
                1000 // baseDelayMs
            );
        }
        return instance;
    }
    
    /**
     * Constructor with dependency injection
     * 
     * logger - Logger implementation for tracking retry attempts
     * maxRetries - Maximum number of retry attempts (typically 2-5)
     * baseDelayMs - Base delay in milliseconds for exponential backoff (1000-2000 recommended)
     */
    public RetryManager(IIntegrationLogger logger, Integer maxRetries, Integer baseDelayMs) {
        if (logger == null) {
            throw new IllegalArgumentException('Logger cannot be null');
        }
        
        this.logger = logger;
        this.maxRetries = maxRetries != null ? maxRetries : DEFAULT_MAX_RETRIES;
        this.baseDelayMs = baseDelayMs != null ? baseDelayMs : DEFAULT_BASE_DELAY_MS;
        this.errorHandler = new FrameworkErrorHandler(logger);
    }
    
    /**
     * Default constructor with default retry settings
     * 
     * logger - Logger implementation for tracking retry attempts
     * Uses default settings: 3 max retries, 1000ms base delay
     */
    public RetryManager(IIntegrationLogger logger) {
        this(logger, DEFAULT_MAX_RETRIES, DEFAULT_BASE_DELAY_MS);
    }
    
    /**
     * Constructor with framework error handler
     * 
     * logger - Logger implementation for tracking retry attempts
     * errorHandler - Framework error handler for error processing
     * maxRetries - Maximum number of retry attempts (typically 2-5)
     * baseDelayMs - Base delay in milliseconds for exponential backoff (1000-2000 recommended)
     */
    public RetryManager(IIntegrationLogger logger, FrameworkErrorHandler errorHandler, Integer maxRetries, Integer baseDelayMs) {
        if (logger == null) {
            throw new IllegalArgumentException('Logger cannot be null');
        }
        
        if (errorHandler == null) {
            throw new IllegalArgumentException('Error handler cannot be null');
        }
        
        this.logger = logger;
        this.errorHandler = errorHandler;
        this.maxRetries = maxRetries != null ? maxRetries : DEFAULT_MAX_RETRIES;
        this.baseDelayMs = baseDelayMs != null ? baseDelayMs : DEFAULT_BASE_DELAY_MS;
    }
    
    /**
     * Executes an operation with retry logic and exponential backoff
     * 
     * This method automatically retries failed operations with increasing delays.
     * Only retries on retryable errors (5xx, timeouts, rate limits).
     * 
     * operation - The operation to execute (must implement RetryableOperation)
     * correlationId - Unique identifier for tracking this request
     * systemName - Name of the external system for logging
     * context - Additional context information for debugging
     * Returns RetryResult with success status and retry details
     */
    public RetryResult executeWithRetry(RetryableOperation operation, String correlationId, 
                                      String systemName, Map<String, Object> context) {
        if (operation == null) {
            throw new IllegalArgumentException('Operation cannot be null');
        }
        
        if (String.isBlank(correlationId)) {
            throw new IllegalArgumentException('Correlation ID cannot be null or empty');
        }
        
        if (String.isBlank(systemName)) {
            throw new IllegalArgumentException('System name cannot be null or empty');
        }
        
        Integer retryCount = 0;
        Long totalProcessingTime = 0;
        Exception lastException = null;
        
        while (retryCount < maxRetries) {
            Long startTime = System.currentTimeMillis();
            
            try {
                // Execute the operation
                Object result = operation.execute();
                Long processingTime = System.currentTimeMillis() - startTime;
                totalProcessingTime += processingTime;
                
                // Log retry success (but don't duplicate outbound logging since HttpRequestOperation handles it)
                logRetrySuccess(correlationId, systemName, retryCount, processingTime, context);
                
                return new RetryResult(true, result, retryCount, totalProcessingTime, null);
                
            } catch (Exception e) {
                Long processingTime = System.currentTimeMillis() - startTime;
                totalProcessingTime += processingTime;
                lastException = e;
                
                // Log the error
                logRetryError(correlationId, systemName, retryCount, e, processingTime, context);
                
                // Check if we should retry
                if (retryCount >= maxRetries || !isRetryableError(e)) {
                    break;
                }
                
                // Calculate delay for exponential backoff
                Integer delayMs = calculateBackoffDelay(retryCount);
                
                // Log retry attempt
                logRetryAttempt(correlationId, systemName, retryCount, delayMs, context);
                
                // Check if we should use Queueable retry for production
                if (isProductionEnvironment()) {
                    // Use Queueable retry to avoid platform limitations
                    scheduleQueueableRetry(correlationId, systemName, retryCount, delayMs, context);
                    return new RetryResult(false, null, retryCount, totalProcessingTime, e); // Exit immediately
                } else {
                    // For testing/development, simulate delay
                    if (delayMs > 0) {
                        System.debug('Simulating delay of ' + delayMs + 'ms before retry ' + (retryCount + 1));
                    }
                }
                
                retryCount++;
            }
        }
        
        // All retries exhausted (only log if not using queueable retry)
        if (!isProductionEnvironment()) {
            logRetryExhausted(correlationId, systemName, retryCount, lastException, totalProcessingTime, context);
        }
        
        return new RetryResult(false, null, retryCount, totalProcessingTime, lastException);
    }
    
    /**
     * Determines if an error is retryable
     * 
     * Checks if the exception should trigger a retry attempt.
     * Retryable errors: 5xx server errors, timeouts, rate limits.
     * Non-retryable errors: 4xx client errors, authentication failures.
     * 
     * ex - The exception to check
     * Returns true if the error is retryable, false otherwise
     */
    private Boolean isRetryableError(Exception ex) {
        if (ex == null) {
            return false;
        }
        
        // Check for specific retryable error types
        String errorMessage = ex.getMessage();
        if (errorMessage != null) {
            errorMessage = errorMessage.toLowerCase();
            
            // Network and timeout errors
            if (errorMessage.contains('timeout') || 
                errorMessage.contains('connection') ||
                errorMessage.contains('network') ||
                errorMessage.contains('unavailable') ||
                errorMessage.contains('service unavailable')) {
                return true;
            }
            
            // HTTP 5xx errors (server errors) - RETRYABLE
            if (errorMessage.contains('500') || 
                errorMessage.contains('502') ||
                errorMessage.contains('503') ||
                errorMessage.contains('504')) {
                return true;
            }
            
            // HTTP 4xx errors - NOT RETRYABLE (except 429)
            if (errorMessage.contains('400') || 
                errorMessage.contains('401') ||
                errorMessage.contains('403') ||
                errorMessage.contains('404') ||
                errorMessage.contains('405') ||
                errorMessage.contains('406') ||
                errorMessage.contains('407') ||
                errorMessage.contains('408') ||
                errorMessage.contains('409') ||
                errorMessage.contains('410') ||
                errorMessage.contains('411') ||
                errorMessage.contains('412') ||
                errorMessage.contains('413') ||
                errorMessage.contains('414') ||
                errorMessage.contains('415') ||
                errorMessage.contains('416') ||
                errorMessage.contains('417') ||
                errorMessage.contains('418') ||
                errorMessage.contains('422') ||
                errorMessage.contains('423') ||
                errorMessage.contains('424') ||
                errorMessage.contains('425') ||
                errorMessage.contains('426') ||
                errorMessage.contains('428') ||
                errorMessage.contains('431') ||
                errorMessage.contains('451')) {
                return false; // 4xx errors are client errors, not retryable
            }
            
            // Rate limiting (429) - RETRYABLE
            if (errorMessage.contains('429') || 
                errorMessage.contains('rate limit') ||
                errorMessage.contains('too many requests')) {
                return true;
            }
        }
        
        // Check for specific exception types
        if (ex instanceof CalloutException) {
            // CalloutException is generally retryable unless it's a specific client error
            String calloutMessage = ex.getMessage().toLowerCase();
            if (calloutMessage.contains('400') || 
                calloutMessage.contains('401') ||
                calloutMessage.contains('403') ||
                calloutMessage.contains('404')) {
                return false; // Client errors are not retryable
            }
            return true; // Most callout exceptions are retryable
        }
        
        return false;
    }
    
    /**
     * Calculates the delay for exponential backoff
     * 
     * Uses exponential backoff with jitter to avoid thundering herd problems.
     * Delay increases with each retry: baseDelay * (2^retryCount) + random jitter.
     * 
     * retryCount - Current retry attempt number (0-based)
     * Returns delay in milliseconds (capped at 30 seconds)
     */
    private Integer calculateBackoffDelay(Integer retryCount) {
        if (retryCount <= 0) {
            return 0;
        }
        
        // Exponential backoff: baseDelay * (backoffMultiplier ^ (retryCount - 1))
        Double delay = baseDelayMs * Math.pow(BACKOFF_MULTIPLIER, retryCount - 1);
        
        // Add jitter to prevent thundering herd
        Double jitter = Math.random() * 0.1 * delay; // 10% jitter
        delay += jitter;
        
        // Cap the delay at maximum
        delay = Math.min(delay, MAX_DELAY_MS);
        
        return delay.intValue();
    }
    
    /**
     * Logs a successful retry operation
     * 
     * Records when a retry attempt succeeds, including retry count and timing.
     * Updates the existing log record with retry information.
     */
    private void logRetrySuccess(String correlationId, String systemName, Integer retryCount, 
                                Long processingTime, Map<String, Object> context) {
        // Update the existing log record with retry information instead of creating a new outbound message
        Map<String, Object> additionalData = new Map<String, Object>{
            'retryCount' => retryCount,
            'processingTime' => processingTime,
            'status' => 'Completed'
        };
        
        logger.updateLogStatus(correlationId, 'Completed', additionalData);
    }
    
    /**
     * @description Logs a retry error with enhanced error handling
     */
    private void logRetryError(String correlationId, String systemName, Integer retryCount, 
                               Exception ex, Long processingTime, Map<String, Object> context) {
        // Only log errors for the initial attempt, not for retries (RetryQueueable will handle retry errors)
        if (retryCount > 0) {
            return;
        }
        
        Map<String, Object> enhancedContext = new Map<String, Object>{
            'retryCount' => retryCount,
            'processingTime' => processingTime,
            'exceptionType' => ex.getTypeName(),
            'systemName' => systemName,
            'maxRetries' => maxRetries,
            'context' => context
        };
        
        String errorType = 'RETRY_ERROR';
        String severity = retryCount >= maxRetries ? 'High' : 'Medium';
        
        // Use framework error handler for error logging
        errorHandler.logFrameworkError(
            correlationId, 
            errorType, 
            'Retry attempt ' + (retryCount + 1) + ' failed: ' + ex.getMessage(),
            ex.getStackTraceString(), 
            severity, 
            enhancedContext,
            retryCount + 1
        );
    }
    
    /**
     * @description Logs a retry attempt
     */
    private void logRetryAttempt(String correlationId, String systemName, Integer retryCount, 
                                Integer delayMs, Map<String, Object> context) {
        // Don't create duplicate log records - let HttpRequestOperation handle the actual logging
        // Just log the retry scheduling for debugging
        System.debug('Retry attempt ' + (retryCount + 1) + ' scheduled with ' + delayMs + 'ms delay for correlation ID: ' + correlationId);
    }
    
    /**
     * @description Logs when all retries are exhausted with enhanced error handling
     */
    private void logRetryExhausted(String correlationId, String systemName, Integer retryCount, 
                                   Exception ex, Long totalProcessingTime, Map<String, Object> context) {
        // Only log exhaustion for the initial attempt, not for retries (RetryQueueable will handle retry exhaustion)
        if (retryCount > 0) {
            return;
        }
        
        Map<String, Object> enhancedContext = new Map<String, Object>{
            'retryCount' => retryCount,
            'totalProcessingTime' => totalProcessingTime,
            'maxRetries' => maxRetries,
            'systemName' => systemName,
            'context' => context
        };
        
        String errorMessage = 'Retry mechanism exhausted: ' + retryCount + ' attempts completed over ' + 
                            totalProcessingTime + 'ms. System: ' + systemName;
        
        if (ex != null) {
            errorMessage += '. Final error: ' + ex.getMessage();
        }
        
        // Use framework error handler for error logging
        errorHandler.logFrameworkError(
            correlationId, 
            'RETRY_EXHAUSTED', 
            errorMessage,
            ex != null ? ex.getStackTraceString() : '', 
            'HIGH', 
            enhancedContext,
            retryCount
        );
    }
    
    
    
    
    
    /**
     * @description Updates the retry count for a specific correlation ID (for testing)
     * @param correlationId Correlation ID to update
     * @param retryCount New retry count
     */
    @TestVisible
    public void updateRetryCount(String correlationId, Integer retryCount) {
        if (String.isBlank(correlationId)) {
            throw new IllegalArgumentException('Correlation ID cannot be null or empty');
        }
        
        if (retryCount == null || retryCount < 0) {
            throw new IllegalArgumentException('Retry count must be non-negative');
        }
        
        try {
            List<Integration_Error__c> errors = [
                SELECT Id, Retry_Count__c 
                FROM Integration_Error__c 
                WHERE Correlation_ID__c = :correlationId 
                LIMIT 1
            ];
            
            if (!errors.isEmpty()) {
                Integration_Error__c error = errors[0];
                error.Retry_Count__c = retryCount;
                update error;
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to update retry count: ' + e.getMessage());
        }
    }
    
    /**
     * @description Gets the current retry count for a correlation ID (for testing)
     * @param correlationId Correlation ID to check
     * @return Current retry count or 0 if not found
     */
    @TestVisible
    public Integer getRetryCount(String correlationId) {
        if (String.isBlank(correlationId)) {
            return 0;
        }
        
        try {
            List<Integration_Error__c> errors = [
                SELECT Retry_Count__c 
                FROM Integration_Error__c 
                WHERE Correlation_ID__c = :correlationId 
                LIMIT 1
            ];
            
            return !errors.isEmpty() ? (Integer) errors[0].Retry_Count__c : 0;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to get retry count: ' + e.getMessage());
            return 0;
        }
    }
    
    /**
     * @description Gets the maximum retry attempts configured (for testing)
     * @return Maximum retry attempts
     */
    @TestVisible
    public Integer getMaxRetries() {
        return maxRetries;
    }
    
    /**
     * @description Gets the base delay configured (for testing)
     * @return Base delay in milliseconds
     */
    @TestVisible
    public Integer getBaseDelayMs() {
        return baseDelayMs;
    }
    
    /**
     * @description Determines if we're in a production environment
     * @return Boolean indicating if production environment
     */
    private Boolean isProductionEnvironment() {
        // Use configurable environment detection
        FrameworkConfigManager configManager = FrameworkConfigManager.getInstance();
        
        // Check if Queueable retry is explicitly enabled
        if (configManager.isQueueableRetryEnabled()) {
            return true;
        }
        
        // Check environment type
        if (configManager.isProductionEnvironment()) {
            return true;
        }
        
        // Default to false if no explicit configuration
        return false;
    }
    
    /**
     * @description Schedule Queueable retry to avoid platform limitations
     * @param correlationId Correlation ID
     * @param systemName System name
     * @param retryCount Current retry count
     * @param delayMs Delay in milliseconds
     * @param context Additional context
     */
    private void scheduleQueueableRetry(String correlationId, String systemName, 
                                      Integer retryCount, Integer delayMs, Map<String, Object> context) {
        try {
            // Extract retry information from context
            String endpoint = (String) context.get('endpoint');
            String payload = (String) context.get('payload');
            Map<String, String> headers = (Map<String, String>) context.get('headers');
            String httpMethod = (String) context.get('method');
            
            if (String.isNotBlank(endpoint)) {
                // Schedule Queueable retry
                RetryQueueable.scheduleRetry(
                    correlationId, endpoint, payload, headers, systemName, httpMethod,
                    maxRetries, baseDelayMs, context
                );
                
                System.debug('Scheduled Queueable retry for correlation ID: ' + correlationId);
            } else {
                System.debug(LoggingLevel.WARN, 'Cannot schedule Queueable retry - missing endpoint in context');
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to schedule Queueable retry: ' + e.getMessage());
        }
    }
}