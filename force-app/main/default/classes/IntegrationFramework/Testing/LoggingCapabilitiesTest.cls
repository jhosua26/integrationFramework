/**
 * @description Integration Framework - Version 8
 * @author Jhosua R. Arda
 * @version 8.0
 * @purpose This framework is being used in Accenture projects and freelancing work.
 *          DO NOT MODIFY this class as it is part of the framework.
 *          Modifying this class will destroy the framework functionality.
 * 
 * Comprehensive test for all logging capabilities
 * Tests the following classes:
 * - IntegrationLogger (main class under test)
 * - FrameworkErrorHandler (error handling)
 * - Integration_Log__c custom object
 * - Integration_Error__c custom object
 * 
 * IMPORTANT: DO NOT REMOVE existing test methods. Only add new test methods to maintain
 *            high test coverage. Removing existing methods will reduce test coverage.
 */
@IsTest
private class LoggingCapabilitiesTest {
    
    @IsTest
    static void testSuccessfulOutboundIntegration() {
        // Test successful outbound integration logging
        System.debug('=== TESTING SUCCESSFUL OUTBOUND INTEGRATION ===');
        
        // Arrange
        IIntegrationLogger logger = new IntegrationLogger();
        String correlationId = CorrelationIdGenerator.generateCorrelationId();
        String systemName = 'External_Salesforce_Org';
        String payload = '{"Name":"Acme Corporation","Phone":"(555) 123-4567","Industry":"Technology"}';
        Map<String, Object> context = new Map<String, Object>{
            'endpoint' => '/services/data/v64.0/sobjects/Account',
            'method' => 'POST',
            'namedCredential' => 'External_SF_Credential',
            'operation' => 'Create_Account'
        };
        
        // Act - Log outbound request
        Test.startTest();
        logger.logOutboundMessage(correlationId, systemName, payload, context);
        
        // Simulate successful response
        String responsePayload = '{"id":"001XXXXXXXXXXXXXXX","success":true,"errors":[]}';
        Map<String, Object> responseContext = new Map<String, Object>{
            'statusCode' => 201,
            'processingTime' => 2500,
            'operation' => 'Create_Account',
            'externalRecordId' => '001XXXXXXXXXXXXXXX'
        };
        logger.logInboundMessage(correlationId, systemName, responsePayload, responseContext);
        Test.stopTest();
        
        // Assert
        List<Integration_Log__c> logs = [
            SELECT Id, Correlation_ID__c, System__c, Payload__c, Direction__c, 
                   Message_Type__c, Status__c
            FROM Integration_Log__c 
            WHERE Correlation_ID__c = :correlationId
            ORDER BY Direction__c DESC
        ];
        
        System.assertEquals(2, logs.size(), 'Should create 2 log records (outbound + inbound)');
        
        // Verify outbound log
        Integration_Log__c outboundLog = logs[0];
        System.assertEquals('Outbound', outboundLog.Direction__c, 'First log should be outbound');
        System.assertEquals('Request', outboundLog.Message_Type__c, 'Should be request type');
        System.assertEquals('Sent', outboundLog.Status__c, 'Should be sent status');
        System.assertEquals(payload, outboundLog.Payload__c, 'Payload should match');
        
        // Verify inbound log
        Integration_Log__c inboundLog = logs[1];
        System.assertEquals('Inbound', inboundLog.Direction__c, 'Second log should be inbound');
        System.assertEquals('Response', inboundLog.Message_Type__c, 'Should be response type');
        System.assertEquals('Received', inboundLog.Status__c, 'Should be received status');
        System.assertEquals(responsePayload, inboundLog.Payload__c, 'Response payload should match');
        
        // Verify no error logs
        List<Integration_Error__c> errors = [
            SELECT Id FROM Integration_Error__c 
            WHERE Correlation_ID__c = :correlationId
        ];
        System.assertEquals(0, errors.size(), 'Should not have any error logs for successful integration');
        
        System.debug('✅ SUCCESSFUL OUTBOUND INTEGRATION TEST PASSED');
    }
    
    @IsTest
    static void testFailedOutboundIntegration() {
        // Test failed outbound integration with error logging
        System.debug('=== TESTING FAILED OUTBOUND INTEGRATION ===');
        
        // Arrange
        IIntegrationLogger logger = new IntegrationLogger();
        FrameworkErrorHandler errorHandler = new FrameworkErrorHandler(logger);
        String correlationId = CorrelationIdGenerator.generateCorrelationId();
        String systemName = 'External_Salesforce_Org';
        String payload = '{"Name":"Test Corporation","Phone":"(555) 999-8888"}';
        Map<String, Object> context = new Map<String, Object>{
            'endpoint' => '/services/data/v64.0/sobjects/Account',
            'method' => 'POST',
            'namedCredential' => 'External_SF_Credential',
            'operation' => 'Create_Account'
        };
        
        // Act - Log outbound request
        Test.startTest();
        logger.logOutboundMessage(correlationId, systemName, payload, context);
        
        // Simulate error
        String errorMessage = 'Callout failed: Connection refused to external Salesforce org';
        String stackTrace = 'System.CalloutException: Callout failed: Connection refused\n  at IntegrationFramework.Connectors.RESTConnector.sendRequest(RESTConnector.cls:45)';
        Map<String, Object> errorContext = new Map<String, Object>{
            'systemName' => systemName,
            'endpoint' => '/services/data/v64.0/sobjects/Account',
            'retryCount' => 0,
            'processingTime' => 5000
        };
        errorHandler.logFrameworkError(correlationId, 'BASIC_ERROR', errorMessage, stackTrace, 'High', errorContext);
        Test.stopTest();
        
        // Assert
        List<Integration_Log__c> logs = [
            SELECT Id, Direction__c, Status__c
            FROM Integration_Log__c 
            WHERE Correlation_ID__c = :correlationId
        ];
        
        System.assertEquals(1, logs.size(), 'Should have 1 outbound log');
        System.assertEquals('Outbound', logs[0].Direction__c, 'Should be outbound');
        System.assertEquals('Sent', logs[0].Status__c, 'Should be sent status');
        
        // Verify error logs
        List<Integration_Error__c> errors = [
            SELECT Id, Error_Type__c, Error_Severity__c, Status__c, Retry_Count__c,
                   Business_Impact__c, Resolution_Notes__c
            FROM Integration_Error__c 
            WHERE Correlation_ID__c = :correlationId
        ];
        
        System.assertEquals(1, errors.size(), 'Should have 1 error log');
        System.assertEquals('PLATFORM', errors[0].Error_Type__c, 'Should classify as PLATFORM error');
        System.assertEquals('HIGH', errors[0].Error_Severity__c, 'Should be HIGH severity');
        System.assertEquals('Open', errors[0].Status__c, 'Should be open status');
        System.assertEquals(0, errors[0].Retry_Count__c, 'Should have 0 retry count');
        System.assertNotEquals(null, errors[0].Business_Impact__c, 'Should have business impact');
        System.assertNotEquals(null, errors[0].Resolution_Notes__c, 'Should have resolution notes');
        
        System.debug('✅ FAILED OUTBOUND INTEGRATION TEST PASSED');
    }
    
    @IsTest
    static void testSuccessfulInboundIntegration() {
        // Test successful inbound integration logging
        System.debug('=== TESTING SUCCESSFUL INBOUND INTEGRATION ===');
        
        // Arrange
        IIntegrationLogger logger = new IntegrationLogger();
        String correlationId = 'EXT-20241201-555666777888'; // External system correlation ID
        String systemName = 'External_ERP_System';
        String payload = '{"accountName":"Global Industries","phoneNumber":"(555) 777-8888","industry":"Manufacturing"}';
        Map<String, Object> context = new Map<String, Object>{
            'endpoint' => '/services/apexrest/v1/accounts',
            'method' => 'POST',
            'contentType' => 'application/json',
            'userAgent' => 'ExternalERP/1.0',
            'clientIP' => '192.168.1.100',
            'operation' => 'Create_Account_From_ERP'
        };
        
        // Act - Log inbound request
        Test.startTest();
        logger.logInboundMessage(correlationId, systemName, payload, context);
        
        // Simulate successful response
        String responsePayload = '{"success":true,"accountId":"001YYYYYYYYYYYYYYY","message":"Account created successfully"}';
        Map<String, Object> responseContext = new Map<String, Object>{
            'statusCode' => 201,
            'processingTime' => 2500,
            'operation' => 'Create_Account_From_ERP',
            'createdRecordId' => '001YYYYYYYYYYYYYYY'
        };
        logger.logOutboundMessage(correlationId, systemName, responsePayload, responseContext);
        Test.stopTest();
        
        // Assert
        List<Integration_Log__c> logs = [
            SELECT Id, Correlation_ID__c, System__c, Payload__c, Direction__c, 
                   Message_Type__c, Status__c
            FROM Integration_Log__c 
            WHERE Correlation_ID__c = :correlationId
            ORDER BY Direction__c ASC
        ];
        
        System.assertEquals(2, logs.size(), 'Should create 2 log records (inbound + outbound)');
        
        // Verify inbound log
        Integration_Log__c inboundLog = logs[0];
        System.assertEquals('Inbound', inboundLog.Direction__c, 'First log should be inbound');
        System.assertEquals('Response', inboundLog.Message_Type__c, 'Should be response type');
        System.assertEquals('Received', inboundLog.Status__c, 'Should be received status');
        System.assertEquals(payload, inboundLog.Payload__c, 'Payload should match');
        
        // Verify outbound log (response)
        Integration_Log__c outboundLog = logs[1];
        System.assertEquals('Outbound', outboundLog.Direction__c, 'Second log should be outbound');
        System.assertEquals('Request', outboundLog.Message_Type__c, 'Should be request type');
        System.assertEquals('Sent', outboundLog.Status__c, 'Should be sent status');
        System.assertEquals(responsePayload, outboundLog.Payload__c, 'Response payload should match');
        
        // Verify no error logs
        List<Integration_Error__c> errors = [
            SELECT Id FROM Integration_Error__c 
            WHERE Correlation_ID__c = :correlationId
        ];
        System.assertEquals(0, errors.size(), 'Should not have any error logs for successful integration');
        
        System.debug('✅ SUCCESSFUL INBOUND INTEGRATION TEST PASSED');
    }
    
    @IsTest
    static void testFailedInboundIntegration() {
        // Test failed inbound integration with validation error
        System.debug('=== TESTING FAILED INBOUND INTEGRATION ===');
        
        // Arrange
        IIntegrationLogger logger = new IntegrationLogger();
        FrameworkErrorHandler errorHandler = new FrameworkErrorHandler(logger);
        String correlationId = 'EXT-20241201-999888777666';
        String systemName = 'External_CRM_System';
        String payload = '{"accountName":"","phoneNumber":"invalid-phone","industry":"Unknown Industry"}';
        Map<String, Object> context = new Map<String, Object>{
            'endpoint' => '/services/apexrest/v1/accounts',
            'method' => 'POST',
            'contentType' => 'application/json',
            'userAgent' => 'ExternalCRM/2.1',
            'clientIP' => '10.0.0.50',
            'operation' => 'Create_Account_From_CRM'
        };
        
        // Act - Log inbound request
        Test.startTest();
        logger.logInboundMessage(correlationId, systemName, payload, context);
        
        // Simulate validation error
        String errorMessage = 'Validation failed: Account name cannot be empty, Phone number format is invalid';
        String stackTrace = 'System.DmlException: Insert failed. First exception on row 0; first error: FIELD_CUSTOM_VALIDATION_EXCEPTION, Account Name cannot be empty: [Name]';
        Map<String, Object> errorContext = new Map<String, Object>{
            'systemName' => systemName,
            'endpoint' => '/services/apexrest/v1/accounts',
            'processingTime' => 1200,
            'validationErrors' => new List<String>{'Account Name cannot be empty', 'Phone number format is invalid'},
            'clientIP' => '10.0.0.50'
        };
        errorHandler.logFrameworkError(correlationId, 'VALIDATION_ERROR', errorMessage, stackTrace, 'Medium', errorContext);
        
        // Simulate error response sent back
        String errorResponsePayload = '{"success":false,"errors":["Account Name cannot be empty","Phone number format is invalid"],"errorCode":"VALIDATION_ERROR"}';
        Map<String, Object> responseContext = new Map<String, Object>{
            'statusCode' => 400,
            'processingTime' => 1200,
            'operation' => 'Create_Account_From_CRM',
            'errorResponse' => true,
            'validationErrors' => 2
        };
        logger.logOutboundMessage(correlationId, systemName, errorResponsePayload, responseContext);
        Test.stopTest();
        
        // Assert
        List<Integration_Log__c> logs = [
            SELECT Id, Direction__c, Status__c
            FROM Integration_Log__c 
            WHERE Correlation_ID__c = :correlationId
        ];
        
        System.assertEquals(2, logs.size(), 'Should have 2 logs (inbound request + outbound error response)');
        
        // Verify error logs
        List<Integration_Error__c> errors = [
            SELECT Id, Error_Type__c, Error_Severity__c, Status__c, Retry_Count__c,
                   Business_Impact__c, Resolution_Notes__c
            FROM Integration_Error__c 
            WHERE Correlation_ID__c = :correlationId
        ];
        
        System.assertEquals(1, errors.size(), 'Should have 1 error log');
        System.assertEquals('DATA', errors[0].Error_Type__c, 'Should classify as DATA error');
        System.assertEquals('MEDIUM', errors[0].Error_Severity__c, 'Should be MEDIUM severity');
        System.assertEquals('Not Retryable', errors[0].Status__c, 'Should be not retryable status');
        System.assertEquals(0, errors[0].Retry_Count__c, 'Should have 0 retry count');
        System.assertNotEquals(null, errors[0].Business_Impact__c, 'Should have business impact');
        System.assertNotEquals(null, errors[0].Resolution_Notes__c, 'Should have resolution notes');
        
        System.debug('✅ FAILED INBOUND INTEGRATION TEST PASSED');
    }
    
    @IsTest
    static void testRetryScenario() {
        // Test retry scenario with multiple error logs
        System.debug('=== TESTING RETRY SCENARIO ===');
        
        // Arrange
        IIntegrationLogger logger = new IntegrationLogger();
        FrameworkErrorHandler errorHandler = new FrameworkErrorHandler(logger);
        String correlationId = CorrelationIdGenerator.generateCorrelationId();
        String systemName = 'External_Billing_System';
        
        // Act - Log initial request
        Test.startTest();
        logger.logOutboundMessage(correlationId, systemName, '{"invoiceNumber":"INV-2024-001","amount":5000.00}', null);
        
        // Simulate first failure
        errorHandler.logFrameworkError(correlationId, 'TIMEOUT', 'Connection timeout after 30 seconds', 'System.CalloutException: Callout failed: Connection timeout', 'High', new Map<String, Object>{'retryCount' => 0, 'systemName' => systemName});
        
        // Simulate second failure
        errorHandler.logFrameworkError(correlationId, 'NETWORK', 'Network unreachable after connection attempt', 'System.CalloutException: Callout failed: Network unreachable', 'High', new Map<String, Object>{'systemName' => systemName}, 1);
        
        // Simulate final failure
        errorHandler.logFrameworkError(correlationId, 'PLATFORM', 'Max retries exceeded (3 attempts). Final error: System down', 'System.CalloutException: Callout failed: System down', 'Critical', new Map<String, Object>{'systemName' => systemName, 'maxRetriesExceeded' => true}, 3);
        Test.stopTest();
        
        // Assert
        List<Integration_Error__c> errors = [
            SELECT Id, Error_Type__c, Error_Severity__c, Status__c, Retry_Count__c
            FROM Integration_Error__c 
            WHERE Correlation_ID__c = :correlationId
            ORDER BY Retry_Count__c ASC
        ];
        
        System.assertEquals(3, errors.size(), 'Should have 3 error logs for retry attempts');
        
        // Verify retry progression
        System.assertEquals('TIMEOUT', errors[0].Error_Type__c, 'First error should be TIMEOUT');
        System.assertEquals('HIGH', errors[0].Error_Severity__c, 'First error should be HIGH severity');
        System.assertEquals('Retrying', errors[0].Status__c, 'First error should be retrying');
        System.assertEquals(0, errors[0].Retry_Count__c, 'First error should have 0 retry count');
        
        System.assertEquals('NETWORK', errors[1].Error_Type__c, 'Second error should be NETWORK');
        System.assertEquals('HIGH', errors[1].Error_Severity__c, 'Second error should be HIGH severity');
        System.assertEquals('Retrying', errors[1].Status__c, 'Second error should be retrying');
        System.assertEquals(1, errors[1].Retry_Count__c, 'Second error should have 1 retry count');
        
        System.assertEquals('PLATFORM', errors[2].Error_Type__c, 'Final error should be PLATFORM');
        System.assertEquals('CRITICAL', errors[2].Error_Severity__c, 'Final error should be CRITICAL severity');
        System.assertEquals('Max Retries Exceeded', errors[2].Status__c, 'Final error should be max retries exceeded');
        System.assertEquals(3, errors[2].Retry_Count__c, 'Final error should have 3 retry count');
        
        System.debug('✅ RETRY SCENARIO TEST PASSED');
    }
    
    @IsTest
    static void testLogStatusUpdates() {
        // Test log status updates
        System.debug('=== TESTING LOG STATUS UPDATES ===');
        
        // Arrange
        IIntegrationLogger logger = new IntegrationLogger();
        String correlationId = CorrelationIdGenerator.generateCorrelationId();
        String systemName = 'TestSystem';
        String payload = '{"test": "data"}';
        
        // Act
        Test.startTest();
        logger.logOutboundMessage(correlationId, systemName, payload, null);
        
        // Update status to completed
        Map<String, Object> updateData = new Map<String, Object>{
            'processingTime' => 1500,
            'retryCount' => 2,
            'statusCode' => 200
        };
        logger.updateLogStatus(correlationId, 'Completed', updateData);
        Test.stopTest();
        
        // Assert
        List<Integration_Log__c> logs = [
            SELECT Id, Status__c, Processing_Time__c, Retry_Count__c
            FROM Integration_Log__c 
            WHERE Correlation_ID__c = :correlationId
        ];
        
        System.assertEquals(1, logs.size(), 'Should have 1 log record');
        System.assertEquals('Completed', logs[0].Status__c, 'Status should be updated to Completed');
        System.assertEquals(1500, logs[0].Processing_Time__c, 'Processing time should be updated');
        System.assertEquals(2, logs[0].Retry_Count__c, 'Retry count should be updated');
        
        System.debug('✅ LOG STATUS UPDATES TEST PASSED');
    }
    
    @IsTest
    static void testErrorAnalytics() {
        // Test error analytics functionality
        System.debug('=== TESTING ERROR ANALYTICS ===');
        
        // Arrange
        IIntegrationLogger logger = new IntegrationLogger();
        FrameworkErrorHandler errorHandler = new FrameworkErrorHandler(logger);
        String correlationId = CorrelationIdGenerator.generateCorrelationId();
        
        // Create multiple errors
        Test.startTest();
        errorHandler.logFrameworkError(correlationId, 'NETWORK', 'First error', 'Stack trace 1', 'High', null);
        errorHandler.logFrameworkError(correlationId, 'TIMEOUT', 'Second error', 'Stack trace 2', 'Medium', null);
        errorHandler.logFrameworkError(correlationId, 'PLATFORM', 'Third error', 'Stack trace 3', 'Low', null);
        
        // Get analytics
        Map<String, Object> analytics = errorHandler.getFrameworkErrorAnalytics(correlationId);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, analytics, 'Should return analytics data');
        System.assertEquals(3, analytics.get('totalErrors'), 'Should have 3 total errors');
        System.assertEquals('IntegrationFramework', analytics.get('framework'), 'Should identify framework');
        
        Map<String, Integer> errorTypes = (Map<String, Integer>) analytics.get('errorTypes');
        System.assert(errorTypes.containsKey('PLATFORM'), 'Should have PLATFORM error type');
        
        Map<String, Integer> severityDistribution = (Map<String, Integer>) analytics.get('severityDistribution');
        System.assertEquals(1, severityDistribution.get('HIGH'), 'Should have 1 HIGH severity error');
        System.assertEquals(1, severityDistribution.get('MEDIUM'), 'Should have 1 MEDIUM severity error');
        System.assertEquals(1, severityDistribution.get('LOW'), 'Should have 1 LOW severity error');
        
        System.debug('✅ ERROR ANALYTICS TEST PASSED');
    }
}
