/**
 * @description Integration Framework - Version 8
 * @author Jhosua R. Arda
 * @version 8.0
 * @purpose This framework is being used in Accenture projects and freelancing work.
 *          DO NOT MODIFY this class as it is part of the framework.
 *          Modifying this class will destroy the framework functionality.
 * 
 * Interface for integration logging operations
 */
public interface IIntegrationLogger {
    
    /**
     * @description Logs an inbound message
     * @param correlationId Unique identifier for the integration session
     * @param systemName Name of the external system
     * @param payload The message payload
     * @param additionalContext Additional context information
     */
    void logInboundMessage(String correlationId, String systemName, String payload, Map<String, Object> additionalContext);
    
    /**
     * @description Logs an outbound message
     * @param correlationId Unique identifier for the integration session
     * @param systemName Name of the external system
     * @param payload The message payload
     * @param additionalContext Additional context information
     */
    void logOutboundMessage(String correlationId, String systemName, String payload, Map<String, Object> additionalContext);
    
    /**
     * @description Logs an error with detailed information
     * @param correlationId Unique identifier for the integration session
     * @param errorType Type of error (e.g., 'AUTHENTICATION', 'TIMEOUT', 'VALIDATION')
     * @param errorMessage Human-readable error message
     * @param stackTrace Technical stack trace
     * @param severity Error severity level
     * @param context Additional context information
     */
    void logError(String correlationId, String errorType, String errorMessage, String stackTrace, String severity, Map<String, Object> context);
    
    /**
     * @description Updates the status of an existing log entry
     * @param correlationId Unique identifier for the integration session
     * @param status New status value
     * @param additionalData Additional data to update
     */
    void updateLogStatus(String correlationId, String status, Map<String, Object> additionalData);
}
