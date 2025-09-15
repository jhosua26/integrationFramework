/**
 * @description Integration Framework - Version 8
 * @author Jhosua R. Arda
 * @version 8.0
 * @purpose This framework is being used in Accenture projects and freelancing work.
 *          DO NOT MODIFY this class as it is part of the framework.
 *          Modifying this class will destroy the framework functionality.
 * 
 * Simple demonstration of IntegrationFramework with AccountManagement API
 */
public class SimpleAccountManagementDemo {
    
    /**
     * Demonstrates how to use the framework with your AccountManagement API
     * 
     * Shows how to retrieve account details from an external system using the framework.
     * Includes proper error handling, logging, and response parsing.
     * 
     * accountId - Account ID to retrieve from the external system
     * Returns Account details or null if not found
     */
    public static Account getAccountDetails(String accountId) {
        if (String.isBlank(accountId)) {
            throw new IllegalArgumentException('Account ID cannot be null or empty');
        }
        
        // Initialize framework components
        IIntegrationLogger logger = new IntegrationLogger();
        RESTConnector connector = new RESTConnector(logger, 'S2S_Production', 30000, null);
        
        // Generate correlation ID for tracking
        String correlationId = 'ACCOUNT-GET-' + accountId + '-' + Datetime.now().getTime();
        
        try {
            // Prepare headers for the request
            Map<String, String> headers = new Map<String, String>{
                'Content-Type' => 'application/json',
                'Accept' => 'application/json'
            };
            
            // Make the API call using the connector directly
            IntegrationResponse response = connector.sendRequest(
                'callout:S2S_Production/services/apexrest/accountmgmt/?accid=' + accountId,
                //'callout:S2S_Production/services/apexrest/accountmgmt/?forceError=500',
                '', // Empty payload for GET
                headers,
                'GET', // Explicitly specify GET method
                correlationId
            );
            
            // Check if the request was successful
            if (response.getIsSuccess() && response.getStatusCode() == 200) {
                // Parse the response
                return parseAccountFromResponse(response.getResponseBody());
            } else {
                System.debug('API call failed: ' + response.getErrorMessage());
                return null;
            }
            
        } catch (Exception e) {
            System.debug('Error in getAccountDetails: ' + e.getMessage());
            return null;
        }
    }
    
    /**
     * @description Demonstrates how to create an account using the framework
     * @param name Account name
     * @param phone Account phone
     * @param industry Account industry
     * @return Account ID if successful, null otherwise
     */
    public static String createNewAccount(String name, String phone, String industry) {
        if (String.isBlank(name)) {
            throw new IllegalArgumentException('Account name cannot be null or empty');
        }
        
        // Initialize framework components
        IIntegrationLogger logger = new IntegrationLogger();
        RESTConnector connector = new RESTConnector(logger, 'S2S_Production', 30000, null);
        
        // Generate correlation ID for tracking
        String correlationId = 'ACCOUNT-CREATE-' + name.replaceAll('[^a-zA-Z0-9]', '') + '-' + Datetime.now().getTime();
        
        try {
            // Prepare request payload
            String requestPayload = JSON.serialize(new Map<String, String>{
                'name' => name,
                'phone' => phone,
                'industry' => industry
            });
            
            System.debug('=== CREATE ACCOUNT DEBUG ===');
            System.debug('Correlation ID: ' + correlationId);
            System.debug('Request Payload: ' + requestPayload);
            System.debug('Endpoint: callout:S2S_Production/services/apexrest/accountmgmt/');
            
            // Prepare headers
            Map<String, String> headers = new Map<String, String>{
                'Content-Type' => 'application/json',
                'Accept' => 'application/json'
            };
            
            System.debug('Headers: ' + JSON.serialize(headers));
            
            // Make the API call using the connector directly
            IntegrationResponse response = connector.sendRequest(
                'callout:S2S_Production/services/apexrest/accountmgmt/',
                requestPayload,
                headers,
                'POST', // Explicitly specify POST method
                correlationId
            );
            
            System.debug('=== RESPONSE DEBUG ===');
            System.debug('Response Status Code: ' + response.getStatusCode());
            System.debug('Response Body: ' + response.getResponseBody());
            System.debug('Response Headers: ' + response.getHeaders());
            System.debug('Is Success: ' + response.getIsSuccess());
            System.debug('Error Message: ' + response.getErrorMessage());
            System.debug('Processing Time: ' + response.getProcessingTimeMs() + 'ms');
            
            // Check if the request was successful
            if (response.getIsSuccess() && response.getStatusCode() == 200) {
                // Extract account ID from response
                String accountId = extractAccountIdFromResponse(response.getResponseBody());
                System.debug('Extracted Account ID: ' + accountId);
                return accountId;
            } else {
                System.debug('API call failed: ' + response.getErrorMessage());
                System.debug('Status Code: ' + response.getStatusCode());
                System.debug('Response Body: ' + response.getResponseBody());
                return null;
            }
            
        } catch (Exception e) {
            System.debug('=== EXCEPTION DEBUG ===');
            System.debug('Exception Type: ' + e.getTypeName());
            System.debug('Exception Message: ' + e.getMessage());
            System.debug('Exception Stack Trace: ' + e.getStackTraceString());
            System.debug('Error in createNewAccount: ' + e.getMessage());
            return null;
        }
    }
    
    /**
     * @description Demonstrates how to update an account using the framework
     * @param accountId Account ID to update
     * @param name New account name
     * @param phone New account phone
     * @param industry New account industry
     * @return True if successful, false otherwise
     */
    public static Boolean updateAccountDetails(String accountId, String name, String phone, String industry) {
        if (String.isBlank(accountId)) {
            throw new IllegalArgumentException('Account ID cannot be null or empty');
        }
        
        // Initialize framework components
        IIntegrationLogger logger = new IntegrationLogger();
        RESTConnector connector = new RESTConnector(logger, 'S2S_Production', 30000, null);
        
        // Generate correlation ID for tracking
        String correlationId = 'ACCOUNT-UPDATE-' + accountId + '-' + Datetime.now().getTime();
        
        try {
            // Prepare request payload
            String requestPayload = JSON.serialize(new Map<String, String>{
                'accid' => accountId,
                'name' => name,
                'phone' => phone,
                'industry' => industry
            });
            
            // Prepare headers
            Map<String, String> headers = new Map<String, String>{
                'Content-Type' => 'application/json',
                'Accept' => 'application/json'
            };
            
            // Make the API call using the connector directly
            IntegrationResponse response = connector.sendRequest(
                'callout:S2S_Production/services/apexrest/accountmgmt/',
                requestPayload,
                headers,
                'PUT', // Explicitly specify PUT method
                correlationId
            );
            
            // Check if the request was successful
            return response.getIsSuccess() && response.getStatusCode() == 200;
            
        } catch (Exception e) {
            System.debug('Error in updateAccountDetails: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * @description Demonstrates how to delete an account using the framework
     * @param accountId Account ID to delete
     * @return True if successful, false otherwise
     */
    public static Boolean deleteAccount(String accountId) {
        if (String.isBlank(accountId)) {
            throw new IllegalArgumentException('Account ID cannot be null or empty');
        }
        
        // Initialize framework components
        IIntegrationLogger logger = new IntegrationLogger();
        RESTConnector connector = new RESTConnector(logger, 'S2S_Production', 30000, null);
        
        // Generate correlation ID for tracking
        String correlationId = 'ACCOUNT-DELETE-' + accountId + '-' + Datetime.now().getTime();
        
        try {
            // Prepare headers
            Map<String, String> headers = new Map<String, String>{
                'Content-Type' => 'application/json',
                'Accept' => 'application/json'
            };
            
            // Make the API call using the connector directly
            IntegrationResponse response = connector.sendRequest(
                'callout:S2S_Production/services/apexrest/accountmgmt/?accid=' + accountId,
                '', // Empty payload for DELETE
                headers,
                'DELETE', // Explicitly specify DELETE method
                correlationId
            );
            
            // Check if the request was successful
            return response.getIsSuccess() && response.getStatusCode() == 200;
            
        } catch (Exception e) {
            System.debug('Error in deleteAccount: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * @description Get integration logs for a specific correlation ID
     * @param correlationId Correlation ID to search for
     * @return List of integration logs
     */
    public static List<Integration_Log__c> getIntegrationLogs(String correlationId) {
        return [
            SELECT Id, Direction__c, Message_Type__c, Status__c, Payload__c, 
                   Processing_Time__c, CreatedDate, System__c
            FROM Integration_Log__c 
            WHERE Correlation_ID__c = :correlationId
            ORDER BY CreatedDate DESC
        ];
    }
    
    /**
     * @description Get integration errors for a specific correlation ID
     * @param correlationId Correlation ID to search for
     * @return List of integration errors
     */
    public static List<Integration_Error__c> getIntegrationErrors(String correlationId) {
        return [
            SELECT Id, Error_Type__c, Error_Severity__c, Error_Message__c, 
                   Status__c, Business_Impact__c, Resolution_Notes__c, CreatedDate
            FROM Integration_Error__c 
            WHERE Correlation_ID__c = :correlationId
            ORDER BY CreatedDate DESC
        ];
    }
    
    /**
     * @description Parse Account object from API response
     * @param responseBody JSON response from API
     * @return Account object
     */
    private static Account parseAccountFromResponse(String responseBody) {
        try {
            Map<String, Object> accountData = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
            
            Account acc = new Account();
            acc.Id = (String) accountData.get('Id');
            acc.Name = (String) accountData.get('Name');
            acc.Phone = (String) accountData.get('Phone');
            acc.Industry = (String) accountData.get('Industry');
            
            return acc;
        } catch (Exception e) {
            System.debug('Error parsing account response: ' + e.getMessage());
            return null;
        }
    }
    
    /**
     * @description Extract account ID from create response
     * @param responseBody Response from create API
     * @return Account ID
     */
    private static String extractAccountIdFromResponse(String responseBody) {
        try {
            // Assuming response format: "Account created with Id: 001XXXXXXXXXXXXXXX"
            if (responseBody.contains('Account created with Id:')) {
                return responseBody.substringAfter('Account created with Id:').trim();
            }
            return null;
        } catch (Exception e) {
            System.debug('Error extracting account ID: ' + e.getMessage());
            return null;
        }
    }
    
    /**
     * @description Test method specifically for testing retry logic with 500 errors
     * @param accountId Account ID to retrieve
     * @return Account details or null if not found
     */
    public static Account testRetryLogic(String accountId) {
        if (String.isBlank(accountId)) {
            throw new IllegalArgumentException('Account ID cannot be null or empty');
        }
        
        // Initialize framework components
        IIntegrationLogger logger = new IntegrationLogger();
        RESTConnector connector = new RESTConnector(logger, 'S2S_Production', 30000, null);
        
        // Generate correlation ID for tracking
        String correlationId = 'RETRY-TEST-' + accountId + '-' + Datetime.now().getTime();
        
        try {
            // Prepare headers for the request
            Map<String, String> headers = new Map<String, String>{
                'Content-Type' => 'application/json',
                'Accept' => 'application/json'
            };
            
            // Make the API call using the connector directly - this will trigger 500 error
            IntegrationResponse response = connector.sendRequest(
                'callout:S2S_Production/services/apexrest/accountmgmt/?forceError=500',
                '', // Empty payload for GET
                headers,
                'GET', // Explicitly specify GET method
                correlationId
            );
            
            // Check if the request was successful
            if (response.getIsSuccess() && response.getStatusCode() == 200) {
                // Parse the response
                return parseAccountFromResponse(response.getResponseBody());
            } else {
                System.debug('API call failed: ' + response.getErrorMessage());
                return null;
            }
            
        } catch (Exception e) {
            System.debug('Error in testRetryLogic: ' + e.getMessage());
            return null;
        }
    }
    
    /**
     * @description Demonstrates how to use the framework with helper methods
     * @param accountId Account ID to retrieve
     * @return Account details using helper methods
     */
    public static Account getAccountUsingHelpers(String accountId) {
        if (String.isBlank(accountId)) {
            throw new IllegalArgumentException('Account ID cannot be null or empty');
        }
        
        // Use IntegrationHelpers for simplified callout
        IntegrationResponse response = IntegrationHelpers.queryRecords(
            'S2S_Production',
            'SELECT Id, Name, Phone, Industry FROM Account WHERE Id = \'' + accountId + '\''
        );
        
        if (response.getIsSuccess() && response.getStatusCode() == 200) {
            return parseAccountFromResponse(response.getResponseBody());
        }
        
        return null;
    }
}
