/**
 * @description Integration Framework - Version 8
 * @author Jhosua R. Arda
 * @version 8.0
 * @purpose This framework is being used in Accenture projects and freelancing work.
 *          DO NOT MODIFY this class as it is part of the framework.
 *          Modifying this class will destroy the framework functionality.
 * 
 * Concrete implementation of integration logging using custom objects
 */
public class IntegrationLogger implements IIntegrationLogger {
    
    private static final String INBOUND_DIRECTION = 'Inbound';
    private static final String OUTBOUND_DIRECTION = 'Outbound';
    private static final String SUCCESS_STATUS = 'Completed';
    private static final String ERROR_STATUS = 'Failed';
    private static final String PENDING_STATUS = 'Processing';
    
    private static IntegrationLogger instance;
    
    /**
     * Gets the singleton instance of IntegrationLogger
     * 
     * Returns a shared instance for consistent logging across the framework.
     * Use this method to get the logger instance instead of creating new ones.
     */
    public static IntegrationLogger getInstance() {
        if (instance == null) {
            instance = new IntegrationLogger();
        }
        return instance;
    }
    
    /**
     * Logs an inbound message
     * 
     * Records incoming messages from external systems for tracking and debugging.
     * Creates an Integration_Log__c record with inbound direction and 'Response' message type.
     * 
     * correlationId - Unique identifier for the integration session
     * systemName - Name of the external system sending the message
     * payload - The message payload (JSON, XML, etc.)
     * additionalContext - Additional context information for debugging
     */
    public void logInboundMessage(String correlationId, String systemName, String payload, Map<String, Object> additionalContext) {
        if (String.isBlank(correlationId)) {
            throw new IllegalArgumentException('Correlation ID cannot be null or empty');
        }
        
        if (String.isBlank(systemName)) {
            throw new IllegalArgumentException('System name cannot be null or empty');
        }
        
        try {
            Integration_Log__c logRecord = createLogRecord(
                correlationId,
                systemName,
                payload,
                INBOUND_DIRECTION,
                'Response',
                'Received',
                additionalContext
            );
            
            insert logRecord;
        } catch (Exception e) {
            // Log the logging error to avoid infinite loops
            System.debug(LoggingLevel.ERROR, 'Failed to log inbound message: ' + e.getMessage());
        }
    }
    
    /**
     * Logs an outbound message
     * 
     * Records outgoing messages to external systems for tracking and debugging.
     * Creates an Integration_Log__c record with outbound direction and 'Request' message type.
     * 
     * correlationId - Unique identifier for the integration session
     * systemName - Name of the external system receiving the message
     * payload - The message payload (JSON, XML, etc.)
     * additionalContext - Additional context information for debugging
     */
    public void logOutboundMessage(String correlationId, String systemName, String payload, Map<String, Object> additionalContext) {
        if (String.isBlank(correlationId)) {
            throw new IllegalArgumentException('Correlation ID cannot be null or empty');
        }
        
        if (String.isBlank(systemName)) {
            throw new IllegalArgumentException('System name cannot be null or empty');
        }
        
        try {
            Integration_Log__c logRecord = createLogRecord(
                correlationId,
                systemName,
                payload,
                OUTBOUND_DIRECTION,
                'Request',
                'Sent',
                additionalContext
            );
            
            insert logRecord;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to log outbound message: ' + e.getMessage());
        }
    }
    
    /**
     * Logs an error with detailed information using FrameworkErrorHandler
     * 
     * Records integration errors with full context for debugging and monitoring.
     * Uses FrameworkErrorHandler for proper error classification and severity assessment.
     * Creates an Integration_Error__c record with all error details.
     * 
     * correlationId - Unique identifier for the integration session
     * errorType - Type of error (e.g., 'AUTHENTICATION', 'TIMEOUT', 'VALIDATION')
     * errorMessage - Human-readable error message
     * stackTrace - Technical stack trace for debugging
     * severity - Error severity level ('Low', 'Medium', 'High', 'Critical')
     * context - Additional context information for debugging
     */
    public void logError(String correlationId, String errorType, String errorMessage, String stackTrace, String severity, Map<String, Object> context) {
        if (String.isBlank(correlationId)) {
            throw new IllegalArgumentException('Correlation ID cannot be null or empty');
        }
        
        if (String.isBlank(errorType)) {
            throw new IllegalArgumentException('Error type cannot be null or empty');
        }
        
        if (String.isBlank(errorMessage)) {
            throw new IllegalArgumentException('Error message cannot be null or empty');
        }
        
        try {
            // Use FrameworkErrorHandler for comprehensive error logging
            FrameworkErrorHandler errorHandler = new FrameworkErrorHandler((IIntegrationLogger)this);
            errorHandler.logFrameworkError(correlationId, errorType, errorMessage, stackTrace, severity, context);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to log error: ' + e.getMessage());
        }
    }
    
    /**
     * @description Updates the status of an existing log entry
     * @param correlationId Unique identifier for the integration session
     * @param status New status value
     * @param additionalData Additional data to update
     */
    public void updateLogStatus(String correlationId, String status, Map<String, Object> additionalData) {
        if (String.isBlank(correlationId)) {
            throw new IllegalArgumentException('Correlation ID cannot be null or empty');
        }
        
        if (String.isBlank(status)) {
            throw new IllegalArgumentException('Status cannot be null or empty');
        }
        
        try {
            List<Integration_Log__c> logRecords = [
                SELECT Id, Status__c, Processing_Time__c, Retry_Count__c
                FROM Integration_Log__c 
                WHERE Correlation_ID__c = :correlationId
                LIMIT 1
            ];
            
            if (!logRecords.isEmpty()) {
                Integration_Log__c logRecord = logRecords[0];
                logRecord.Status__c = status;
                
                if (additionalData != null) {
                    if (additionalData.containsKey('processingTime')) {
                        logRecord.Processing_Time__c = (Decimal) additionalData.get('processingTime');
                    }
                    if (additionalData.containsKey('retryCount')) {
                        logRecord.Retry_Count__c = (Integer) additionalData.get('retryCount');
                    }
                }
                
                update logRecord;
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to update log status: ' + e.getMessage());
        }
    }
    
    /**
     * @description Creates a log record with the provided data
     * @param correlationId Unique identifier for the integration session
     * @param systemName Name of the external system
     * @param payload The message payload
     * @param direction Message direction (Inbound/Outbound)
     * @param messageType Type of message
     * @param status Status of the message
     * @param additionalContext Additional context information
     * @return Integration_Log__c record
     */
    @TestVisible
    private Integration_Log__c createLogRecord(String correlationId, String systemName, String payload, 
                                              String direction, String messageType, String status, 
                                              Map<String, Object> additionalContext) {
        // Extract processing time from context if available
        Decimal processingTime = null;
        if (additionalContext != null && additionalContext.containsKey('processingTime')) {
            Object processingTimeObj = additionalContext.get('processingTime');
            if (processingTimeObj instanceof Long) {
                processingTime = (Long) processingTimeObj;
            } else if (processingTimeObj instanceof Integer) {
                processingTime = (Integer) processingTimeObj;
            } else if (processingTimeObj instanceof Decimal) {
                processingTime = (Decimal) processingTimeObj;
            }
            // If processingTimeObj is not a valid numeric type, processingTime remains null
        }
        
        // Extract retry count from context if available
        Integer retryCount = 0;
        if (additionalContext != null && additionalContext.containsKey('retryCount')) {
            Object retryCountObj = additionalContext.get('retryCount');
            if (retryCountObj instanceof Integer) {
                retryCount = (Integer) retryCountObj;
            } else if (retryCountObj instanceof Decimal) {
                retryCount = (Integer) ((Decimal) retryCountObj).intValue();
            }
        }
        
        return new Integration_Log__c(
            Correlation_ID__c = correlationId,
            System__c = systemName,
            Payload__c = payload,
            Direction__c = direction,
            Message_Type__c = messageType,
            Status__c = status,
            Timestamp__c = Datetime.now(),
            Processing_Time__c = processingTime,
            Retry_Count__c = retryCount
        );
    }
    
    /**
     * @description Builds technical context from the provided context map
     * @param context Context information
     * @return String representation of technical context
     */
    @TestVisible
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
}
