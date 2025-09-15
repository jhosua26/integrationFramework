/**
 * @description Integration Framework - Version 8
 * @author Jhosua R. Arda
 * @version 8.0
 * @purpose This framework is being used in Accenture projects and freelancing work.
 *          DO NOT MODIFY this class as it is part of the framework.
 *          Modifying this class will destroy the framework functionality.
 * 
 * Handles retry logic asynchronously to avoid Salesforce platform limitations:
 * - Executes retry attempts in separate transactions
 * - Avoids "uncommitted work pending" errors
 * - Maintains retry count and exponential backoff
 * - Provides comprehensive logging
 * 
 * Follows principles: SOLID, dependency injection, guard clauses
 */
public class RetryQueueable implements Queueable, Database.AllowsCallouts {
    
    private static final Integer MAX_QUEUEABLE_RETRIES = 5; // Salesforce limit
    
    private final String correlationId;
    private final String endpoint;
    private final String payload;
    private final Map<String, String> headers;
    private final String systemName;
    private final String httpMethod; // Add HTTP method parameter
    private final Integer currentRetryCount;
    private final Integer maxRetries;
    private final Integer baseDelayMs;
    private final Map<String, Object> context;
    private final FrameworkErrorHandler errorHandler;
    
    /**
     * Constructor for retry queueable
     * 
     * Creates a new retry queueable for asynchronous retry execution.
     * Handles retry attempts in separate transactions to avoid platform limitations.
     * 
     * correlationId - Unique identifier for tracking this request
     * endpoint - API endpoint to call during retry
     * payload - Request payload to send
     * headers - Request headers (optional - named credentials handle auth)
     * systemName - System name for logging and identification
     * currentRetryCount - Current retry attempt number (0-based)
     * maxRetries - Maximum retry attempts allowed
     * baseDelayMs - Base delay for exponential backoff calculation
     * context - Additional context information for debugging
     */
    public RetryQueueable(String correlationId, String endpoint, String payload, 
                         Map<String, String> headers, String systemName, 
                         String httpMethod, Integer currentRetryCount, Integer maxRetries, 
                         Integer baseDelayMs, Map<String, Object> context) {
        
        if (String.isBlank(correlationId)) {
            throw new IllegalArgumentException('Correlation ID cannot be null or empty');
        }
        
        if (String.isBlank(endpoint)) {
            throw new IllegalArgumentException('Endpoint cannot be null or empty');
        }
        
        if (String.isBlank(systemName)) {
            throw new IllegalArgumentException('System name cannot be null or empty');
        }
        
        if (String.isBlank(httpMethod)) {
            throw new IllegalArgumentException('HTTP method cannot be null or empty');
        }
        
        this.correlationId = correlationId;
        this.endpoint = endpoint;
        this.payload = payload;
        this.headers = headers;
        this.systemName = systemName;
        this.httpMethod = httpMethod.toUpperCase();
        this.currentRetryCount = currentRetryCount != null ? currentRetryCount : 0;
        this.maxRetries = maxRetries != null ? maxRetries : 3;
        this.baseDelayMs = baseDelayMs != null ? baseDelayMs : 1000;
        this.context = context;
        
        // Initialize error handler only (no logger needed for direct logging)
        this.errorHandler = new FrameworkErrorHandler(new IntegrationLogger());
    }
    
    /**
     * @description Execute the retry attempt
     * @param context Queueable context
     */
    public void execute(QueueableContext context) {
        Long startTime = System.currentTimeMillis();
        HttpResponse response = null;
        Exception calloutException = null;
        
        try {
            // Make direct HTTP callout FIRST (no DML before callout)
            HttpRequest request = prepareHttpRequest(endpoint, payload, headers, httpMethod);
            Http http = new Http();
            response = http.send(request);
            
        } catch (Exception e) {
            // Capture exception but don't log yet (avoid DML before callout)
            calloutException = e;
        }
        
        // Calculate processing time
        Long processingTime = System.currentTimeMillis() - startTime;
        
        // NOW we can do DML operations (after callout)
        try {
            System.debug('RetryQueueable execute - Attempt ' + (currentRetryCount + 1) + ' for correlation ID: ' + correlationId);
            
            // Log retry outbound message (after callout)
            logRetryOutboundMessage();
            
            if (calloutException != null) {
                // Handle callout exception
                System.debug('Callout exception occurred in attempt ' + (currentRetryCount + 1) + ': ' + calloutException.getMessage());
                handleRetryException(calloutException);
                return;
            }
            
            // Log retry inbound message (after callout)
            logRetryInboundMessage(response, processingTime);
            
            System.debug('Response status code: ' + response.getStatusCode() + ' for attempt ' + (currentRetryCount + 1));
            
            // Check if successful
            if (response.getStatusCode() >= 200 && response.getStatusCode() < 300) {
                // Success - complete
                System.debug('Queueable retry attempt ' + (currentRetryCount + 1) + ' succeeded for correlation ID: ' + correlationId);
                return;
            }
            
            // Check if we should retry
            if (currentRetryCount >= maxRetries || !isRetryableStatusCode(response.getStatusCode())) {
                // Max retries reached or non-retryable error
                System.debug('Max retries reached or non-retryable error for attempt ' + (currentRetryCount + 1));
                logRetryExhausted(response, processingTime);
                return;
            }
            
            // Log error for HTTP error status codes (only for retries that will continue)
            logHttpError(response, processingTime);
            
            // Schedule next retry
            System.debug('Scheduling next retry for attempt ' + (currentRetryCount + 1));
            scheduleNextRetry(response, processingTime);
            
        } catch (Exception e) {
            // Handle logging exceptions
            System.debug(LoggingLevel.ERROR, 'Failed to process retry result: ' + e.getMessage());
        }
    }
    
    /**
     * @description Log retry outbound message
     */
    @TestVisible
    private void logRetryOutboundMessage() {
        try {
            Map<String, Object> context = new Map<String, Object>{
                'endpoint' => endpoint,
                'method' => httpMethod,
                'headers' => headers != null ? headers : new Map<String, String>(),
                'retryCount' => currentRetryCount + 1,
                'maxRetries' => maxRetries,
                'usesNamedCredential' => headers == null || headers.isEmpty(),
                'isRetryAttempt' => true,
                'queueableExecution' => true
            };
            
            IntegrationLogger logger = new IntegrationLogger();
            logger.logOutboundMessage(
                correlationId,
                systemName,
                payload,
                context
            );
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to log retry outbound message: ' + e.getMessage());
        }
    }
    
    /**
     * @description Log retry inbound message
     * @param response HTTP response
     * @param processingTime Processing time in milliseconds
     */
    @TestVisible
    private void logRetryInboundMessage(HttpResponse response, Long processingTime) {
        try {
            Map<String, Object> context = new Map<String, Object>{
                'statusCode' => response.getStatusCode(),
                'processingTime' => processingTime,
                'responseHeaders' => extractResponseHeaders(response),
                'retryCount' => currentRetryCount + 1,
                'maxRetries' => maxRetries,
                'success' => response.getStatusCode() >= 200 && response.getStatusCode() < 300,
                'isRetryAttempt' => true,
                'queueableExecution' => true
            };
            
            IntegrationLogger logger = new IntegrationLogger();
            logger.logInboundMessage(
                correlationId,
                systemName,
                response.getBody(),
                context
            );
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to log retry inbound message: ' + e.getMessage());
        }
    }
    
    /**
     * @description Extract response headers from HttpResponse
     * @param response HTTP response
     * @return Map of response headers
     */
    @TestVisible
    private Map<String, String> extractResponseHeaders(HttpResponse response) {
        Map<String, String> headers = new Map<String, String>();
        if (response != null && response.getHeaderKeys() != null) {
            for (String key : response.getHeaderKeys()) {
                headers.put(key, response.getHeader(key));
            }
        }
        return headers;
    }
    
    /**
     * @description Log retry exhaustion
     * @param response HTTP response
     * @param processingTime Processing time in milliseconds
     */
    @TestVisible
    private void logRetryExhausted(HttpResponse response, Long processingTime) {
        try {
            // Log error for this retry attempt
            Map<String, Object> exhaustedContext = new Map<String, Object>{
                'retryCount' => currentRetryCount + 1,
                'maxRetries' => maxRetries,
                'processingTime' => processingTime,
                'systemName' => systemName,
                'endpoint' => endpoint,
                'statusCode' => response.getStatusCode(),
                'responseBody' => response.getBody(),
                'context' => context,
                'queueableExecution' => true,
                'finalAttempt' => (currentRetryCount + 1 >= maxRetries)
            };
            
            String errorMessage = 'Queueable retry attempt ' + (currentRetryCount + 1) + '/' + maxRetries + ' failed: HTTP ' + response.getStatusCode() + ' from ' + systemName + ' endpoint: ' + endpoint;
            String severity = (currentRetryCount + 1 >= maxRetries) ? 'HIGH' : 'MEDIUM';
            
            errorHandler.logFrameworkError(
                correlationId,
                'PLATFORM',
                errorMessage,
                'HTTP Error: Status ' + response.getStatusCode() + ' returned from endpoint: ' + endpoint,
                severity,
                exhaustedContext,
                currentRetryCount + 1
            );
            
            System.debug('Queueable retry attempt ' + (currentRetryCount + 1) + ' failed for correlation ID: ' + correlationId);
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to log retry exhaustion: ' + e.getMessage());
        }
    }
    
    /**
     * @description Schedule next retry attempt
     * @param response Current HTTP response
     * @param processingTime Processing time in milliseconds
     */
    @TestVisible
    private void scheduleNextRetry(HttpResponse response, Long processingTime) {
        try {
            // Calculate delay for exponential backoff
            Integer delayMs = calculateBackoffDelay(currentRetryCount);
            
            // Don't log intermediate retry failures to avoid duplicate error records
            // The HttpRequestOperation already logs the actual HTTP callout results
            
            // Schedule next retry if within limits
            // currentRetryCount represents the attempt number (0, 1, 2)
            // We want to retry until we've made maxRetries attempts total
            if (currentRetryCount < maxRetries - 1 && currentRetryCount < MAX_QUEUEABLE_RETRIES - 1) {
                RetryQueueable nextRetry = new RetryQueueable(
                    correlationId, endpoint, payload, headers, systemName, httpMethod,
                    currentRetryCount + 1, maxRetries, baseDelayMs, context
                );
                
                // Use System.enqueueJob for immediate execution (Queueable doesn't support delays)
                // Note: In production, consider using Scheduled jobs for delays
                System.enqueueJob(nextRetry);
                
                System.debug('Scheduled next retry attempt ' + (currentRetryCount + 2) + ' for correlation ID: ' + correlationId);
            } else {
                System.debug('Max retries reached (' + maxRetries + ') or Queueable limit reached for correlation ID: ' + correlationId);
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to schedule next retry: ' + e.getMessage());
        }
    }
    
    /**
     * @description Log HTTP error status codes
     * @param response HTTP response with error status code
     * @param processingTime Processing time in milliseconds
     */
    @TestVisible
    private void logHttpError(HttpResponse response, Long processingTime) {
        try {
            Map<String, Object> context = new Map<String, Object>{
                'endpoint' => endpoint,
                'processingTime' => processingTime,
                'statusCode' => response.getStatusCode(),
                'responseHeaders' => extractResponseHeaders(response),
                'systemName' => systemName,
                'payload' => payload,
                'headers' => headers != null ? headers : new Map<String, String>(),
                'retryCount' => currentRetryCount + 1,
                'maxRetries' => maxRetries,
                'queueableExecution' => true
            };
            
            String severity = response.getStatusCode() >= 500 ? 'HIGH' : 'MEDIUM';
            String errorMessage = 'HTTP ' + response.getStatusCode() + ' error: ' + response.getBody();
            
            errorHandler.logFrameworkError(
                correlationId,
                'HTTP_CALLOUT_ERROR',
                errorMessage,
                'HTTP Error: Status ' + response.getStatusCode() + ' returned from endpoint: ' + endpoint,
                severity,
                context,
                currentRetryCount + 1
            );
            
            System.debug('Logged HTTP error for retry attempt ' + (currentRetryCount + 1) + ' with status code ' + response.getStatusCode());
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to log HTTP error: ' + e.getMessage());
        }
    }
    
    /**
     * @description Handle retry exceptions
     * @param ex Exception that occurred
     */
    private void handleRetryException(Exception ex) {
        try {
            // Log error for this retry attempt
            Map<String, Object> exceptionContext = new Map<String, Object>{
                'retryCount' => currentRetryCount + 1,
                'maxRetries' => maxRetries,
                'systemName' => systemName,
                'endpoint' => endpoint,
                'exceptionType' => ex.getTypeName(),
                'context' => context,
                'queueableExecution' => true
            };
            
            String errorMessage = 'Retry attempt ' + (currentRetryCount + 1) + ' failed: ' + ex.getMessage();
            String severity = (currentRetryCount + 1 >= maxRetries) ? 'HIGH' : 'MEDIUM';
            
            errorHandler.logFrameworkError(
                correlationId,
                'PLATFORM',
                errorMessage,
                ex.getStackTraceString(),
                severity,
                exceptionContext,
                currentRetryCount + 1
            );
            
            System.debug('Queueable retry attempt ' + (currentRetryCount + 1) + ' failed with exception for correlation ID: ' + correlationId);
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to handle retry exception: ' + e.getMessage());
        }
    }
    
    /**
     * @description Determine if status code is retryable
     * @param statusCode HTTP status code
     * @return Boolean indicating if retryable
     */
    private Boolean isRetryableStatusCode(Integer statusCode) {
        // Retry 5xx server errors
        if (statusCode >= 500 && statusCode < 600) {
            return true;
        }
        
        // Retry 429 (rate limiting)
        if (statusCode == 429) {
            return true;
        }
        
        // Don't retry 4xx client errors
        return false;
    }
    
    /**
     * @description Calculate exponential backoff delay
     * @param retryCount Current retry count
     * @return Delay in milliseconds
     */
    @TestVisible
    private Integer calculateBackoffDelay(Integer retryCount) {
        if (retryCount <= 0) {
            return 0;
        }
        
        // Exponential backoff: baseDelay * (2 ^ (retryCount - 1))
        Integer delay = baseDelayMs;
        for (Integer i = 1; i < retryCount; i++) {
            delay = delay * 2;
        }
        
        // Add jitter to prevent thundering herd
        Integer jitter = (Integer)(Math.random() * delay * 0.1); // 10% jitter
        delay = delay + jitter;
        
        // Cap the delay at 30 seconds
        if (delay > 30000) {
            delay = 30000;
        }
        
        return delay;
    }
    
    /**
     * @description Prepares an HTTP request with the given parameters
     * @param endpoint The endpoint URL
     * @param payload The request payload
     * @param headers Request headers (optional - named credentials handle auth)
     * @param method HTTP method (GET, POST, PUT, PATCH, DELETE)
     * @return HttpRequest prepared request
     */
    private HttpRequest prepareHttpRequest(String endpoint, String payload, Map<String, String> headers, String method) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod(method);
        request.setTimeout(30000); // 30 second timeout
        
        // Only set body for methods that support it
        if (!String.isBlank(payload) && (method == 'POST' || method == 'PUT' || method == 'PATCH')) {
            request.setBody(payload);
        }
        
        // Add custom headers (only if provided and not using named credentials)
        if (headers != null && !headers.isEmpty()) {
            for (String key : headers.keySet()) {
                request.setHeader(key, headers.get(key));
            }
        }
        
        return request;
    }
    
    /**
     * @description Schedule retry for a failed operation
     * @param correlationId Correlation ID
     * @param endpoint API endpoint
     * @param payload Request payload
     * @param headers Request headers
     * @param systemName System name
     * @param maxRetries Maximum retry attempts
     * @param baseDelayMs Base delay for exponential backoff
     * @param context Additional context
     */
    public static void scheduleRetry(String correlationId, String endpoint, String payload,
                                   Map<String, String> headers, String systemName,
                                   String httpMethod, Integer maxRetries, Integer baseDelayMs, Map<String, Object> context) {
        
        RetryQueueable retryJob = new RetryQueueable(
            correlationId, endpoint, payload, headers, systemName, httpMethod,
            0, maxRetries, baseDelayMs, context
        );
        
        System.enqueueJob(retryJob);
        
        System.debug('Scheduled initial retry for correlation ID: ' + correlationId);
    }
}
