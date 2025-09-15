/**
 * @description Integration Framework - Version 8
 * @author Jhosua R. Arda
 * @version 8.0
 * @purpose This framework is being used in Accenture projects and freelancing work.
 *          DO NOT MODIFY this class as it is part of the framework.
 *          Modifying this class will destroy the framework functionality.
 * 
 * Simple business logic handler for Account operations
 * Works with RESTConnector to provide clean separation of concerns
 */
public class AccountBusinessHandler {
    
    /**
     * @description Process GET request - Retrieve account data
     * @param request RestRequest
     * @return Map<String, Object> result
     */
    public static Map<String, Object> processGetRequest(RestRequest request) {
        Map<String, Object> result = new Map<String, Object>();
        
        String accountId = request.params.get('id');
        String name = request.params.get('name');
        String forceError = request.params.get('forceError');
        
        // Check for forced error BEFORE processing
        if (forceError == '500') {
            throw new CalloutException('Internal Server Error - Testing retry logic');
        }
        
        // Additional error testing scenarios
        if (forceError == '400') {
            throw new IllegalArgumentException('Bad Request - Invalid parameters provided');
        }
        
        if (forceError == '401') {
            throw new SecurityException('Unauthorized - Authentication required');
        }
        
        if (forceError == '403') {
            throw new SecurityException('Forbidden - Access denied');
        }
        
        if (forceError == '404') {
            throw new QueryException('Not Found - Account does not exist');
        }
        
        List<Account> accounts = new List<Account>();
        
        if (String.isNotBlank(accountId)) {
            // Get specific account by ID
            accounts = [SELECT Id, Name, Phone, Industry, CreatedDate FROM Account WHERE Id = :accountId LIMIT 1];
        } else if (String.isNotBlank(name)) {
            // Search accounts by name
            accounts = [SELECT Id, Name, Phone, Industry, CreatedDate FROM Account WHERE Name LIKE :('%' + name + '%') LIMIT 10];
        } 
        
        result.put('success', true);
        result.put('method', 'GET');
        result.put('count', accounts.size());
        result.put('accounts', accounts);
        
        return result;
    }
    
    /**
     * @description Process POST request - Create new account
     * @param request RestRequest
     * @return Map<String, Object> result
     */
    public static Map<String, Object> processPostRequest(RestRequest request) {
        String requestBody = request.requestBody.toString();
        
        if (String.isBlank(requestBody)) {
            throw new IllegalArgumentException('Request body cannot be empty for POST request');
        }
        
        Map<String, Object> accountData = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
        
        Account newAccount = new Account();
        newAccount.Name = (String) accountData.get('name');
        newAccount.Phone = (String) accountData.get('phone');
        newAccount.Industry = (String) accountData.get('industry');
        
        insert newAccount;
        
        Map<String, Object> result = new Map<String, Object>{
            'success' => true,
            'method' => 'POST',
            'message' => 'Account created successfully',
            'accountId' => newAccount.Id,
            'account' => newAccount
        };
        
        return result;
    }
    
    /**
     * @description Process PUT request - Update account
     * @param request RestRequest
     * @return Map<String, Object> result
     */
    public static Map<String, Object> processPutRequest(RestRequest request) {
        String requestBody = request.requestBody.toString();
        String forceError = request.params.get('forceError');

        if (forceError == '400') {
            throw new IllegalArgumentException('Bad Request - Invalid parameters provided');
        }
        
        if (String.isBlank(requestBody)) {
            throw new IllegalArgumentException('Request body cannot be empty for PUT request');
        }
        
        Map<String, Object> accountData = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
        String accountId = (String) accountData.get('id');
        
        if (String.isBlank(accountId)) {
            throw new IllegalArgumentException('Account ID is required for PUT request');
        }
        
        List<Account> accounts = [SELECT Id, Name, Phone, Industry FROM Account WHERE Id = :accountId LIMIT 1];
        
        if (accounts.isEmpty()) {
            throw new IllegalArgumentException('Account not found with ID: ' + accountId);
        }
        
        Account accountToUpdate = accounts[0];
        accountToUpdate.Name = (String) accountData.get('name');
        accountToUpdate.Phone = (String) accountData.get('phone');
        accountToUpdate.Industry = (String) accountData.get('industry');
        
        update accountToUpdate;
        
        Map<String, Object> result = new Map<String, Object>{
            'success' => true,
            'method' => 'PUT',
            'message' => 'Account updated successfully',
            'accountId' => accountToUpdate.Id,
            'account' => accountToUpdate
        };
        
        return result;
    }
    
    /**
     * @description Process PATCH request - Partial update account
     * @param request RestRequest
     * @return Map<String, Object> result
     */
    public static Map<String, Object> processPatchRequest(RestRequest request) {
        String requestBody = request.requestBody.toString();
        
        if (String.isBlank(requestBody)) {
            throw new IllegalArgumentException('Request body cannot be empty for PATCH request');
        }
        
        Map<String, Object> accountData = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
        String accountId = (String) accountData.get('id');
        
        if (String.isBlank(accountId)) {
            throw new IllegalArgumentException('Account ID is required for PATCH request');
        }
        
        List<Account> accounts = [SELECT Id, Name, Phone, Industry FROM Account WHERE Id = :accountId LIMIT 1];
        
        if (accounts.isEmpty()) {
            throw new IllegalArgumentException('Account not found with ID: ' + accountId);
        }
        
        Account accountToUpdate = accounts[0];
        
        // Only update fields that are provided
        if (accountData.containsKey('name')) {
            accountToUpdate.Name = (String) accountData.get('name');
        }
        if (accountData.containsKey('phone')) {
            accountToUpdate.Phone = (String) accountData.get('phone');
        }
        if (accountData.containsKey('industry')) {
            accountToUpdate.Industry = (String) accountData.get('industry');
        }
        
        update accountToUpdate;
        
        Map<String, Object> result = new Map<String, Object>{
            'success' => true,
            'method' => 'PATCH',
            'message' => 'Account partially updated successfully',
            'accountId' => accountToUpdate.Id,
            'account' => accountToUpdate
        };
        
        return result;
    }
    
    /**
     * @description Process DELETE request - Delete account
     * @param request RestRequest
     * @return Map<String, Object> result
     */
    public static Map<String, Object> processDeleteRequest(RestRequest request) {
        String accountId = request.params.get('id');
        
        if (String.isBlank(accountId)) {
            throw new IllegalArgumentException('Account ID is required for DELETE request');
        }
        
        List<Account> accounts = [SELECT Id, Name FROM Account WHERE Id = :accountId LIMIT 1];
        
        if (accounts.isEmpty()) {
            throw new IllegalArgumentException('Account not found with ID: ' + accountId);
        }
        
        Account accountToDelete = accounts[0];
        String accountName = accountToDelete.Name;
        
        delete accountToDelete;
        
        Map<String, Object> result = new Map<String, Object>{
            'success' => true,
            'method' => 'DELETE',
            'message' => 'Account "' + accountName + '" deleted successfully',
            'accountId' => accountId
        };
        
        return result;
    }
}
