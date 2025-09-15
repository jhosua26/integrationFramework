/**
 * @description Integration Framework - Version 8
 * @author Jhosua R. Arda
 * @version 8.0
 * @purpose This framework is being used in Accenture projects and freelancing work.
 *          DO NOT MODIFY this class as it is part of the framework.
 *          Modifying this class will destroy the framework functionality.
 * 
 * Integration Framework - Main integration manager
 * 
 * This class manages all external system integrations by:
 * - Coordinating different connectors (REST, SOAP, etc.)
 * - Handling request/response logging and error tracking
 * - Providing a unified interface for all integration calls
 * 
 * Use this class to send requests to external systems instead of calling connectors directly.
 */
public class IntegrationManager {
    
    private final IIntegrationLogger logger;
    private final Map<String, IIntegrationConnector> connectors;
    private final String defaultSystemName;
    private final EnhancedErrorHandler enhancedErrorHandler;
    
    /**
     * Creates a new IntegrationManager instance
     * 
     * logger - The logger to use for tracking requests and errors
     * defaultSystemName - Default system name when none is specified
     */
    public IntegrationManager(IIntegrationLogger logger, String defaultSystemName) {
        if (logger == null) {
            throw new IllegalArgumentException('Logger cannot be null');
        }
        
        if (String.isBlank(defaultSystemName)) {
            throw new IllegalArgumentException('Default system name cannot be null or empty');
        }
        
        this.logger = logger;
        this.defaultSystemName = defaultSystemName;
        this.connectors = new Map<String, IIntegrationConnector>();
        this.enhancedErrorHandler = new EnhancedErrorHandler(logger);
    }
    
    
    /**
     * Sends a request to an external system
     * 
     * This method handles the complete integration flow:
     * - Validates input parameters
     * - Finds the appropriate connector for the system
     * - Sends the request and logs the interaction
     * - Returns a standardized response object
     * 
     * systemName - Name of the external system (must be registered)
     * endpoint - The API endpoint URL
     * payload - Request body (JSON/XML/etc.)
     * headers - HTTP headers for the request
     * correlationId - Unique ID for tracking this request
     * Returns IntegrationResponse with the result
     */
    public IntegrationResponse sendRequest(String systemName, String endpoint, String payload, 
                                         Map<String, String> headers, String correlationId) {
        if (String.isBlank(systemName)) {
            throw new IllegalArgumentException('System name cannot be null or empty');
        }
        
        if (String.isBlank(endpoint)) {
            throw new IllegalArgumentException('Endpoint cannot be null or empty');
        }
        
        if (String.isBlank(correlationId)) {
            throw new IllegalArgumentException('Correlation ID cannot be null or empty');
        }
        
        IIntegrationConnector connector = connectors.get(systemName.toLowerCase());
        if (connector == null) {
            String errorMessage = 'No connector registered for system: ' + systemName;
            
            // Use enhanced error handling for connector not found
            Map<String, Object> context = new Map<String, Object>{
                'systemName' => systemName,
                'availableConnectors' => connectors.keySet(),
                'requestType' => 'sendRequest'
            };
            
            enhancedErrorHandler.logEnhancedError(
                correlationId, 
                'CONNECTOR_NOT_FOUND', 
                errorMessage, 
                '', 
                'High', 
                context
            );
            
            throw new IllegalArgumentException(errorMessage);
        }
        
        return connector.sendRequest(endpoint, payload, headers, correlationId);
    }
    
    
    
    /**
     * Sends a GET request to an external system
     * 
     * Convenience method for GET requests (no payload needed).
     * Same validation and logging as sendRequest() but optimized for GET calls.
     * 
     * systemName - Name of the external system
     * endpoint - The API endpoint URL
     * headers - HTTP headers for the request
     * correlationId - Unique ID for tracking this request
     * Returns IntegrationResponse with the result
     */
    public IntegrationResponse sendGetRequest(String systemName, String endpoint, 
                                            Map<String, String> headers, String correlationId) {
        if (String.isBlank(systemName)) {
            throw new IllegalArgumentException('System name cannot be null or empty');
        }
        
        if (String.isBlank(endpoint)) {
            throw new IllegalArgumentException('Endpoint cannot be null or empty');
        }
        
        if (String.isBlank(correlationId)) {
            throw new IllegalArgumentException('Correlation ID cannot be null or empty');
        }
        
        IIntegrationConnector connector = connectors.get(systemName.toLowerCase());
        if (connector == null) {
            String errorMessage = 'No connector registered for system: ' + systemName;
            logger.logError(correlationId, 'CONNECTOR_NOT_FOUND', errorMessage, '', 'High', 
                          new Map<String, Object>{'systemName' => systemName});
            throw new IllegalArgumentException(errorMessage);
        }
        
        // For now, we'll throw an exception since GET requests need specific connector implementation
        String errorMessage = 'GET requests are only supported by REST connectors';
        logger.logError(correlationId, 'UNSUPPORTED_OPERATION', errorMessage, '', 'Medium', 
                      new Map<String, Object>{'systemName' => systemName, 'connectorType' => connector.getConnectorType()});
        throw new UnsupportedOperationException(errorMessage);
    }
    
    
    
    
    /**
     * Logs an error for tracking and debugging
     * 
     * Use this method to log integration errors with full context.
     * The error will be stored in Integration_Error__c with all relevant details.
     * 
     * systemName - External system name (uses default if blank)
     * errorType - Type of error (e.g., 'TIMEOUT', 'AUTH_FAILED')
     * errorMessage - Human-readable error description
     * stackTrace - Technical stack trace for debugging
     * severity - Error severity level ('Low', 'Medium', 'High', 'Critical')
     * correlationId - Unique ID linking to the original request
     * context - Additional context data for debugging
     */
    public void logError(String systemName, String errorType, String errorMessage, String stackTrace, 
                        String severity, String correlationId, Map<String, Object> context) {
        if (String.isBlank(systemName)) {
            systemName = defaultSystemName;
        }
        
        if (String.isBlank(correlationId)) {
            throw new IllegalArgumentException('Correlation ID cannot be null or empty');
        }
        
        logger.logError(correlationId, errorType, errorMessage, stackTrace, severity, context);
    }
    
    /**
     * Gets the connector for a specific system
     * 
     * Returns the connector instance for the given system name.
     * Useful for advanced operations or direct connector access.
     * 
     * systemName - Name of the system
     * Returns connector instance or null if not found
     */
    public IIntegrationConnector getConnector(String systemName) {
        if (String.isBlank(systemName)) {
            return null;
        }
        
        return connectors.get(systemName.toLowerCase());
    }
    
    /**
     * Gets all registered system names
     * 
     * Returns a set of all system names that have connectors registered.
     * Useful for validation or displaying available systems.
     * 
     * Returns set of registered system names
     */
    public Set<String> getRegisteredSystems() {
        return connectors.keySet();
    }
    
    /**
     * Validates that all registered connectors are properly configured
     * 
     * Checks each connector to ensure it has valid configuration.
     * Call this during system initialization to catch setup issues early.
     * 
     * Returns true if all connectors are valid, false otherwise
     */
    public Boolean validateAllConnectors() {
        for (IIntegrationConnector connector : connectors.values()) {
            if (!connector.validateConfiguration()) {
                return false;
            }
        }
        return true;
    }
}
