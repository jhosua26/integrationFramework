/**
 * @description Integration Framework - Version 8
 * @author Jhosua R. Arda
 * @version 8.0
 * @purpose This framework is being used in Accenture projects and freelancing work.
 *          DO NOT MODIFY this class as it is part of the framework.
 *          Modifying this class will destroy the framework functionality.
 * 
 * Demo class showing how external Salesforce orgs can call our REST API
 * using Integration Framework with all HTTP methods
 */
public with sharing class ExternalSalesforceCaller {
    
    // Configuration for the external Salesforce org
    private static final String EXTERNAL_SF_ENDPOINT = 'https://your-salesforce-instance.salesforce.com/services/apexrest/integration-demo';
    private static final String EXTERNAL_SF_SYSTEM = 'External_SF';
    
    /**
     * @description GET - Retrieve account data from external Salesforce
     * @param accountId Account ID to retrieve (optional)
     * @param industry Industry filter (optional)
     * @return Response from external Salesforce
     */
    public static Map<String, Object> getAccountData(String accountId, String industry) {
        try {
            // Build query parameters
            Map<String, String> queryParams = new Map<String, String>();
            if (String.isNotBlank(accountId)) {
                queryParams.put('accountId', accountId);
            }
            if (String.isNotBlank(industry)) {
                queryParams.put('industry', industry);
            }
            
            // Use framework components properly
            IIntegrationLogger logger = IntegrationLogger.getInstance();
            RESTConnector connector = new RESTConnector(logger, EXTERNAL_SF_SYSTEM, 30000, null);
            
            // Generate proper correlation ID using framework utility
            String correlationId = CorrelationIdGenerator.generateCorrelationId('GET');
            
            // Execute request using RESTConnector (handles all HTTP methods)
            IntegrationResponse response = connector.sendRequest(
                EXTERNAL_SF_ENDPOINT + buildQueryString(queryParams),
                null, // No body for GET
                new Map<String, String>{
                    'Content-Type' => 'application/json',
                    'Accept' => 'application/json'
                },
                'GET',
                correlationId
            );
            
            if (response.getIsSuccess()) {
                return (Map<String, Object>) JSON.deserializeUntyped(response.getResponseBody());
            } else {
                throw new CalloutException('GET request failed: ' + response.getErrorMessage());
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to get account data: ' + e.getMessage());
            throw new CalloutException('GET request failed: ' + e.getMessage());
        }
    }
    
    /**
     * @description POST - Create new account in external Salesforce
     * @param accountData Account data to create
     * @return Response from external Salesforce
     */
    public static Map<String, Object> createAccount(Map<String, Object> accountData) {
        try {
            // Validate required fields
            if (!accountData.containsKey('name') || String.isBlank((String) accountData.get('name'))) {
                throw new IllegalArgumentException('Account name is required');
            }
            
            // Use framework components properly
            IIntegrationLogger logger = IntegrationLogger.getInstance();
            RESTConnector connector = new RESTConnector(logger, EXTERNAL_SF_SYSTEM, 30000, null);
            
            // Generate proper correlation ID using framework utility
            String correlationId = CorrelationIdGenerator.generateCorrelationId('POST');
            
            // Execute request using RESTConnector
            IntegrationResponse response = connector.sendRequest(
                EXTERNAL_SF_ENDPOINT,
                JSON.serialize(accountData),
                new Map<String, String>{
                    'Content-Type' => 'application/json',
                    'Accept' => 'application/json'
                },
                'POST',
                correlationId
            );
            
            if (response.getIsSuccess()) {
                return (Map<String, Object>) JSON.deserializeUntyped(response.getResponseBody());
            } else {
                throw new CalloutException('POST request failed: ' + response.getErrorMessage());
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to create account: ' + e.getMessage());
            throw new CalloutException('POST request failed: ' + e.getMessage());
        }
    }
    
    /**
     * @description PUT - Update account in external Salesforce (full replacement)
     * @param accountId Account ID to update
     * @param accountData Complete account data
     * @return Response from external Salesforce
     */
    public static Map<String, Object> updateAccount(String accountId, Map<String, Object> accountData) {
        try {
            if (String.isBlank(accountId)) {
                throw new IllegalArgumentException('Account ID is required for update');
            }
            
            // Add ID to the data
            accountData.put('id', accountId);
            
            // Use framework components properly
            IIntegrationLogger logger = IntegrationLogger.getInstance();
            RESTConnector connector = new RESTConnector(logger, EXTERNAL_SF_SYSTEM, 30000, null);
            
            // Generate proper correlation ID using framework utility
            String correlationId = CorrelationIdGenerator.generateCorrelationId('PUT');
            
            // Execute request using RESTConnector
            IntegrationResponse response = connector.sendRequest(
                EXTERNAL_SF_ENDPOINT,
                JSON.serialize(accountData),
                new Map<String, String>{
                    'Content-Type' => 'application/json',
                    'Accept' => 'application/json'
                },
                'PUT',
                correlationId
            );
            
            if (response.getIsSuccess()) {
                return (Map<String, Object>) JSON.deserializeUntyped(response.getResponseBody());
            } else {
                throw new CalloutException('PUT request failed: ' + response.getErrorMessage());
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to update account: ' + e.getMessage());
            throw new CalloutException('PUT request failed: ' + e.getMessage());
        }
    }
    
    /**
     * @description PATCH - Partial update of account in external Salesforce
     * @param accountId Account ID to update
     * @param partialData Partial account data to update
     * @return Response from external Salesforce
     */
    public static Map<String, Object> patchAccount(String accountId, Map<String, Object> partialData) {
        try {
            if (String.isBlank(accountId)) {
                throw new IllegalArgumentException('Account ID is required for update');
            }
            
            // Add ID to the data
            partialData.put('id', accountId);
            
            // Use framework components properly
            IIntegrationLogger logger = IntegrationLogger.getInstance();
            RESTConnector connector = new RESTConnector(logger, EXTERNAL_SF_SYSTEM, 30000, null);
            
            // Generate proper correlation ID using framework utility
            String correlationId = CorrelationIdGenerator.generateCorrelationId('PATCH');
            
            // Execute request using RESTConnector
            IntegrationResponse response = connector.sendRequest(
                EXTERNAL_SF_ENDPOINT,
                JSON.serialize(partialData),
                new Map<String, String>{
                    'Content-Type' => 'application/json',
                    'Accept' => 'application/json'
                },
                'PATCH',
                correlationId
            );
            
            if (response.getIsSuccess()) {
                return (Map<String, Object>) JSON.deserializeUntyped(response.getResponseBody());
            } else {
                throw new CalloutException('PATCH request failed: ' + response.getErrorMessage());
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to patch account: ' + e.getMessage());
            throw new CalloutException('PATCH request failed: ' + e.getMessage());
        }
    }
    
    /**
     * @description DELETE - Delete account in external Salesforce
     * @param accountId Account ID to delete
     * @return Response from external Salesforce
     */
    public static Map<String, Object> deleteAccount(String accountId) {
        try {
            if (String.isBlank(accountId)) {
                throw new IllegalArgumentException('Account ID is required for deletion');
            }
            
            // Use framework components properly
            IIntegrationLogger logger = IntegrationLogger.getInstance();
            RESTConnector connector = new RESTConnector(logger, EXTERNAL_SF_SYSTEM, 30000, null);
            
            // Generate proper correlation ID using framework utility
            String correlationId = CorrelationIdGenerator.generateCorrelationId('DELETE');
            
            // Execute request using RESTConnector
            IntegrationResponse response = connector.sendRequest(
                EXTERNAL_SF_ENDPOINT + '?accountId=' + EncodingUtil.urlEncode(accountId, 'UTF-8'),
                null, // No body for DELETE
                new Map<String, String>{
                    'Content-Type' => 'application/json',
                    'Accept' => 'application/json'
                },
                'DELETE',
                correlationId
            );
            
            if (response.getIsSuccess()) {
                return (Map<String, Object>) JSON.deserializeUntyped(response.getResponseBody());
            } else {
                throw new CalloutException('DELETE request failed: ' + response.getErrorMessage());
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to delete account: ' + e.getMessage());
            throw new CalloutException('DELETE request failed: ' + e.getMessage());
        }
    }
    
    /**
     * @description Comprehensive demo method that tests all HTTP methods
     * @return Map containing results of all operations
     */
    public static Map<String, Object> runComprehensiveDemo() {
        Map<String, Object> results = new Map<String, Object>();
        
        try {
            System.debug('🚀 Starting Comprehensive REST API Demo...');
            
            // 1. GET - Retrieve all accounts
            System.debug('📥 Testing GET - Retrieve all accounts');
            Map<String, Object> getResult = getAccountData(null, null);
            results.put('GET_ALL', getResult);
            System.debug('✅ GET successful: ' + getResult.get('message'));
            
            // 2. POST - Create new account
            System.debug('📤 Testing POST - Create new account');
            Map<String, Object> newAccount = new Map<String, Object>{
                'name' => 'Demo Account ' + System.currentTimeMillis(),
                'industry' => 'Technology',
                'phone' => '555-0123',
                'description' => 'Created via REST API demo'
            };
            Map<String, Object> postResult = createAccount(newAccount);
            results.put('POST_CREATE', postResult);
            System.debug('✅ POST successful: ' + postResult.get('message'));
            
            // Extract account ID for subsequent operations
            Map<String, Object> createdAccount = (Map<String, Object>) postResult.get('data');
            String accountId = (String) createdAccount.get('id');
            
            // 3. GET - Retrieve specific account
            System.debug('📥 Testing GET - Retrieve specific account');
            Map<String, Object> getSpecificResult = getAccountData(accountId, null);
            results.put('GET_SPECIFIC', getSpecificResult);
            System.debug('✅ GET specific successful: ' + getSpecificResult.get('message'));
            
            // 4. PUT - Full update
            System.debug('🔄 Testing PUT - Full update');
            Map<String, Object> updateData = new Map<String, Object>{
                'name' => 'Updated Demo Account',
                'industry' => 'Healthcare',
                'phone' => '555-0456',
                'description' => 'Updated via PUT request'
            };
            Map<String, Object> putResult = updateAccount(accountId, updateData);
            results.put('PUT_UPDATE', putResult);
            System.debug('✅ PUT successful: ' + putResult.get('message'));
            
            // 5. PATCH - Partial update
            System.debug('🔧 Testing PATCH - Partial update');
            Map<String, Object> patchData = new Map<String, Object>{
                'phone' => '555-0789',
                'description' => 'Updated via PATCH request'
            };
            Map<String, Object> patchResult = patchAccount(accountId, patchData);
            results.put('PATCH_UPDATE', patchResult);
            System.debug('✅ PATCH successful: ' + patchResult.get('message'));
            
            // 6. GET - Retrieve by industry
            System.debug('📥 Testing GET - Retrieve by industry');
            Map<String, Object> getIndustryResult = getAccountData(null, 'Healthcare');
            results.put('GET_BY_INDUSTRY', getIndustryResult);
            System.debug('✅ GET by industry successful: ' + getIndustryResult.get('message'));
            
            // 7. DELETE - Delete account
            System.debug('🗑️ Testing DELETE - Delete account');
            Map<String, Object> deleteResult = deleteAccount(accountId);
            results.put('DELETE_ACCOUNT', deleteResult);
            System.debug('✅ DELETE successful: ' + deleteResult.get('message'));
            
            results.put('overallSuccess', true);
            results.put('message', 'All HTTP methods tested successfully!');
            System.debug('🎉 Comprehensive demo completed successfully!');
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, '❌ Demo failed: ' + e.getMessage());
            results.put('overallSuccess', false);
            results.put('error', e.getMessage());
            results.put('stackTrace', e.getStackTraceString());
        }
        
        return results;
    }
    
    // ==================== PRIVATE HELPER METHODS ====================
    
    /**
     * @description Build query string from parameters
     */
    private static String buildQueryString(Map<String, String> params) {
        if (params == null || params.isEmpty()) {
            return '';
        }
        
        List<String> queryParts = new List<String>();
        for (String key : params.keySet()) {
            if (String.isNotBlank(params.get(key))) {
                queryParts.add(key + '=' + EncodingUtil.urlEncode(params.get(key), 'UTF-8'));
            }
        }
        
        return queryParts.isEmpty() ? '' : '?' + String.join(queryParts, '&');
    }
    
    /**
     * @description Get integration logs for a specific correlation ID
     */
    public static List<Integration_Log__c> getIntegrationLogs(String correlationId) {
        return [
            SELECT Id, Correlation_ID__c, Direction__c, Message_Type__c, 
                   Status__c, System__c, Timestamp__c, Processing_Time__c
            FROM Integration_Log__c 
            WHERE Correlation_ID__c = :correlationId 
            ORDER BY Timestamp__c ASC
        ];
    }
    
    /**
     * @description Get integration errors for a specific correlation ID
     */
    public static List<Integration_Error__c> getIntegrationErrors(String correlationId) {
        return [
            SELECT Id, Correlation_ID__c, Error_Type__c, Error_Message__c, 
                   Error_Severity__c, Retry_Count__c, Status__c
            FROM Integration_Error__c 
            WHERE Correlation_ID__c = :correlationId 
            ORDER BY CreatedDate ASC
        ];
    }
}

