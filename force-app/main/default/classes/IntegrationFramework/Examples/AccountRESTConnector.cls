/**
 * @description Integration Framework - Version 8
 * @author Jhosua R. Arda
 * @version 8.0
 * @purpose This framework is being used in Accenture projects and freelancing work.
 *          DO NOT MODIFY this class as it is part of the framework.
 *          Modifying this class will destroy the framework functionality.
 * 
 * Custom REST Connector for Account operations
 * Extends RESTConnector to provide specific business logic for account management
 */
public class AccountRESTConnector extends RESTConnector {
    
    /**
     * Constructor
     * 
     * Creates a new AccountRESTConnector for account-specific operations.
     * Extends the base RESTConnector with account business logic.
     * 
     * logger - Logger implementation for tracking requests and responses
     * systemName - Name of the external system this connector handles
     * timeoutMs - Request timeout in milliseconds (defaults to 30 seconds)
     * defaultHeaders - Default headers to include in all requests
     */
    public AccountRESTConnector(IIntegrationLogger logger, String systemName, Integer timeoutMs, Map<String, String> defaultHeaders) {
        super(logger, systemName, timeoutMs, defaultHeaders);
    }
    
    /**
     * Processes the actual inbound request logic for account operations
     * 
     * Handles incoming REST requests for account operations.
     * Delegates to AccountBusinessHandler for specific business logic.
     * 
     * request - RestRequest from Salesforce REST API
     * httpMethod - HTTP method (GET, POST, PUT, PATCH, DELETE)
     * Returns IntegrationResponse with the processed result
     */
    protected override IntegrationResponse processInboundRequest(RestRequest request, String httpMethod) {
        try {
            Map<String, Object> result;
            
            switch on httpMethod {
                when 'GET' {
                    result = AccountBusinessHandler.processGetRequest(request);
                }
                when 'POST' {
                    result = AccountBusinessHandler.processPostRequest(request);
                }
                when 'PUT' {
                    result = AccountBusinessHandler.processPutRequest(request);
                }
                when 'PATCH' {
                    result = AccountBusinessHandler.processPatchRequest(request);
                }
                when 'DELETE' {
                    result = AccountBusinessHandler.processDeleteRequest(request);
                }
                when else {
                    throw new IllegalArgumentException('Unsupported HTTP method: ' + httpMethod);
                }
            }
            
            // Determine status code based on method
            Integer statusCode = (httpMethod == 'POST') ? 201 : 200;
            
            return new IntegrationResponse(
                JSON.serialize(result),
                statusCode,
                new Map<String, String>{'Content-Type' => 'application/json'},
                null, // correlationId - will be set by parent method
                -1 // processingTimeMs - placeholder, will be calculated by parent method
            );
            
        } catch (Exception e) {
            // Re-throw exception so parent RESTConnector can handle error logging
            throw e;
        }
    }
}
