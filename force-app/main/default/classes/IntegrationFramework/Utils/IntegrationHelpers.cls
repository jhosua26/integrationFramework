/**
 * @description Integration Framework - Version 8
 * @author Jhosua R. Arda
 * @version 8.0
 * @purpose This framework is being used in Accenture projects and freelancing work.
 *          DO NOT MODIFY this class as it is part of the framework.
 *          Modifying this class will destroy the framework functionality.
 * 
 * Helper methods for simplified integration operations
 */
public class IntegrationHelpers {
    
    // Configuration
    private static final Integer DEFAULT_TIMEOUT_MS = 30000;
    private static final String DEFAULT_SYSTEM_NAME = 'External_SF';
    
    /**
     * Create a record in external system
     * 
     * Simplified method for creating records in external Salesforce orgs.
     * Uses standard Salesforce REST API endpoint for object creation.
     * 
     * namedCredential - Named credential to use for authentication
     * objectType - Salesforce object type (e.g., 'Account', 'Contact')
     * recordData - Record data as Map with field names and values
     * Returns IntegrationResponse with creation result
     */
    public static IntegrationResponse createRecord(String namedCredential, String objectType, Map<String, Object> recordData) {
        // Guard clauses
        if (String.isBlank(namedCredential)) {
            throw new IllegalArgumentException('Named credential cannot be null or empty');
        }
        if (String.isBlank(objectType)) {
            throw new IllegalArgumentException('Object type cannot be null or empty');
        }
        if (recordData == null || recordData.isEmpty()) {
            throw new IllegalArgumentException('Record data cannot be null or empty');
        }
        
        IIntegrationLogger logger = new IntegrationLogger();
        RESTConnector connector = new RESTConnector(logger, DEFAULT_SYSTEM_NAME, DEFAULT_TIMEOUT_MS, null);
        
        String correlationId = CorrelationIdGenerator.generateCorrelationId();
        String endpoint = '/services/data/v64.0/sobjects/' + objectType;
        String payload = JSON.serialize(recordData);
        
        // Send request FIRST (no DML before callout)
        IntegrationResponse response = connector.sendRequest(endpoint, payload, null, correlationId);
        
        // Log outbound request AFTER callout
        logger.logOutboundMessage(
            correlationId,
            DEFAULT_SYSTEM_NAME,
            payload,
            new Map<String, Object>{
                'endpoint' => endpoint,
                'method' => 'POST',
                'namedCredential' => namedCredential,
                'operation' => 'Create_' + objectType
            }
        );
        
        // Log inbound response
        logger.logInboundMessage(
            correlationId,
            DEFAULT_SYSTEM_NAME,
            response.getResponseBody(),
            new Map<String, Object>{
                'statusCode' => response.getStatusCode(),
                'operation' => 'Create_' + objectType,
                'success' => response.getIsSuccess()
            }
        );
        
        return response;
    }
    
    /**
     * @description Update a record in external system
     * @param namedCredential Named credential to use
     * @param objectType Salesforce object type
     * @param recordId Record ID to update
     * @param recordData Record data as Map
     * @return IntegrationResponse with result
     */
    public static IntegrationResponse updateRecord(String namedCredential, String objectType, String recordId, Map<String, Object> recordData) {
        // Guard clauses
        if (String.isBlank(namedCredential)) {
            throw new IllegalArgumentException('Named credential cannot be null or empty');
        }
        if (String.isBlank(objectType)) {
            throw new IllegalArgumentException('Object type cannot be null or empty');
        }
        if (String.isBlank(recordId)) {
            throw new IllegalArgumentException('Record ID cannot be null or empty');
        }
        if (recordData == null || recordData.isEmpty()) {
            throw new IllegalArgumentException('Record data cannot be null or empty');
        }
        
        IIntegrationLogger logger = new IntegrationLogger();
        RESTConnector connector = new RESTConnector(logger, DEFAULT_SYSTEM_NAME, DEFAULT_TIMEOUT_MS, null);
        
        String correlationId = CorrelationIdGenerator.generateCorrelationId();
        String endpoint = '/services/data/v64.0/sobjects/' + objectType + '/' + recordId;
        String payload = JSON.serialize(recordData);
        
        // Send request FIRST (no DML before callout)
        IntegrationResponse response = connector.sendRequest(endpoint, payload, null, correlationId);
        
        // Log outbound request AFTER callout
        logger.logOutboundMessage(
            correlationId,
            DEFAULT_SYSTEM_NAME,
            payload,
            new Map<String, Object>{
                'endpoint' => endpoint,
                'method' => 'PATCH',
                'namedCredential' => namedCredential,
                'operation' => 'Update_' + objectType,
                'recordId' => recordId
            }
        );
        
        // Log inbound response
        logger.logInboundMessage(
            correlationId,
            DEFAULT_SYSTEM_NAME,
            response.getResponseBody(),
            new Map<String, Object>{
                'statusCode' => response.getStatusCode(),
                'operation' => 'Update_' + objectType,
                'success' => response.getIsSuccess(),
                'recordId' => recordId
            }
        );
        
        return response;
    }
    
    /**
     * @description Query records from external system
     * @param namedCredential Named credential to use
     * @param soqlQuery SOQL query string
     * @return IntegrationResponse with result
     */
    public static IntegrationResponse queryRecords(String namedCredential, String soqlQuery) {
        // Guard clauses
        if (String.isBlank(namedCredential)) {
            throw new IllegalArgumentException('Named credential cannot be null or empty');
        }
        if (String.isBlank(soqlQuery)) {
            throw new IllegalArgumentException('SOQL query cannot be null or empty');
        }
        
        IIntegrationLogger logger = new IntegrationLogger();
        RESTConnector connector = new RESTConnector(logger, DEFAULT_SYSTEM_NAME, DEFAULT_TIMEOUT_MS, null);
        
        String correlationId = CorrelationIdGenerator.generateCorrelationId();
        String endpoint = '/services/data/v64.0/query?q=' + EncodingUtil.urlEncode(soqlQuery, 'UTF-8');
        
        // Send request FIRST (no DML before callout)
        IntegrationResponse response = connector.sendRequest(endpoint, '', null, correlationId);
        
        // Log outbound request AFTER callout
        logger.logOutboundMessage(
            correlationId,
            DEFAULT_SYSTEM_NAME,
            'SOQL Query: ' + soqlQuery,
            new Map<String, Object>{
                'endpoint' => endpoint,
                'method' => 'GET',
                'namedCredential' => namedCredential,
                'operation' => 'Query_Records'
            }
        );
        
        // Log inbound response
        logger.logInboundMessage(
            correlationId,
            DEFAULT_SYSTEM_NAME,
            response.getResponseBody(),
            new Map<String, Object>{
                'statusCode' => response.getStatusCode(),
                'operation' => 'Query_Records',
                'success' => response.getIsSuccess()
            }
        );
        
        return response;
    }
    
    /**
     * @description Delete a record from external system
     * @param namedCredential Named credential to use
     * @param objectType Salesforce object type
     * @param recordId Record ID to delete
     * @return IntegrationResponse with result
     */
    public static IntegrationResponse deleteRecord(String namedCredential, String objectType, String recordId) {
        // Guard clauses
        if (String.isBlank(namedCredential)) {
            throw new IllegalArgumentException('Named credential cannot be null or empty');
        }
        if (String.isBlank(objectType)) {
            throw new IllegalArgumentException('Object type cannot be null or empty');
        }
        if (String.isBlank(recordId)) {
            throw new IllegalArgumentException('Record ID cannot be null or empty');
        }
        
        IIntegrationLogger logger = new IntegrationLogger();
        RESTConnector connector = new RESTConnector(logger, DEFAULT_SYSTEM_NAME, DEFAULT_TIMEOUT_MS, null);
        
        String correlationId = CorrelationIdGenerator.generateCorrelationId();
        String endpoint = '/services/data/v64.0/sobjects/' + objectType + '/' + recordId;
        
        // Send request FIRST (no DML before callout)
        IntegrationResponse response = connector.sendRequest(endpoint, '', null, correlationId);
        
        // Log outbound request AFTER callout
        logger.logOutboundMessage(
            correlationId,
            DEFAULT_SYSTEM_NAME,
            'DELETE Request',
            new Map<String, Object>{
                'endpoint' => endpoint,
                'method' => 'DELETE',
                'namedCredential' => namedCredential,
                'operation' => 'Delete_' + objectType,
                'recordId' => recordId
            }
        );
        
        // Log inbound response
        logger.logInboundMessage(
            correlationId,
            DEFAULT_SYSTEM_NAME,
            response.getResponseBody(),
            new Map<String, Object>{
                'statusCode' => response.getStatusCode(),
                'operation' => 'Delete_' + objectType,
                'success' => response.getIsSuccess(),
                'recordId' => recordId
            }
        );
        
        return response;
    }
    
    /**
     * @description Handle inbound REST API request with automatic logging
     * @param requestBody Incoming request body
     * @param operationType Type of operation being performed
     * @param correlationId Correlation ID for tracking
     * @return Map containing response data
     */
    public static Map<String, Object> handleInboundRequest(String requestBody, String operationType, String correlationId) {
        // Guard clauses
        if (String.isBlank(requestBody)) {
            throw new IllegalArgumentException('Request body cannot be null or empty');
        }
        if (String.isBlank(operationType)) {
            throw new IllegalArgumentException('Operation type cannot be null or empty');
        }
        if (String.isBlank(correlationId)) {
            throw new IllegalArgumentException('Correlation ID cannot be null or empty');
        }
        
        IIntegrationLogger logger = new IntegrationLogger();
        FrameworkErrorHandler errorHandler = new FrameworkErrorHandler(logger);
        
        Long startTime = System.currentTimeMillis();
        
        try {
            // Log inbound request
            logger.logInboundMessage(
                correlationId,
                'External_Client',
                requestBody,
                new Map<String, Object>{
                    'operation' => operationType,
                    'requestTimestamp' => Datetime.now().format(),
                    'source' => 'REST_API'
                }
            );
            
            // Process the request (simulate business logic)
            Map<String, Object> requestData = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
            Map<String, Object> responseData = processBusinessLogic(requestData, operationType);
            
            Long processingTime = System.currentTimeMillis() - startTime;
            
            // Log outbound response
            String responseBody = JSON.serialize(responseData);
            logger.logOutboundMessage(
                correlationId,
                'External_Client',
                responseBody,
                new Map<String, Object>{
                    'operation' => operationType,
                    'processingTime' => processingTime,
                    'responseTimestamp' => Datetime.now().format(),
                    'status' => 'Success'
                }
            );
            
            return responseData;
            
        } catch (Exception e) {
            Long processingTime = System.currentTimeMillis() - startTime;
            
            // Log error
            errorHandler.logFrameworkError(
                correlationId,
                'INBOUND_PROCESSING',
                'Error processing inbound request: ' + e.getMessage(),
                e.getStackTraceString(),
                'High',
                new Map<String, Object>{
                    'operation' => operationType,
                    'processingTime' => processingTime,
                    'requestBody' => requestBody
                }
            );
            
            // Return error response
            return new Map<String, Object>{
                'success' => false,
                'error' => e.getMessage(),
                'correlationId' => correlationId
            };
        }
    }
    
    /**
     * @description Handle create record from inbound request
     * @param requestBody Incoming request body
     * @param objectType Object type to create
     * @param correlationId Correlation ID
     * @return Map containing response data
     */
    public static Map<String, Object> createRecordFromRequest(String requestBody, String objectType, String correlationId) {
        return handleInboundRequest(requestBody, 'Create_' + objectType, correlationId);
    }
    
    /**
     * @description Handle update record from inbound request
     * @param requestBody Incoming request body
     * @param objectType Object type to update
     * @param recordId Record ID to update
     * @param correlationId Correlation ID
     * @return Map containing response data
     */
    public static Map<String, Object> updateRecordFromRequest(String requestBody, String objectType, String recordId, String correlationId) {
        return handleInboundRequest(requestBody, 'Update_' + objectType + '_' + recordId, correlationId);
    }
    
    // Private helper method for business logic simulation
    private static Map<String, Object> processBusinessLogic(Map<String, Object> requestData, String operationType) {
        // Simulate business logic processing
        Map<String, Object> response = new Map<String, Object>{
            'success' => true,
            'operation' => operationType,
            'processedAt' => Datetime.now().format(),
            'recordId' => '001XXXXXXXXXXXXXXX'
        };
        
        // Add request data to response
        response.putAll(requestData);
        
        return response;
    }
}
