/**
 * @description Integration Framework - Version 8
 * @author Jhosua R. Arda
 * @version 8.0
 * @purpose This framework is being used in Accenture projects and freelancing work.
 *          DO NOT MODIFY this class as it is part of the framework.
 *          Modifying this class will destroy the framework functionality.
 * 
 * Advanced error handling system designed specifically for IntegrationFramework:
 * - Advanced error classification and categorization
 * - Intelligent error resolution suggestions
 * - Error correlation and tracking
 * - Business impact assessment
 * - Framework-specific error patterns
 * 
 * Follows principles: SOLID, dependency injection, guard clauses, deep modules
 */
public class FrameworkErrorHandler {
    
    // Configuration constants
    private static final Integer MAX_ERROR_MESSAGE_SIZE = 32768;
    private static final Integer MAX_STACK_TRACE_SIZE = 131072;
    private static final Integer MAX_CORRELATION_HISTORY = 50;
    
    private static FrameworkErrorHandler instance;
    
    /**
     * Gets the singleton instance of FrameworkErrorHandler
     * 
     * Returns a shared instance for consistent error handling across the framework.
     * Use this method to get the error handler instance instead of creating new ones.
     */
    public static FrameworkErrorHandler getInstance() {
        if (instance == null) {
            instance = new FrameworkErrorHandler();
        }
        return instance;
    }
    
    /**
     * Default constructor for singleton pattern
     * 
     * Private constructor to enforce singleton pattern.
     * Use getInstance() method to get the shared instance.
     */
    public FrameworkErrorHandler() {
        // Default constructor for singleton pattern
    }
    
    // Framework-specific error patterns
    private static final Map<String, String> FRAMEWORK_ERROR_PATTERNS = new Map<String, String>{
        // Integration-specific errors
        'callout' => 'PLATFORM',
        'http' => 'PLATFORM',
        'timeout' => 'TIMEOUT',
        'connection' => 'NETWORK',
        'unreachable' => 'NETWORK',
        'unauthorized' => 'AUTHENTICATION',
        'forbidden' => 'AUTHENTICATION',
        'validation' => 'DATA',
        'invalid' => 'DATA',
        'missing' => 'DATA',
        'retry' => 'PLATFORM'
    };
    
    // Framework-specific severity patterns
    private static final Map<String, String> FRAMEWORK_SEVERITY_PATTERNS = new Map<String, String>{
        // High severity
        'callout failed' => 'HIGH',
        'timeout' => 'HIGH',
        'retry exhausted' => 'HIGH',
        'authentication failed' => 'HIGH',
        'connection lost' => 'HIGH',
        
        // Medium severity
        'retry' => 'MEDIUM',
        'validation' => 'MEDIUM',
        'temporary' => 'MEDIUM',
        'degraded' => 'MEDIUM',
        
        // Low severity
        'info' => 'LOW',
        'debug' => 'LOW',
        'warning' => 'LOW'
    };
    
    // Framework-specific HTTP status code mapping
    private static final Map<String, Integer> FRAMEWORK_STATUS_CODE_MAPPING = new Map<String, Integer>{
        // Authentication errors
        'AUTHENTICATION' => 401,
        'UNAUTHORIZED' => 401,
        'FORBIDDEN' => 403,
        
        // Data validation errors
        'DATA' => 400,
        'VALIDATION' => 400,
        'INVALID' => 400,
        'MISSING' => 400,
        
        // Business logic errors
        'BUSINESS' => 422,
        'CONFLICT' => 409,
        'NOT_FOUND' => 404,
        
        // System/platform errors
        'PLATFORM' => 500,
        'NETWORK' => 503,
        'TIMEOUT' => 504,
        'SERVICE_UNAVAILABLE' => 503,
        
        // Default fallback
        'UNKNOWN' => 500
    };
    
    // Framework-specific resolution suggestions
    private static final Map<String, String> FRAMEWORK_RESOLUTION_SUGGESTIONS = new Map<String, String>{
        'PLATFORM' => 'Check external system connectivity, verify endpoint availability, and review named credentials configuration.',
        'NETWORK' => 'Verify network connectivity, check firewall settings, and ensure DNS resolution is working.',
        'AUTHENTICATION' => 'Verify credentials, check token expiration, and review named credentials setup.',
        'DATA' => 'Validate input data format, check required fields, and ensure data meets schema requirements.',
        'TIMEOUT' => 'Increase timeout settings, optimize request payload, and check network latency.'
    };
    
    // Framework-specific business impact
    private static final Map<String, String> FRAMEWORK_BUSINESS_IMPACT = new Map<String, String>{
        'PLATFORM' => 'External system communication affected - potential data synchronization issues',
        'NETWORK' => 'Service disruption - external system communication blocked',
        'AUTHENTICATION' => 'Security risk - unauthorized access attempts detected',
        'DATA' => 'Data integrity - potential data loss or corruption',
        'TIMEOUT' => 'Performance degradation - slow response times affecting user experience'
    };
    
    private final IIntegrationLogger logger;
    
    /**
     * @description Constructor with dependency injection
     * @param logger Logger implementation
     */
    public FrameworkErrorHandler(IIntegrationLogger logger) {
        if (logger == null) {
            throw new IllegalArgumentException('Logger cannot be null');
        }
        this.logger = logger;
    }
    
    /**
     * @description Framework-specific error logging with advanced classification
     * @param correlationId Unique identifier for tracking
     * @param errorType Type of error
     * @param errorMessage Error message
     * @param stackTrace Stack trace
     * @param severity Error severity
     * @param context Additional context
     */
    public void logFrameworkError(String correlationId, String errorType, String errorMessage, 
                                String stackTrace, String severity, Map<String, Object> context) {
        logFrameworkError(correlationId, errorType, errorMessage, stackTrace, severity, context, 0);
    }
    
    /**
     * @description Logs a framework error with comprehensive error handling
     * @param correlationId Unique identifier for tracking
     * @param errorType Type of error
     * @param errorMessage Error message
     * @param stackTrace Stack trace
     * @param severity Error severity
     * @param context Additional context information
     * @param retryCount Retry count
     */
    public void logFrameworkError(String correlationId, String errorType, String errorMessage, 
                                String stackTrace, String severity, Map<String, Object> context, Integer retryCount) {
        if (String.isBlank(correlationId)) {
            throw new IllegalArgumentException('Correlation ID cannot be null or empty');
        }
        
        if (String.isBlank(errorMessage)) {
            throw new IllegalArgumentException('Error message cannot be null or empty');
        }
        
        try {
            // Framework-specific error classification
            String classifiedErrorType = classifyFrameworkError(errorMessage, errorType);
            String assessedSeverity = assessFrameworkSeverity(errorMessage, severity);
            String businessImpact = assessFrameworkBusinessImpact(classifiedErrorType);
            String resolutionSuggestion = generateFrameworkResolutionSuggestion(classifiedErrorType, context);
            
            // Enhanced context with framework-specific data
            Map<String, Object> enhancedContext = buildFrameworkContext(context, classifiedErrorType, 
                                                                       assessedSeverity, businessImpact, resolutionSuggestion);
            
            // Create framework error record
            Integration_Error__c errorRecord = new Integration_Error__c(
                Correlation_ID__c = correlationId,
                Error_Type__c = classifiedErrorType,
                Error_Message__c = sanitizeErrorMessage(errorMessage),
                Stack_Trace__c = sanitizeStackTrace(stackTrace),
                Error_Severity__c = assessedSeverity,
                Status__c = determineFrameworkStatus(classifiedErrorType, context),
                Timestamp__c = Datetime.now(),
                Retry_Count__c = retryCount != null ? retryCount : 0,
                Context__c = JSON.serialize(enhancedContext),
                Technical_Context__c = buildTechnicalContext(enhancedContext),
                Business_Impact__c = businessImpact,
                Resolution_Notes__c = resolutionSuggestion
            );
            
            insert errorRecord;
            
            // Correlate with existing framework errors
            correlateFrameworkErrors(correlationId, classifiedErrorType, errorMessage);
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to log framework error: ' + e.getMessage());
        }
    }
    
    /**
     * @description Framework-specific error classification
     * @param errorMessage Error message to classify
     * @param originalType Original error type
     * @return Classified error type
     */
    private String classifyFrameworkError(String errorMessage, String originalType) {
        if (String.isBlank(errorMessage)) {
            return originalType != null ? originalType : 'PLATFORM';
        }
        
        String lowerMessage = errorMessage.toLowerCase();
        
        // Framework-specific pattern classification
        for (String pattern : FRAMEWORK_ERROR_PATTERNS.keySet()) {
            if (lowerMessage.contains(pattern)) {
                return FRAMEWORK_ERROR_PATTERNS.get(pattern);
            }
        }
        
        // Framework-specific exception classification
        if (lowerMessage.contains('callout') || lowerMessage.contains('http')) {
            return 'PLATFORM';
        }
        
        if (lowerMessage.contains('retry') || lowerMessage.contains('backoff')) {
            return 'PLATFORM';
        }
        
        return originalType != null ? originalType : 'PLATFORM';
    }
    
    /**
     * @description Framework-specific severity assessment
     * @param errorMessage Error message
     * @param originalSeverity Original severity
     * @return Assessed severity
     */
    private String assessFrameworkSeverity(String errorMessage, String originalSeverity) {
        if (String.isBlank(errorMessage)) {
            return originalSeverity != null ? originalSeverity.toUpperCase() : 'MEDIUM';
        }
        
        String lowerMessage = errorMessage.toLowerCase();
        
        // Framework-specific severity patterns
        for (String pattern : FRAMEWORK_SEVERITY_PATTERNS.keySet()) {
            if (lowerMessage.contains(pattern)) {
                return FRAMEWORK_SEVERITY_PATTERNS.get(pattern);
            }
        }
        
        // Framework-specific business logic
        if (lowerMessage.contains('retry') || lowerMessage.contains('timeout')) {
            return 'MEDIUM';
        }
        
        if (lowerMessage.contains('info') || lowerMessage.contains('debug')) {
            return 'LOW';
        }
        
        return originalSeverity != null ? originalSeverity.toUpperCase() : 'MEDIUM';
    }
    
    /**
     * @description Framework-specific business impact assessment
     * @param errorType Classified error type
     * @return Business impact description
     */
    private String assessFrameworkBusinessImpact(String errorType) {
        if (String.isBlank(errorType)) {
            return 'Unknown framework impact';
        }
        
        return FRAMEWORK_BUSINESS_IMPACT.containsKey(errorType) ? 
               FRAMEWORK_BUSINESS_IMPACT.get(errorType) : 
               'General framework impact';
    }
    
    /**
     * @description Generate framework-specific resolution suggestions
     * @param errorType Error type
     * @param context Error context
     * @return Resolution suggestion
     */
    private String generateFrameworkResolutionSuggestion(String errorType, Map<String, Object> context) {
        if (String.isBlank(errorType)) {
            return 'Review framework error details and consult integration documentation';
        }
        
        String baseSuggestion = FRAMEWORK_RESOLUTION_SUGGESTIONS.containsKey(errorType) ? 
                               FRAMEWORK_RESOLUTION_SUGGESTIONS.get(errorType) : 
                               'Review framework error context and implement appropriate error handling';
        
        // Add framework-specific context suggestions
        if (context != null && context.containsKey('retryCount')) {
            Integer retryCount = (Integer) context.get('retryCount');
            if (retryCount > 0) {
                baseSuggestion += ' Retry attempts: ' + retryCount + '. Consider adjusting retry configuration.';
            }
        }
        
        if (context != null && context.containsKey('systemName')) {
            String systemName = (String) context.get('systemName');
            baseSuggestion += ' Check ' + systemName + ' system status and integration configuration.';
        }
        
        if (context != null && context.containsKey('endpoint')) {
            String endpoint = (String) context.get('endpoint');
            baseSuggestion += ' Verify endpoint availability: ' + endpoint;
        }
        
        return baseSuggestion;
    }
    
    /**
     * @description Determine framework-specific error status
     * @param errorType Error type
     * @return Initial status
     */
    private String determineFrameworkStatus(String errorType, Map<String, Object> context) {
        if (String.isBlank(errorType)) {
            return 'Open';
        }
        
        // Check for max retries exceeded
        if (context != null && context.containsKey('maxRetriesExceeded') && 
            Boolean.valueOf(context.get('maxRetriesExceeded'))) {
            return 'Max Retries Exceeded';
        }
        
        // Framework-specific status logic
        if (errorType == 'NETWORK' || errorType == 'TIMEOUT') {
            return 'Retrying';
        }
        
        if (errorType == 'AUTHENTICATION') {
            return 'Investigating';
        }
        
        if (errorType == 'DATA') {
            return 'Not Retryable';
        }
        
        if (errorType == 'PLATFORM') {
            return 'Open';
        }
        
        return 'Open';
    }
    
    /**
     * @description Automatically determine HTTP status code based on error type
     * @param errorType Error type
     * @param errorMessage Error message for additional context
     * @return HTTP status code
     */
    public Integer determineHttpStatusCode(String errorType, String errorMessage) {
        if (String.isBlank(errorType)) {
            return 500; // Default to internal server error
        }
        
        // Check if we have a direct mapping
        if (FRAMEWORK_STATUS_CODE_MAPPING.containsKey(errorType)) {
            return FRAMEWORK_STATUS_CODE_MAPPING.get(errorType);
        }
        
        // Additional context-based mapping
        if (String.isNotBlank(errorMessage)) {
            String lowerMessage = errorMessage.toLowerCase();
            
            // Authentication errors
            if (lowerMessage.contains('unauthorized') || lowerMessage.contains('authentication')) {
                return 401;
            }
            if (lowerMessage.contains('forbidden') || lowerMessage.contains('access denied')) {
                return 403;
            }
            
            // Data validation errors
            if (lowerMessage.contains('validation') || lowerMessage.contains('invalid') || 
                lowerMessage.contains('missing') || lowerMessage.contains('required')) {
                return 400;
            }
            
            // Business logic errors
            if (lowerMessage.contains('not found') || lowerMessage.contains('does not exist')) {
                return 404;
            }
            if (lowerMessage.contains('conflict') || lowerMessage.contains('already exists')) {
                return 409;
            }
            if (lowerMessage.contains('business') || lowerMessage.contains('unprocessable')) {
                return 422;
            }
            
            // System errors
            if (lowerMessage.contains('timeout') || lowerMessage.contains('timed out')) {
                return 504;
            }
            if (lowerMessage.contains('service unavailable') || lowerMessage.contains('maintenance')) {
                return 503;
            }
        }
        
        // Default fallback
        return 500;
    }
    
    /**
     * @description Create standardized error response
     * @param errorType Error type
     * @param errorMessage Error message
     * @param correlationId Correlation ID
     * @param additionalContext Additional context
     * @return Map containing standardized error response
     */
    public Map<String, Object> createStandardErrorResponse(String errorType, String errorMessage, 
                                                          String correlationId, Map<String, Object> additionalContext) {
        Integer statusCode = determineHttpStatusCode(errorType, errorMessage);
        String severity = assessFrameworkSeverity(errorMessage, 'HIGH');
        
        Map<String, Object> errorResponse = new Map<String, Object>{
            'error' => true,
            'type' => errorType,
            'message' => errorMessage,
            'statusCode' => statusCode,
            'severity' => severity,
            'correlationId' => correlationId,
            'timestamp' => System.currentTimeMillis()
        };
        
        // Add additional context if provided
        if (additionalContext != null && !additionalContext.isEmpty()) {
            errorResponse.put('context', additionalContext);
        }
        
        return errorResponse;
    }
    
    /**
     * @description Correlate framework errors for pattern recognition
     * @param correlationId Correlation ID
     * @param errorType Error type
     * @param errorMessage Error message
     */
    private void correlateFrameworkErrors(String correlationId, String errorType, String errorMessage) {
        if (String.isBlank(errorType) || String.isBlank(errorMessage)) {
            return;
        }
        
        try {
            // Find similar framework errors in the last 24 hours
            Datetime last24Hours = Datetime.now().addHours(-24);
            
            List<Integration_Error__c> similarErrors = [
                SELECT Id, Error_Type__c, Error_Message__c, Timestamp__c, Status__c
                FROM Integration_Error__c 
                WHERE Error_Type__c = :errorType 
                AND Timestamp__c >= :last24Hours
                AND Correlation_ID__c != :correlationId
                ORDER BY Timestamp__c DESC 
                LIMIT :MAX_CORRELATION_HISTORY
            ];
            
            if (!similarErrors.isEmpty()) {
                // Update current error with correlation data
                List<Integration_Error__c> currentErrors = [
                    SELECT Id, Context__c 
                    FROM Integration_Error__c 
                    WHERE Correlation_ID__c = :correlationId 
                    LIMIT 1
                ];
                
                if (!currentErrors.isEmpty()) {
                    Integration_Error__c currentError = currentErrors[0];
                    Map<String, Object> context = currentError.Context__c != null ? 
                        (Map<String, Object>) JSON.deserializeUntyped(currentError.Context__c) : 
                        new Map<String, Object>();
                    
                    context.put('correlatedErrors', similarErrors.size());
                    context.put('errorPattern', 'recurring');
                    context.put('lastOccurrence', similarErrors[0].Timestamp__c.format());
                    context.put('frameworkErrorType', errorType);
                    
                    currentError.Context__c = JSON.serialize(context);
                    update currentError;
                }
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to correlate framework errors: ' + e.getMessage());
        }
    }
    
    /**
     * @description Build framework-specific context
     * @param originalContext Original context
     * @param errorType Classified error type
     * @param severity Assessed severity
     * @param businessImpact Business impact
     * @param resolutionSuggestion Resolution suggestion
     * @return Enhanced context
     */
    private Map<String, Object> buildFrameworkContext(Map<String, Object> originalContext, 
                                                     String errorType, String severity, 
                                                     String businessImpact, String resolutionSuggestion) {
        Map<String, Object> enhancedContext = originalContext != null ? 
            new Map<String, Object>(originalContext) : 
            new Map<String, Object>();
        
        enhancedContext.put('framework', new Map<String, Object>{
            'errorType' => errorType,
            'severity' => severity,
            'businessImpact' => businessImpact,
            'autoClassified' => true,
            'classificationTimestamp' => Datetime.now().format()
        });
        
        enhancedContext.put('resolution', new Map<String, Object>{
            'suggestion' => resolutionSuggestion,
            'autoGenerated' => true,
            'generationTimestamp' => Datetime.now().format(),
            'frameworkSpecific' => true
        });
        
        enhancedContext.put('technical', new Map<String, Object>{
            'userId' => UserInfo.getUserId(),
            'orgId' => UserInfo.getOrganizationId(),
            'timestamp' => Datetime.now().format()
        });
        
        return enhancedContext;
    }
    
    /**
     * @description Build technical context for error record
     * @param context Enhanced context
     * @return Technical context JSON
     */
    private String buildTechnicalContext(Map<String, Object> context) {
        if (context == null || context.isEmpty()) {
            return null;
        }
        
        Map<String, Object> technicalContext = new Map<String, Object>();
        technicalContext.put('timestamp', Datetime.now().format());
        technicalContext.put('userId', UserInfo.getUserId());
        technicalContext.put('orgId', UserInfo.getOrganizationId());
        technicalContext.put('context', context);
        
        return JSON.serialize(technicalContext);
    }
    
    /**
     * @description Sanitize error message for storage
     * @param errorMessage Error message
     * @return Sanitized error message
     */
    private String sanitizeErrorMessage(String errorMessage) {
        if (String.isBlank(errorMessage)) {
            return errorMessage;
        }
        
        if (errorMessage.length() > MAX_ERROR_MESSAGE_SIZE) {
            return errorMessage.substring(0, MAX_ERROR_MESSAGE_SIZE - 3) + '...';
        }
        
        return errorMessage;
    }
    
    /**
     * @description Sanitize stack trace for storage
     * @param stackTrace Stack trace
     * @return Sanitized stack trace
     */
    private String sanitizeStackTrace(String stackTrace) {
        if (String.isBlank(stackTrace)) {
            return stackTrace;
        }
        
        if (stackTrace.length() > MAX_STACK_TRACE_SIZE) {
            return stackTrace.substring(0, MAX_STACK_TRACE_SIZE - 3) + '...';
        }
        
        return stackTrace;
    }
    
    /**
     * @description Get framework error analytics for a correlation ID
     * @param correlationId Correlation ID
     * @return Error analytics data
     */
    public Map<String, Object> getFrameworkErrorAnalytics(String correlationId) {
        if (String.isBlank(correlationId)) {
            return new Map<String, Object>();
        }
        
        try {
            List<Integration_Error__c> errors = [
                SELECT Id, Error_Type__c, Error_Severity__c, Status__c, Timestamp__c, Retry_Count__c
                FROM Integration_Error__c 
                WHERE Correlation_ID__c = :correlationId 
                ORDER BY Timestamp__c DESC
            ];
            
            Map<String, Object> analytics = new Map<String, Object>();
            analytics.put('totalErrors', errors.size());
            analytics.put('framework', 'IntegrationFramework');
            analytics.put('errorTypes', new Map<String, Integer>());
            analytics.put('severityDistribution', new Map<String, Integer>());
            analytics.put('statusDistribution', new Map<String, Integer>());
            analytics.put('retryStats', new Map<String, Object>());
            
            Decimal totalRetries = 0;
            Map<String, Integer> errorTypeCount = new Map<String, Integer>();
            Map<String, Integer> severityCount = new Map<String, Integer>();
            Map<String, Integer> statusCount = new Map<String, Integer>();
            
            for (Integration_Error__c error : errors) {
                // Error type count
                String errorType = error.Error_Type__c;
                errorTypeCount.put(errorType, errorTypeCount.containsKey(errorType) ? 
                    errorTypeCount.get(errorType) + 1 : 1);
                
                // Severity count
                String severity = error.Error_Severity__c;
                severityCount.put(severity, severityCount.containsKey(severity) ? 
                    severityCount.get(severity) + 1 : 1);
                
                // Status count
                String status = error.Status__c;
                statusCount.put(status, statusCount.containsKey(status) ? 
                    statusCount.get(status) + 1 : 1);
                
                // Retry count
                totalRetries += error.Retry_Count__c != null ? error.Retry_Count__c : 0.0;
            }
            
            analytics.put('errorTypes', errorTypeCount);
            analytics.put('severityDistribution', severityCount);
            analytics.put('statusDistribution', statusCount);
            Double averageRetries = errors.size() > 0 ? (Double) totalRetries / errors.size() : 0.0;
            analytics.put('retryStats', new Map<String, Object>{
                'totalRetries' => totalRetries,
                'averageRetries' => averageRetries
            });
            
            return analytics;
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to get framework error analytics: ' + e.getMessage());
            return new Map<String, Object>();
        }
    }
}
