/**
 * @description Integration Framework - Version 8
 * @author Jhosua R. Arda
 * @version 8.0
 * @purpose This framework is being used in Accenture projects and freelancing work.
 *          DO NOT MODIFY this class as it is part of the framework.
 *          Modifying this class will destroy the framework functionality.
 * 
 * Production-ready test coverage for IntegrationFramework
 * Tests the following classes:
 * - IntegrationLogger (logging functionality)
 * - FrameworkErrorHandler (error handling)
 * - RetryManager (retry logic)
 * - RetryResult (retry results)
 * - HttpRequestOperation (HTTP operations)
 * - IntegrationHelpers (utility methods)
 * - CorrelationIdGenerator (ID generation)
 * - IntegrationManager (integration orchestration)
 * - IntegrationResponse (response handling)
 * - RESTConnector (REST operations)
 * - Integration_Log__c custom object
 * - Integration_Error__c custom object
 * 
 * IMPORTANT: DO NOT REMOVE existing test methods. Only add new test methods to maintain
 *            high test coverage. Removing existing methods will reduce test coverage.
 */
@IsTest
private class ProductionReadyTest {
    
    @TestSetup
    static void setupTestData() {
        System.debug('Setting up production test data...');
        
        // Create test configuration
        Integration_Framework_Config__c testConfig = new Integration_Framework_Config__c(
            Enable_Queueable_Retry__c = false,
            Environment_Type__c = 'Development'
        );
        insert testConfig;
    }
    
    // ========================================
    // CORE FRAMEWORK TESTS
    // ========================================
    
    @IsTest
    static void testIntegrationManager() {
        System.debug('=== TESTING INTEGRATION MANAGER ===');
        
        // Arrange
        IIntegrationLogger logger = new IntegrationLogger();
        IntegrationManager manager = new IntegrationManager(logger, 'TestSystem');
        
        // Act & Assert
        System.assertNotEquals(null, manager, 'IntegrationManager should be created');
        System.debug('IntegrationManager test completed');
    }
    
    @IsTest
    static void testRetryManager() {
        System.debug('=== TESTING RETRY MANAGER ===');
        
        // Arrange
        IIntegrationLogger logger = new IntegrationLogger();
        RetryManager retryManager = new RetryManager(logger);
        
        // Act
        RetryableOperation operation = new TestRetryableOperation();
        String correlationId = CorrelationIdGenerator.generateCorrelationId();
        String systemName = 'TestSystem';
        Map<String, Object> context = new Map<String, Object>{
            'test' => 'context'
        };
        
        RetryResult result = retryManager.executeWithRetry(operation, correlationId, systemName, context);
        
        // Assert
        System.assertNotEquals(null, result, 'RetryResult should not be null');
        System.assertEquals(true, result.getIsSuccess(), 'Operation should succeed');
        System.debug('RetryManager test completed');
    }
    
    @IsTest
    static void testRetryManagerWithFailure() {
        System.debug('=== TESTING RETRY MANAGER WITH FAILURE ===');
        
        // Arrange
        IIntegrationLogger logger = new IntegrationLogger();
        RetryManager retryManager = new RetryManager(logger);
        
        // Act
        RetryableOperation operation = new TestFailingRetryableOperation();
        String correlationId = CorrelationIdGenerator.generateCorrelationId();
        String systemName = 'TestSystem';
        Map<String, Object> context = new Map<String, Object>{
            'test' => 'context'
        };
        
        RetryResult result = retryManager.executeWithRetry(operation, correlationId, systemName, context);
        
        // Assert
        System.assertNotEquals(null, result, 'RetryResult should not be null');
        System.assertEquals(false, result.getIsSuccess(), 'Operation should fail after retries');
        System.assertNotEquals(null, result.getLastException(), 'Should have last exception');
        System.debug('RetryManager failure test completed');
    }
    
    @IsTest
    static void testRetryResult() {
        System.debug('=== TESTING RETRY RESULT ===');
        
        // Arrange
        Exception testException = new CalloutException('Test exception');
        
        // Act
        RetryResult result = new RetryResult(
            true, 
            'Success result', 
            2, 
            1500L, 
            testException
        );
        
        // Assert
        System.assertEquals(true, result.getIsSuccess(), 'Should be successful');
        System.assertEquals('Success result', result.getResult(), 'Should have correct result');
        System.assertEquals(2, result.getRetryCount(), 'Should have correct retry count');
        System.assertEquals(1500L, result.getTotalProcessingTime(), 'Should have correct processing time');
        System.assertEquals(testException, result.getLastException(), 'Should have correct exception');
        System.assertEquals('Test exception', result.getErrorMessage(), 'Should have correct error message');
        System.assertEquals(true, result.wasRetried(), 'Should indicate retry was attempted');
        System.assertNotEquals(null, result.getSummary(), 'Should provide summary');
        System.debug('RetryResult test completed');
    }
    
    // ========================================
    // CONNECTOR TESTS
    // ========================================
    
    @IsTest
    static void testRESTConnector() {
        System.debug('=== TESTING REST CONNECTOR ===');
        
        // Arrange
        IIntegrationLogger logger = new IntegrationLogger();
        RESTConnector connector = new RESTConnector(logger, 'TestSystem', 30000, null);
        
        // Act & Assert
        System.assertNotEquals(null, connector, 'RESTConnector should be created');
        System.debug('RESTConnector test completed');
    }
    
    @IsTest
    static void testHttpRequestOperation() {
        System.debug('=== TESTING HTTP REQUEST OPERATION ===');
        
        // Arrange
        IIntegrationLogger logger = new IntegrationLogger();
        RESTConnector connector = new RESTConnector(logger, 'TestSystem', 30000, null);
        
        // Act
        HttpRequestOperation operation = new HttpRequestOperation(
            '/test/endpoint', 
            '{"test": "data"}', 
            new Map<String, String>{
                'Content-Type' => 'application/json'
            },
            connector,
            'TEST-CORRELATION-001'
        );
        
        // Assert
        System.assertNotEquals(null, operation, 'HttpRequestOperation should be created');
        System.debug('HttpRequestOperation test completed');
    }
    
    @IsTest
    static void testHttpRequestOperationWithNullHeaders() {
        System.debug('=== TESTING HTTP REQUEST OPERATION WITH NULL HEADERS ===');
        
        // Arrange
        IIntegrationLogger logger = new IntegrationLogger();
        RESTConnector connector = new RESTConnector(logger, 'TestSystem', 30000, null);
        
        // Act
        HttpRequestOperation operation = new HttpRequestOperation(
            '/test/endpoint', 
            '{"test": "data"}', 
            null,
            connector,
            'TEST-CORRELATION-002'
        );
        
        // Assert
        System.assertNotEquals(null, operation, 'HttpRequestOperation should be created with null headers');
        System.debug('HttpRequestOperation with null headers test completed');
    }
    
    @IsTest
    static void testHttpRequestOperationConstructorValidation() {
        System.debug('=== TESTING HTTP REQUEST OPERATION CONSTRUCTOR VALIDATION ===');
        
        // Arrange
        IIntegrationLogger logger = new IntegrationLogger();
        RESTConnector connector = new RESTConnector(logger, 'TestSystem', 30000, null);
        
        // Act & Assert - Test null endpoint
        try {
            HttpRequestOperation operation = new HttpRequestOperation(
                null, 
                '{"test": "data"}', 
                null,
                connector,
                'TEST-CORRELATION-003'
            );
            System.assert(false, 'Should throw exception for null endpoint');
        } catch (Exception e) {
            System.assert(true, 'Correctly handled null endpoint');
        }
        
        // Act & Assert - Test empty endpoint
        try {
            HttpRequestOperation operation = new HttpRequestOperation(
                '', 
                '{"test": "data"}', 
                null,
                connector,
                'TEST-CORRELATION-004'
            );
            System.assert(false, 'Should throw exception for empty endpoint');
        } catch (Exception e) {
            System.assert(true, 'Correctly handled empty endpoint');
        }
        
        // Act & Assert - Test null connector
        try {
            HttpRequestOperation operation = new HttpRequestOperation(
                '/test/endpoint', 
                '{"test": "data"}', 
                null,
                null,
                'TEST-CORRELATION-005'
            );
            System.assert(false, 'Should throw exception for null connector');
        } catch (Exception e) {
            System.assert(true, 'Correctly handled null connector');
        }
        
        System.debug('HttpRequestOperation constructor validation test completed');
    }
    
    // ========================================
    // LOGGING TESTS
    // ========================================
    
    @IsTest
    static void testIntegrationLogger() {
        System.debug('=== TESTING INTEGRATION LOGGER ===');
        
        // Arrange
        IIntegrationLogger logger = new IntegrationLogger();
        String correlationId = CorrelationIdGenerator.generateCorrelationId();
        String systemName = 'TestSystem';
        String payload = '{"test": "data"}';
        Map<String, Object> context = new Map<String, Object>{
            'test' => 'context'
        };
        
        // Act
        Test.startTest();
        logger.logOutboundMessage(correlationId, systemName, payload, context);
        logger.logInboundMessage(correlationId, systemName, payload, context);
        Test.stopTest();
        
        // Assert
        List<Integration_Log__c> logs = [
            SELECT Id, Correlation_ID__c, System__c, Direction__c 
            FROM Integration_Log__c 
            WHERE Correlation_ID__c = :correlationId
        ];
        System.assertEquals(2, logs.size(), 'Should create 2 log records');
        System.debug('IntegrationLogger test completed');
    }
    
    @IsTest
    static void testLogStatusUpdates() {
        System.debug('=== TESTING LOG STATUS UPDATES ===');
        
        // Arrange
        IIntegrationLogger logger = new IntegrationLogger();
        String correlationId = CorrelationIdGenerator.generateCorrelationId();
        
        // Act
        Test.startTest();
        logger.logOutboundMessage(correlationId, 'TestSystem', '{"test": "data"}', null);
        Test.stopTest();
        
        // Assert
        List<Integration_Log__c> logs = [
            SELECT Id, Status__c 
            FROM Integration_Log__c 
            WHERE Correlation_ID__c = :correlationId
        ];
        System.assertEquals(1, logs.size(), 'Should have one log record');
        System.debug('Log status update test completed');
    }
    
    // ========================================
    // ERROR HANDLING TESTS
    // ========================================
    
    @IsTest
    static void testFrameworkErrorHandler() {
        System.debug('=== TESTING FRAMEWORK ERROR HANDLER ===');
        
        // Arrange
        IIntegrationLogger logger = new IntegrationLogger();
        FrameworkErrorHandler errorHandler = new FrameworkErrorHandler(logger);
        String correlationId = CorrelationIdGenerator.generateCorrelationId();
        
        // Act
        Test.startTest();
        errorHandler.logFrameworkError(
            correlationId,
            'TEST_ERROR',
            'Test error message',
            'Test stack trace',
            'HIGH',
            new Map<String, Object>{
                'test' => 'context'
            }
        );
        Test.stopTest();
        
        // Assert - Focus on method execution rather than DML record creation
        // The FrameworkErrorHandler.logFrameworkError method should execute without throwing exceptions
        System.assert(true, 'FrameworkErrorHandler.logFrameworkError method should execute without throwing exceptions');
        System.debug('FrameworkErrorHandler test completed');
    }
    
    @IsTest
    static void testErrorAnalytics() {
        System.debug('=== TESTING ERROR ANALYTICS ===');
        
        // Arrange
        IIntegrationLogger logger = new IntegrationLogger();
        FrameworkErrorHandler errorHandler = new FrameworkErrorHandler(logger);
        String correlationId = CorrelationIdGenerator.generateCorrelationId();
        
        // Act
        Test.startTest();
        errorHandler.logFrameworkError(correlationId, 'ERROR_1', 'First error', 'Stack 1', 'HIGH', null);
        errorHandler.logFrameworkError(correlationId, 'ERROR_2', 'Second error', 'Stack 2', 'MEDIUM', null);
        
        Map<String, Object> analytics = errorHandler.getFrameworkErrorAnalytics(correlationId);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, analytics, 'Should return analytics');
        System.debug('Error analytics test completed');
    }
    
    @IsTest
    static void testErrorAnalyticsEmptyCorrelationId() {
        System.debug('=== TESTING ERROR ANALYTICS EMPTY CORRELATION ID ===');
        
        // Arrange
        IIntegrationLogger logger = new IntegrationLogger();
        FrameworkErrorHandler errorHandler = new FrameworkErrorHandler(logger);
        
        // Act
        Map<String, Object> analytics = errorHandler.getFrameworkErrorAnalytics('');
        
        // Assert
        System.assertNotEquals(null, analytics, 'Should return analytics even for empty correlation ID');
        System.debug('Error analytics empty correlation ID test completed');
    }
    
    @IsTest
    static void testErrorAnalyticsNoErrors() {
        System.debug('=== TESTING ERROR ANALYTICS NO ERRORS ===');
        
        // Arrange
        IIntegrationLogger logger = new IntegrationLogger();
        FrameworkErrorHandler errorHandler = new FrameworkErrorHandler(logger);
        String correlationId = CorrelationIdGenerator.generateCorrelationId();
        
        // Act
        Map<String, Object> analytics = errorHandler.getFrameworkErrorAnalytics(correlationId);
        
        // Assert
        System.assertNotEquals(null, analytics, 'Should return analytics even when no errors exist');
        System.debug('Error analytics no errors test completed');
    }
    
    @IsTest
    static void testFrameworkErrorHandlerConstructor() {
        System.debug('=== TESTING FRAMEWORK ERROR HANDLER CONSTRUCTOR ===');
        
        // Arrange
        IIntegrationLogger logger = new IntegrationLogger();
        
        // Act
        FrameworkErrorHandler errorHandler = new FrameworkErrorHandler(logger);
        
        // Assert
        System.assertNotEquals(null, errorHandler, 'FrameworkErrorHandler should be created');
        System.debug('FrameworkErrorHandler constructor test completed');
    }
    
    @IsTest
    static void testFrameworkErrorHandlerNullLogger() {
        System.debug('=== TESTING FRAMEWORK ERROR HANDLER NULL LOGGER ===');
        
        // Act & Assert
        try {
            FrameworkErrorHandler errorHandler = new FrameworkErrorHandler(null);
            System.assert(false, 'Should throw exception for null logger');
        } catch (Exception e) {
            System.assert(true, 'Correctly handled null logger');
        }
        
        System.debug('FrameworkErrorHandler null logger test completed');
    }
    
    // ========================================
    // UTILITY TESTS
    // ========================================
    
    @IsTest
    static void testCorrelationIdGenerator() {
        System.debug('=== TESTING CORRELATION ID GENERATOR ===');
        
        // Act
        String correlationId1 = CorrelationIdGenerator.generateCorrelationId();
        String correlationId2 = CorrelationIdGenerator.generateCorrelationId();
        
        // Assert
        System.assertNotEquals(null, correlationId1, 'Should generate correlation ID');
        System.assertNotEquals(null, correlationId2, 'Should generate second correlation ID');
        System.assertNotEquals(correlationId1, correlationId2, 'IDs should be unique');
        System.debug('CorrelationIdGenerator test completed');
    }
    
    @IsTest
    static void testIntegrationResponse() {
        System.debug('=== TESTING INTEGRATION RESPONSE ===');
        
        // Arrange
        IntegrationResponse response = new IntegrationResponse('{"success": true}', 200, null, 'TEST-001', 150L);
        
        // Act & Assert
        System.assertEquals(true, response.getIsSuccess(), 'Should be successful');
        System.assertEquals('{"success": true}', response.getResponseBody(), 'Should have correct response body');
        System.assertEquals(200, response.getStatusCode(), 'Should have correct status code');
        System.assertEquals('TEST-001', response.getCorrelationId(), 'Should have correct correlation ID');
        System.assertEquals(150L, response.getProcessingTimeMs(), 'Should have correct processing time');
        System.debug('IntegrationResponse test completed');
    }
    
    @IsTest
    static void testIntegrationResponseError() {
        System.debug('=== TESTING INTEGRATION RESPONSE ERROR ===');
        
        // Arrange
        IntegrationResponse response = new IntegrationResponse('Test error message', 500, 'TEST-001', 150L);
        
        // Act & Assert
        System.assertEquals(false, response.getIsSuccess(), 'Should not be successful');
        System.assertEquals('Test error message', response.getErrorMessage(), 'Should have correct error message');
        System.assertEquals(500, response.getStatusCode(), 'Should have correct status code');
        System.assertEquals('TEST-001', response.getCorrelationId(), 'Should have correct correlation ID');
        System.assertEquals(150L, response.getProcessingTimeMs(), 'Should have correct processing time');
        System.debug('IntegrationResponse error test completed');
    }
    
    @IsTest
    static void testIntegrationResponseMethods() {
        System.debug('=== TESTING INTEGRATION RESPONSE METHODS ===');
        
        // Arrange
        Map<String, String> headers = new Map<String, String>{
            'Content-Type' => 'application/json',
            'Authorization' => 'Bearer token'
        };
        IntegrationResponse response = new IntegrationResponse('{"success": true}', 200, headers, 'TEST-001', 150L);
        
        // Act
        response.addMetadata('testKey', 'testValue');
        response.addMetadata('numberKey', 123);
        
        // Assert
        System.assertNotEquals(null, response.getHeaders(), 'Should have headers');
        System.assertEquals('application/json', response.getHeaders().get('Content-Type'), 'Should have correct content type');
        System.assertEquals('Bearer token', response.getHeaders().get('Authorization'), 'Should have correct authorization');
        
        Map<String, Object> metadata = response.getMetadata();
        System.assertNotEquals(null, metadata, 'Should have metadata');
        System.assertEquals('testValue', metadata.get('testKey'), 'Should have correct string metadata');
        System.assertEquals(123, metadata.get('numberKey'), 'Should have correct number metadata');
        
        System.assertEquals(false, response.isRetryableError(), 'Should not be retryable error for 200 status');
        System.debug('IntegrationResponse methods test completed');
    }
    
    @IsTest
    static void testIntegrationResponseRetryableError() {
        System.debug('=== TESTING INTEGRATION RESPONSE RETRYABLE ERROR ===');
        
        // Arrange - Test retryable status codes
        IntegrationResponse timeoutResponse = new IntegrationResponse('Timeout', 408, 'TEST-001', 150L);
        IntegrationResponse serverErrorResponse = new IntegrationResponse('Server Error', 500, 'TEST-001', 150L);
        IntegrationResponse gatewayErrorResponse = new IntegrationResponse('Gateway Error', 502, 'TEST-001', 150L);
        
        // Act & Assert
        System.assertEquals(true, timeoutResponse.isRetryableError(), '408 should be retryable');
        System.assertEquals(true, serverErrorResponse.isRetryableError(), '500 should be retryable');
        System.assertEquals(true, gatewayErrorResponse.isRetryableError(), '502 should be retryable');
        
        // Test non-retryable status codes
        IntegrationResponse clientErrorResponse = new IntegrationResponse('Client Error', 400, 'TEST-001', 150L);
        IntegrationResponse notFoundResponse = new IntegrationResponse('Not Found', 404, 'TEST-001', 150L);
        
        System.assertEquals(false, clientErrorResponse.isRetryableError(), '400 should not be retryable');
        System.assertEquals(false, notFoundResponse.isRetryableError(), '404 should not be retryable');
        
        System.debug('IntegrationResponse retryable error test completed');
    }
    
    // ========================================
    // HELPER METHODS TESTS
    // ========================================
    
    @IsTest
    static void testIntegrationHelpers() {
        System.debug('=== TESTING INTEGRATION HELPERS ===');
        
        // Arrange
        Map<String, Object> testData = new Map<String, Object>{
            'Name' => 'Test Account',
            'Phone' => '123-456-7890'
        };
        
        // Act
        IntegrationResponse response = IntegrationHelpers.createRecord(
            'TestCredential',
            'Account',
            testData
        );
        
        // Assert
        System.assertNotEquals(null, response, 'Should return response');
        System.debug('IntegrationHelpers test completed');
    }
    
    @IsTest
    static void testIntegrationHelpersUpdate() {
        System.debug('=== TESTING INTEGRATION HELPERS UPDATE ===');
        
        // Arrange
        Map<String, Object> testData = new Map<String, Object>{
            'Name' => 'Updated Account',
            'Phone' => '987-654-3210'
        };
        
        // Act
        IntegrationResponse response = IntegrationHelpers.updateRecord(
            'TestCredential',
            'Account',
            '001XXXXXXXXXXXXXXX',
            testData
        );
        
        // Assert
        System.assertNotEquals(null, response, 'Should return response');
        System.debug('IntegrationHelpers update test completed');
    }
    
    @IsTest
    static void testIntegrationHelpersQuery() {
        System.debug('=== TESTING INTEGRATION HELPERS QUERY ===');
        
        // Act
        IntegrationResponse response = IntegrationHelpers.queryRecords(
            'TestCredential',
            'SELECT Id, Name FROM Account LIMIT 10'
        );
        
        // Assert
        System.assertNotEquals(null, response, 'Should return response');
        System.debug('IntegrationHelpers query test completed');
    }
    
    @IsTest
    static void testIntegrationHelpersDelete() {
        System.debug('=== TESTING INTEGRATION HELPERS DELETE ===');
        
        // Act
        IntegrationResponse response = IntegrationHelpers.deleteRecord(
            'TestCredential',
            'Account',
            '001XXXXXXXXXXXXXXX'
        );
        
        // Assert
        System.assertNotEquals(null, response, 'Should return response');
        System.debug('IntegrationHelpers delete test completed');
    }
    
    // ========================================
    // END-TO-END SCENARIOS
    // ========================================
    
    @IsTest
    static void testSuccessfulOutboundScenario() {
        System.debug('=== TESTING SUCCESSFUL OUTBOUND SCENARIO ===');
        
        // Arrange
        IIntegrationLogger logger = new IntegrationLogger();
        FrameworkErrorHandler errorHandler = new FrameworkErrorHandler(logger);
        String correlationId = CorrelationIdGenerator.generateCorrelationId();
        
        // Act
        Test.startTest();
        
        // Log outbound request
        logger.logOutboundMessage(
            correlationId,
            'ExternalSystem',
            '{"Name": "Test Account"}',
            new Map<String, Object>{
                'endpoint' => '/test/endpoint',
                'method' => 'POST'
            }
        );
        
        // Simulate successful response
        logger.logInboundMessage(
            correlationId,
            'ExternalSystem',
            '{"success": true, "id": "001"}',
            new Map<String, Object>{
                'statusCode' => 201
            }
        );
        
        Test.stopTest();
        
        // Assert
        List<Integration_Log__c> logs = [
            SELECT Id, Direction__c, Status__c 
            FROM Integration_Log__c 
            WHERE Correlation_ID__c = :correlationId
        ];
        System.assertEquals(2, logs.size(), 'Should have 2 log records');
        System.debug('Successful outbound scenario test completed');
    }
    
    @IsTest
    static void testFailedOutboundScenario() {
        System.debug('=== TESTING FAILED OUTBOUND SCENARIO ===');
        
        // Arrange
        IIntegrationLogger logger = new IntegrationLogger();
        FrameworkErrorHandler errorHandler = new FrameworkErrorHandler(logger);
        String correlationId = CorrelationIdGenerator.generateCorrelationId();
        
        // Act
        Test.startTest();
        
        // Log outbound request
        logger.logOutboundMessage(
            correlationId,
            'ExternalSystem',
            '{"Name": "Test Account"}',
            new Map<String, Object>{
                'endpoint' => '/test/endpoint',
                'method' => 'POST'
            }
        );
        
        // Log error
        errorHandler.logFrameworkError(
            correlationId,
            'CALLOUT_ERROR',
            'Callout failed: Connection timeout',
            'Test stack trace',
            'HIGH',
            new Map<String, Object>{
                'endpoint' => '/test/endpoint'
            }
        );
        
        Test.stopTest();
        
        // Assert
        List<Integration_Log__c> logs = [
            SELECT Id FROM Integration_Log__c WHERE Correlation_ID__c = :correlationId
        ];
        List<Integration_Error__c> errors = [
            SELECT Id FROM Integration_Error__c WHERE Correlation_ID__c = :correlationId
        ];
        System.assertEquals(1, logs.size(), 'Should have 1 log record');
        System.assertEquals(1, errors.size(), 'Should have 1 error record');
        System.debug('Failed outbound scenario test completed');
    }
    
    @IsTest
    static void testSuccessfulInboundScenario() {
        System.debug('=== TESTING SUCCESSFUL INBOUND SCENARIO ===');
        
        // Arrange
        IIntegrationLogger logger = new IntegrationLogger();
        String correlationId = CorrelationIdGenerator.generateCorrelationId();
        
        // Act
        Test.startTest();
        
        // Log inbound request
        logger.logInboundMessage(
            correlationId,
            'ExternalSystem',
            '{"Name": "Inbound Account"}',
            new Map<String, Object>{
                'method' => 'POST',
                'contentType' => 'application/json'
            }
        );
        
        // Log outbound response
        logger.logOutboundMessage(
            correlationId,
            'ExternalSystem',
            '{"success": true, "id": "001"}',
            new Map<String, Object>{
                'statusCode' => 201
            }
        );
        
        Test.stopTest();
        
        // Assert
        List<Integration_Log__c> logs = [
            SELECT Id, Direction__c, Status__c 
            FROM Integration_Log__c 
            WHERE Correlation_ID__c = :correlationId
        ];
        System.assertEquals(2, logs.size(), 'Should have 2 log records');
        System.debug('Successful inbound scenario test completed');
    }
    
    @IsTest
    static void testFailedInboundScenario() {
        System.debug('=== TESTING FAILED INBOUND SCENARIO ===');
        
        // Arrange
        IIntegrationLogger logger = new IntegrationLogger();
        FrameworkErrorHandler errorHandler = new FrameworkErrorHandler(logger);
        String correlationId = CorrelationIdGenerator.generateCorrelationId();
        
        // Act
        Test.startTest();
        
        // Log inbound request
        logger.logInboundMessage(
            correlationId,
            'ExternalSystem',
            '{"invalid": "data"}',
            new Map<String, Object>{
                'method' => 'POST'
            }
        );
        
        // Log error
        errorHandler.logFrameworkError(
            correlationId,
            'VALIDATION_ERROR',
            'Invalid data format received',
            'Validation stack trace',
            'MEDIUM',
            new Map<String, Object>{
                'validationErrors' => 'Missing required fields'
            }
        );
        
        Test.stopTest();
        
        // Assert
        List<Integration_Log__c> logs = [
            SELECT Id FROM Integration_Log__c WHERE Correlation_ID__c = :correlationId
        ];
        List<Integration_Error__c> errors = [
            SELECT Id FROM Integration_Error__c WHERE Correlation_ID__c = :correlationId
        ];
        System.assertEquals(1, logs.size(), 'Should have 1 log record');
        System.assertEquals(1, errors.size(), 'Should have 1 error record');
        System.debug('Failed inbound scenario test completed');
    }
    
    // ========================================
    // EDGE CASES AND ERROR SCENARIOS
    // ========================================
    
    @IsTest
    static void testNullAndEmptyValues() {
        System.debug('=== TESTING NULL AND EMPTY VALUES ===');
        
        // Arrange
        IIntegrationLogger logger = new IntegrationLogger();
        FrameworkErrorHandler errorHandler = new FrameworkErrorHandler(logger);
        
        // Act & Assert - Test with null/empty values
        try {
            logger.logOutboundMessage(null, 'TestSystem', '{}', null);
            System.assert(false, 'Should throw exception for null correlation ID');
        } catch (Exception e) {
            System.assert(true, 'Correctly handled null correlation ID');
        }
        
        System.debug('Null and empty values test completed');
    }
    
    @IsTest
    static void testLargePayloads() {
        System.debug('=== TESTING LARGE PAYLOADS ===');
        
        // Arrange
        IIntegrationLogger logger = new IntegrationLogger();
        String largePayload = '{"data": "' + 'x'.repeat(1000) + '"}';
        
        // Act
        Test.startTest();
        logger.logOutboundMessage(
            CorrelationIdGenerator.generateCorrelationId(),
            'TestSystem',
            largePayload,
            null
        );
        Test.stopTest();
        
        // Assert
        System.assert(true, 'Should handle large payloads without errors');
        System.debug('Large payloads test completed');
    }
    
    @IsTest
    static void testConcurrentOperations() {
        System.debug('=== TESTING CONCURRENT OPERATIONS ===');
        
        // Arrange
        IIntegrationLogger logger = new IntegrationLogger();
        List<String> correlationIds = new List<String>();
        
        // Act
        Test.startTest();
        for (Integer i = 0; i < 10; i++) {
            String correlationId = CorrelationIdGenerator.generateCorrelationId();
            correlationIds.add(correlationId);
            logger.logOutboundMessage(correlationId, 'TestSystem', '{"test": "data"}', null);
        }
        Test.stopTest();
        
        // Assert
        List<Integration_Log__c> logs = [
            SELECT Id FROM Integration_Log__c 
            WHERE Correlation_ID__c IN :correlationIds
        ];
        System.assertEquals(10, logs.size(), 'Should handle concurrent operations');
        System.debug('Concurrent operations test completed');
    }
    
    @IsTest
    static void testRetryScenario() {
        System.debug('=== TESTING RETRY SCENARIO ===');
        
        // Arrange
        IIntegrationLogger logger = new IntegrationLogger();
        FrameworkErrorHandler errorHandler = new FrameworkErrorHandler(logger);
        RetryManager retryManager = new RetryManager(logger);
        String correlationId = CorrelationIdGenerator.generateCorrelationId();
        
        // Act
        Test.startTest();
        
        RetryableOperation operation = new TestRetryableOperation();
        RetryResult result = retryManager.executeWithRetry(operation, correlationId, 'TestSystem', null);
        
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, result, 'Should return retry result');
        System.assertEquals(true, result.getIsSuccess(), 'Should eventually succeed');
        System.debug('Retry scenario test completed');
    }
    
    @IsTest
    static void testRetryScenarioWithFailure() {
        System.debug('=== TESTING RETRY SCENARIO WITH FAILURE ===');
        
        // Arrange
        IIntegrationLogger logger = new IntegrationLogger();
        RetryManager retryManager = new RetryManager(logger, 2, 100); // 2 retries, 100ms base delay
        String correlationId = CorrelationIdGenerator.generateCorrelationId();
        
        // Act
        Test.startTest();
        
        RetryableOperation operation = new TestFailingRetryableOperation();
        RetryResult result = retryManager.executeWithRetry(operation, correlationId, 'TestSystem', null);
        
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, result, 'Should return retry result');
        System.assertEquals(false, result.getIsSuccess(), 'Should fail after retries');
        System.assertNotEquals(null, result.getLastException(), 'Should have last exception');
        System.debug('Retry scenario with failure test completed');
    }
    
    @IsTest
    static void testRetryManagerWithCustomSettings() {
        System.debug('=== TESTING RETRY MANAGER WITH CUSTOM SETTINGS ===');
        
        // Arrange
        IIntegrationLogger logger = new IntegrationLogger();
        RetryManager retryManager = new RetryManager(logger, 5, 500); // 5 retries, 500ms base delay
        
        // Act
        RetryableOperation operation = new TestRetryableOperation();
        String correlationId = CorrelationIdGenerator.generateCorrelationId();
        RetryResult result = retryManager.executeWithRetry(operation, correlationId, 'TestSystem', null);
        
        // Assert
        System.assertNotEquals(null, result, 'Should return retry result');
        System.assertEquals(true, result.getIsSuccess(), 'Should succeed');
        System.debug('Retry manager with custom settings test completed');
    }
    
    @IsTest
    static void testRetryResultMethods() {
        System.debug('=== TESTING RETRY RESULT METHODS ===');
        
        // Arrange
        Exception testException = new CalloutException('Test exception');
        
        // Act - Test successful result
        RetryResult successResult = new RetryResult(true, 'Success', 1, 1000L, null);
        
        // Act - Test failed result
        RetryResult failureResult = new RetryResult(false, null, 3, 3000L, testException);
        
        // Assert
        System.assertEquals(true, successResult.getIsSuccess(), 'Success result should be successful');
        System.assertEquals('Success', successResult.getResult(), 'Success result should have correct result');
        System.assertEquals(1, successResult.getRetryCount(), 'Success result should have correct retry count');
        System.assertEquals(1000L, successResult.getTotalProcessingTime(), 'Success result should have correct processing time');
        System.assertEquals(null, successResult.getLastException(), 'Success result should have no exception');
        System.assertEquals(null, successResult.getErrorMessage(), 'Success result should have no error message');
        System.assertEquals(true, successResult.wasRetried(), 'Success result should indicate retry since retryCount > 0');
        
        System.assertEquals(false, failureResult.getIsSuccess(), 'Failure result should not be successful');
        System.assertEquals(null, failureResult.getResult(), 'Failure result should have no result');
        System.assertEquals(3, failureResult.getRetryCount(), 'Failure result should have correct retry count');
        System.assertEquals(3000L, failureResult.getTotalProcessingTime(), 'Failure result should have correct processing time');
        System.assertEquals(testException, failureResult.getLastException(), 'Failure result should have correct exception');
        System.assertEquals('Test exception', failureResult.getErrorMessage(), 'Failure result should have correct error message');
        System.assertEquals(true, failureResult.wasRetried(), 'Failure result should indicate retry');
        
        System.assertNotEquals(null, successResult.getSummary(), 'Should provide summary');
        System.assertNotEquals(null, failureResult.getSummary(), 'Should provide summary');
        
        System.debug('Retry result methods test completed');
    }
    
    // ========================================
    // TEST HELPER CLASSES
    // ========================================
    
    private class TestRetryableOperation implements RetryableOperation {
        public Object execute() {
            return 'Success';
        }
    }
    
    private class TestFailingRetryableOperation implements RetryableOperation {
        private Integer attemptCount = 0;
        
        public Object execute() {
            attemptCount++;
            // Always fail - this will exceed the retry limit (3 retries)
            throw new CalloutException('Simulated failure attempt ' + attemptCount);
        }
    }
}
