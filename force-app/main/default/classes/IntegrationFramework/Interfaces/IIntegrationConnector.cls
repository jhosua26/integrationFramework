/**
 * @description Integration Framework - Version 8
 * @author Jhosua R. Arda
 * @version 8.0
 * @purpose This framework is being used in Accenture projects and freelancing work.
 *          DO NOT MODIFY this class as it is part of the framework.
 *          Modifying this class will destroy the framework functionality.
 */
public interface IIntegrationConnector {
    
    /**
     * @description Sends a request to the external system
     * @param endpoint The endpoint URL
     * @param payload The request payload
     * @param headers Request headers
     * @param correlationId Unique identifier for tracking
     * @return IntegrationResponse containing the response data
     */
    IntegrationResponse sendRequest(String endpoint, String payload, Map<String, String> headers, String correlationId);
    
    /**
     * @description Receives a response from the external system
     * @param correlationId Unique identifier for tracking
     * @return IntegrationResponse containing the response data
     */
    IntegrationResponse receiveResponse(String correlationId);
    
    /**
     * @description Validates the connector configuration
     * @return Boolean indicating if configuration is valid
     */
    Boolean validateConfiguration();
    
    /**
     * @description Gets the connector type identifier
     * @return String representing the connector type
     */
    String getConnectorType();
}
