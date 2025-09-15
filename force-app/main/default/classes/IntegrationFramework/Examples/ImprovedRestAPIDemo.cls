/**
 * @description Integration Framework - Version 8
 * @author Jhosua R. Arda
 * @version 8.0
 * @purpose This framework is being used in Accenture projects and freelancing work.
 *          DO NOT MODIFY this class as it is part of the framework.
 *          Modifying this class will destroy the framework functionality.
 * 
 * SIMPLIFIED REST API Demo - Now as simple as outbound integration!
 * Framework handles everything automatically: logging, error handling, correlation IDs
 */
@RestResource(urlMapping='/integration-demo-v2/')
global with sharing class ImprovedRestAPIDemo {
    
    private static final AccountRESTConnector connector = new AccountRESTConnector(
        IntegrationLogger.getInstance(), 
        'External_SF',
        30000,
        null
    );
    
    /**
     * GET endpoint - Retrieve account data
     * 
     * Framework handles: logging, error handling, correlation IDs automatically!
     * Simply delegates to the connector which handles all the complexity.
     */
    @HttpGet
    global static void handleGet() {
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;

        try {
            // Framework handles everything automatically - logging, correlation IDs, etc.
            IntegrationResponse integrationResponse = connector.handleInboundGet(request);
            
            // Simple response setup
            response.statusCode = integrationResponse.getStatusCode();
            response.addHeader('Content-Type', 'application/json');
            response.responseBody = Blob.valueOf(integrationResponse.getResponseBody());
            
        } catch (Exception e) {
            // Handle any unexpected errors
            response.statusCode = 500;
            response.addHeader('Content-Type', 'application/json');
            response.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
                'error' => true,
                'message' => 'Internal Server Error: ' + e.getMessage(),
                'statusCode' => 500,
                'timestamp' => System.currentTimeMillis()
            }));
        }
    }
    
    /**
     * @description POST endpoint - Create new account
     *              Framework handles: logging, error handling, correlation IDs automatically!
     */
    @HttpPost
    global static void handlePost() {
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
        
        // Framework handles everything automatically - just like outbound!
        IntegrationResponse integrationResponse = connector.handleInboundPost(request);
        
        // Simple response setup
        response.statusCode = integrationResponse.getStatusCode();
        response.addHeader('Content-Type', 'application/json');
        response.responseBody = Blob.valueOf(integrationResponse.getResponseBody());
    }
    
    /**
     * @description PUT endpoint - Update account
     *              Framework handles: logging, error handling, correlation IDs automatically!
     */
    @HttpPut
    global static void handlePut() {
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
        
        // Framework handles everything automatically - just like outbound!
        IntegrationResponse integrationResponse = connector.handleInboundPut(request);
        
        // Simple response setup
        response.statusCode = integrationResponse.getStatusCode();
        response.addHeader('Content-Type', 'application/json');
        response.responseBody = Blob.valueOf(integrationResponse.getResponseBody());
    }
    
    /**
     * @description PATCH endpoint - Partial update account
     *              Framework handles: logging, error handling, correlation IDs automatically!
     */
    @HttpPatch
    global static void handlePatch() {
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
        
        // Framework handles everything automatically - just like outbound!
        IntegrationResponse integrationResponse = connector.handleInboundPatch(request);
        
        // Simple response setup
        response.statusCode = integrationResponse.getStatusCode();
        response.addHeader('Content-Type', 'application/json');
        response.responseBody = Blob.valueOf(integrationResponse.getResponseBody());
    }
    
    /**
     * @description DELETE endpoint - Delete account
     *              Framework handles: logging, error handling, correlation IDs automatically!
     */
    @HttpDelete
    global static void handleDelete() {
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
        
        // Framework handles everything automatically - just like outbound!
        IntegrationResponse integrationResponse = connector.handleInboundDelete(request);
        
        // Simple response setup
        response.statusCode = integrationResponse.getStatusCode();
        response.addHeader('Content-Type', 'application/json');
        response.responseBody = Blob.valueOf(integrationResponse.getResponseBody());
    }
}