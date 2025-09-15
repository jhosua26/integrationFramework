/**
 * @description Integration Framework - Version 8
 * @author Jhosua R. Arda
 * @version 8.0
 * @purpose This framework is being used in Accenture projects and freelancing work.
 *          DO NOT MODIFY this class as it is part of the framework.
 *          Modifying this class will destroy the framework functionality.
 * 
 * Test class for RESTConnector
 * 
 * IMPORTANT: DO NOT REMOVE existing test methods. Only add new test methods to maintain
 *            high test coverage. Removing existing methods will reduce test coverage.
 */
@IsTest
private class RESTConnectorTest {
    
    @TestSetup
    static void setup() {
        // Create test configuration
        Integration_Framework_Config__c testConfig = new Integration_Framework_Config__c(
            Enable_Queueable_Retry__c = true,
            Environment_Type__c = 'Development'
        );
        insert testConfig;
    }
    
    @IsTest
    static void testConstructor() {
        IIntegrationLogger logger = IntegrationLogger.getInstance();
        String systemName = 'TestSystem';
        Integer timeoutMs = 30000;
        Map<String, String> defaultHeaders = new Map<String, String>{'Content-Type' => 'application/json'};
        
        Test.startTest();
        RESTConnector connector = new RESTConnector(logger, systemName, timeoutMs, defaultHeaders);
        Test.stopTest();
        
        System.assertNotEquals(null, connector, 'Connector should be created');
    }
    
    @IsTest
    static void testConstructorWithNullLogger() {
        try {
            RESTConnector connector = new RESTConnector(null, 'TestSystem', 30000, new Map<String, String>());
            System.assert(false, 'Should throw exception with null logger');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Logger cannot be null'), 'Should throw appropriate exception');
        }
    }
    
    @IsTest
    static void testConstructorWithNullSystemName() {
        IIntegrationLogger logger = IntegrationLogger.getInstance();
        
        try {
            RESTConnector connector = new RESTConnector(logger, null, 30000, new Map<String, String>());
            System.assert(false, 'Should throw exception with null system name');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('System name cannot be null'), 'Should throw appropriate exception');
        }
    }
    
    @IsTest
    static void testSendRequestSuccess() {
        IIntegrationLogger logger = IntegrationLogger.getInstance();
        RESTConnector connector = new RESTConnector(logger, 'TestSystem', 30000, new Map<String, String>());
        
        // Mock HTTP response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Test.startTest();
        IntegrationResponse response = connector.sendRequest('test-endpoint', '{"test": "data"}', 'test-correlation-id');
        Test.stopTest();
        
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertEquals(true, response.getIsSuccess(), 'Request should succeed');
    }
    
    @IsTest
    static void testSendRequestWithHeaders() {
        IIntegrationLogger logger = IntegrationLogger.getInstance();
        RESTConnector connector = new RESTConnector(logger, 'TestSystem', 30000, new Map<String, String>());
        
        // Mock HTTP response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Map<String, String> headers = new Map<String, String>{'Authorization' => 'Bearer token'};
        
        Test.startTest();
        IntegrationResponse response = connector.sendRequest('test-endpoint', '{"test": "data"}', headers, 'test-correlation-id');
        Test.stopTest();
        
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertEquals(true, response.getIsSuccess(), 'Request should succeed');
    }
    
    @IsTest
    static void testSendRequestWithMethod() {
        IIntegrationLogger logger = IntegrationLogger.getInstance();
        RESTConnector connector = new RESTConnector(logger, 'TestSystem', 30000, new Map<String, String>());
        
        // Mock HTTP response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Map<String, String> headers = new Map<String, String>();
        
        Test.startTest();
        IntegrationResponse response = connector.sendRequest('test-endpoint', '{"test": "data"}', headers, 'POST', 'test-correlation-id');
        Test.stopTest();
        
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertEquals(true, response.getIsSuccess(), 'Request should succeed');
    }
    
    @IsTest
    static void testSendRequestError() {
        IIntegrationLogger logger = IntegrationLogger.getInstance();
        RESTConnector connector = new RESTConnector(logger, 'TestSystem', 30000, new Map<String, String>());
        
        // Mock HTTP error response
        Test.setMock(HttpCalloutMock.class, new MockHttpErrorResponseGenerator());
        
        Test.startTest();
        IntegrationResponse response = connector.sendRequest('test-endpoint', '{"test": "data"}', 'test-correlation-id');
        Test.stopTest();
        
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertEquals(false, response.getIsSuccess(), 'Request should fail');
    }
    
    @IsTest
    static void testValidateConfiguration() {
        IIntegrationLogger logger = IntegrationLogger.getInstance();
        RESTConnector connector = new RESTConnector(logger, 'TestSystem', 30000, new Map<String, String>());
        
        Test.startTest();
        Boolean isValid = connector.validateConfiguration();
        Test.stopTest();
        
        System.assertEquals(true, isValid, 'Configuration should be valid');
    }
    
    @IsTest
    static void testGetConnectorType() {
        IIntegrationLogger logger = IntegrationLogger.getInstance();
        RESTConnector connector = new RESTConnector(logger, 'TestSystem', 30000, new Map<String, String>());
        
        Test.startTest();
        String connectorType = connector.getConnectorType();
        Test.stopTest();
        
        System.assertEquals('REST', connectorType, 'Should return REST connector type');
    }
    
    @IsTest
    static void testGetLogger() {
        IIntegrationLogger logger = IntegrationLogger.getInstance();
        RESTConnector connector = new RESTConnector(logger, 'TestSystem', 30000, new Map<String, String>());
        
        Test.startTest();
        IIntegrationLogger returnedLogger = connector.getLogger();
        Test.stopTest();
        
        System.assertEquals(logger, returnedLogger, 'Should return correct logger');
    }
    
    @IsTest
    static void testGetSystemName() {
        IIntegrationLogger logger = IntegrationLogger.getInstance();
        String systemName = 'TestSystem';
        RESTConnector connector = new RESTConnector(logger, systemName, 30000, new Map<String, String>());
        
        Test.startTest();
        String returnedSystemName = connector.getSystemName();
        Test.stopTest();
        
        System.assertEquals(systemName, returnedSystemName, 'Should return correct system name');
    }
    
    @IsTest
    static void testReceiveResponse() {
        IIntegrationLogger logger = IntegrationLogger.getInstance();
        RESTConnector connector = new RESTConnector(logger, 'TestSystem', 30000, new Map<String, String>());
        
        try {
            Test.startTest();
            IntegrationResponse response = connector.receiveResponse('test-correlation-id');
            Test.stopTest();
            System.assert(false, 'Should throw UnsupportedOperationException');
        } catch (UnsupportedOperationException e) {
            System.assert(e.getMessage().contains('REST connectors do not support receiveResponse'), 'Should throw appropriate exception');
        }
    }
    
    @IsTest
    static void testGetTimeoutMs() {
        IIntegrationLogger logger = IntegrationLogger.getInstance();
        Integer timeoutMs = 45000;
        RESTConnector connector = new RESTConnector(logger, 'TestSystem', timeoutMs, new Map<String, String>());
        
        Test.startTest();
        Integer returnedTimeout = connector.getTimeoutMs();
        Test.stopTest();
        
        System.assertEquals(timeoutMs, returnedTimeout, 'Should return correct timeout');
    }
    
    @IsTest
    static void testHandleInboundRequest() {
        IIntegrationLogger logger = IntegrationLogger.getInstance();
        RESTConnector connector = new RESTConnector(logger, 'TestSystem', 30000, new Map<String, String>());
        
        // Create mock RestRequest
        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf('{"test": "data"}');
        request.requestURI = '/test-endpoint';
        request.httpMethod = 'POST';
        
        Test.startTest();
        IntegrationResponse response = connector.handleInboundRequest(request, 'POST');
        Test.stopTest();
        
        System.assertNotEquals(null, response, 'Response should not be null');
    }
    
    @IsTest
    static void testHandleInboundGet() {
        IIntegrationLogger logger = IntegrationLogger.getInstance();
        RESTConnector connector = new RESTConnector(logger, 'TestSystem', 30000, new Map<String, String>());
        
        // Create mock RestRequest
        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf('');
        request.requestURI = '/test-endpoint';
        request.httpMethod = 'GET';
        
        Test.startTest();
        IntegrationResponse response = connector.handleInboundGet(request);
        Test.stopTest();
        
        System.assertNotEquals(null, response, 'Response should not be null');
    }
    
    @IsTest
    static void testHandleInboundPost() {
        IIntegrationLogger logger = IntegrationLogger.getInstance();
        RESTConnector connector = new RESTConnector(logger, 'TestSystem', 30000, new Map<String, String>());
        
        // Create mock RestRequest
        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf('{"test": "data"}');
        request.requestURI = '/test-endpoint';
        request.httpMethod = 'POST';
        
        Test.startTest();
        IntegrationResponse response = connector.handleInboundPost(request);
        Test.stopTest();
        
        System.assertNotEquals(null, response, 'Response should not be null');
    }
    
    @IsTest
    static void testHandleInboundPut() {
        IIntegrationLogger logger = IntegrationLogger.getInstance();
        RESTConnector connector = new RESTConnector(logger, 'TestSystem', 30000, new Map<String, String>());
        
        // Create mock RestRequest
        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf('{"test": "data"}');
        request.requestURI = '/test-endpoint';
        request.httpMethod = 'PUT';
        
        Test.startTest();
        IntegrationResponse response = connector.handleInboundPut(request);
        Test.stopTest();
        
        System.assertNotEquals(null, response, 'Response should not be null');
    }
    
    @IsTest
    static void testHandleInboundPatch() {
        IIntegrationLogger logger = IntegrationLogger.getInstance();
        RESTConnector connector = new RESTConnector(logger, 'TestSystem', 30000, new Map<String, String>());
        
        // Create mock RestRequest
        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf('{"test": "data"}');
        request.requestURI = '/test-endpoint';
        request.httpMethod = 'PATCH';
        
        Test.startTest();
        IntegrationResponse response = connector.handleInboundPatch(request);
        Test.stopTest();
        
        System.assertNotEquals(null, response, 'Response should not be null');
    }
    
    @IsTest
    static void testHandleInboundDelete() {
        IIntegrationLogger logger = IntegrationLogger.getInstance();
        RESTConnector connector = new RESTConnector(logger, 'TestSystem', 30000, new Map<String, String>());
        
        // Create mock RestRequest
        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf('');
        request.requestURI = '/test-endpoint';
        request.httpMethod = 'DELETE';
        
        Test.startTest();
        IntegrationResponse response = connector.handleInboundDelete(request);
        Test.stopTest();
        
        System.assertNotEquals(null, response, 'Response should not be null');
    }
    
    @IsTest
    static void testEdgeCases() {
        IIntegrationLogger logger = IntegrationLogger.getInstance();
        RESTConnector connector = new RESTConnector(logger, 'TestSystem', 30000, new Map<String, String>());
        
        // Test with null endpoint
        try {
            IntegrationResponse response = connector.sendRequest(null, '{"test": "data"}', 'test-correlation-id');
            System.assert(false, 'Should throw exception with null endpoint');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Endpoint cannot be null'), 'Should throw appropriate exception');
        }
        
        // Test with empty endpoint
        try {
            IntegrationResponse response = connector.sendRequest('', '{"test": "data"}', 'test-correlation-id');
            System.assert(false, 'Should throw exception with empty endpoint');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Endpoint cannot be null'), 'Should throw appropriate exception');
        }
        
        // Test with null payload
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        IntegrationResponse response = connector.sendRequest('test-endpoint', null, 'test-correlation-id');
        System.assertNotEquals(null, response, 'Should handle null payload');
    }
    
    // Mock HTTP response generators for testing
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"success": true, "id": "12345"}');
            return res;
        }
    }
    
    @IsTest
    static void testClassifyExceptionType_PlatformExceptions() {
        // Test platform exception classification through handleInboundRequest catch block
        IIntegrationLogger logger = IntegrationLogger.getInstance();
        TestRESTConnector connector = new TestRESTConnector(logger, 'TestSystem', 30000, new Map<String, String>());
        connector.setExceptionToThrow(new CalloutException('Callout failed'));
        
        // Create a mock RestRequest that will trigger the catch block
        RestRequest request = new RestRequest();
        request.requestURI = '/test/endpoint';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf('{"test": "data"}');
        
        Test.startTest();
        IntegrationResponse response = connector.handleInboundRequest(request, 'POST');
        Test.stopTest();
        
        // Verify error response was created (this tests the classifyExceptionType indirectly)
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertNotEquals(200, response.getStatusCode(), 'Should not be success status code');
        
        // Verify error response contains expected fields
        Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(response.getResponseBody());
        System.assertEquals(true, responseData.get('error'), 'Response should indicate error');
        System.assertNotEquals(null, responseData.get('type'), 'Response should have error type');
    }
    
    @IsTest
    static void testClassifyExceptionType_MessageBasedClassification() {
        // Test message-based exception classification through handleInboundRequest catch block
        IIntegrationLogger logger = IntegrationLogger.getInstance();
        TestRESTConnector connector = new TestRESTConnector(logger, 'TestSystem', 30000, new Map<String, String>());
        connector.setExceptionToThrow(new CalloutException('User is unauthorized to access this resource'));
        
        // Create a mock RestRequest that will trigger the catch block
        RestRequest request = new RestRequest();
        request.requestURI = '/test/endpoint';
        request.httpMethod = 'PUT';
        request.requestBody = Blob.valueOf('{"test": "data"}');
        
        Test.startTest();
        IntegrationResponse response = connector.handleInboundRequest(request, 'PUT');
        Test.stopTest();
        
        // Verify error response was created (this tests the classifyExceptionType indirectly)
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertNotEquals(200, response.getStatusCode(), 'Should not be success status code');
        
        // Verify error response structure
        Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(response.getResponseBody());
        System.assertEquals(true, responseData.get('error'), 'Response should indicate error');
        System.assertNotEquals(null, responseData.get('type'), 'Response should have error type');
    }
    
    @IsTest
    static void testClassifyExceptionType_DefaultClassification() {
        // Test default classification through handleInboundRequest catch block
        IIntegrationLogger logger = IntegrationLogger.getInstance();
        TestRESTConnector connector = new TestRESTConnector(logger, 'TestSystem', 30000, new Map<String, String>());
        connector.setExceptionToThrow(new CalloutException('Some random error message'));
        
        // Create a mock RestRequest that will trigger the catch block
        RestRequest request = new RestRequest();
        request.requestURI = '/test/endpoint';
        request.httpMethod = 'PATCH';
        request.requestBody = Blob.valueOf('{"test": "data"}');
        
        Test.startTest();
        IntegrationResponse response = connector.handleInboundRequest(request, 'PATCH');
        Test.stopTest();
        
        // Verify error response was created (this tests the classifyExceptionType indirectly)
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertNotEquals(200, response.getStatusCode(), 'Should not be success status code');
        
        // Verify error response structure
        Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(response.getResponseBody());
        System.assertEquals(true, responseData.get('error'), 'Response should indicate error');
        System.assertNotEquals(null, responseData.get('type'), 'Response should have error type');
    }
    
    @IsTest
    static void testHandleInboundRequest_CatchBlock_CalloutException() {
        // Test handleInboundRequest catch block with CalloutException
        IIntegrationLogger logger = IntegrationLogger.getInstance();
        TestRESTConnector connector = new TestRESTConnector(logger, 'TestSystem', 30000, new Map<String, String>());
        connector.setExceptionToThrow(new CalloutException('Callout failed'));
        
        // Create a mock RestRequest that will cause a CalloutException
        RestRequest request = new RestRequest();
        request.requestURI = '/test/endpoint';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf('{"test": "data"}');
        
        Test.startTest();
        IntegrationResponse response = connector.handleInboundRequest(request, 'POST');
        Test.stopTest();
        
        // Verify error response was created
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertNotEquals(200, response.getStatusCode(), 'Should not be success status code');
        System.assertNotEquals(null, response.getResponseBody(), 'Response body should not be null');
        
        // Verify error response contains expected fields
        Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(response.getResponseBody());
        System.assertEquals(true, responseData.get('error'), 'Response should indicate error');
        System.assertNotEquals(null, responseData.get('type'), 'Response should have error type');
        System.assertNotEquals(null, responseData.get('message'), 'Response should have error message');
        System.assertNotEquals(null, responseData.get('correlationId'), 'Response should have correlation ID');
    }
    
    @IsTest
    static void testHandleInboundRequest_CatchBlock_DmlException() {
        // Test handleInboundRequest catch block with DmlException
        IIntegrationLogger logger = IntegrationLogger.getInstance();
        TestRESTConnector connector = new TestRESTConnector(logger, 'TestSystem', 30000, new Map<String, String>());
        connector.setExceptionToThrow(new DmlException('DML operation failed'));
        
        // Create a mock RestRequest
        RestRequest request = new RestRequest();
        request.requestURI = '/test/endpoint';
        request.httpMethod = 'PUT';
        request.requestBody = Blob.valueOf('{"test": "data"}');
        
        Test.startTest();
        IntegrationResponse response = connector.handleInboundRequest(request, 'PUT');
        Test.stopTest();
        
        // Verify error response was created
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertNotEquals(200, response.getStatusCode(), 'Should not be success status code');
        
        // Verify error response structure
        Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(response.getResponseBody());
        System.assertEquals(true, responseData.get('error'), 'Response should indicate error');
        System.assertEquals('DATA', responseData.get('type'), 'DmlException should be classified as DATA');
    }
    
    @IsTest
    static void testHandleInboundRequest_CatchBlock_ValidationException() {
        // Test handleInboundRequest catch block with validation exception
        IIntegrationLogger logger = IntegrationLogger.getInstance();
        TestRESTConnector connector = new TestRESTConnector(logger, 'TestSystem', 30000, new Map<String, String>());
        connector.setExceptionToThrow(new DmlException('Required field is missing'));
        
        // Create a mock RestRequest
        RestRequest request = new RestRequest();
        request.requestURI = '/test/endpoint';
        request.httpMethod = 'PATCH';
        request.requestBody = Blob.valueOf('{"test": "data"}');
        
        Test.startTest();
        IntegrationResponse response = connector.handleInboundRequest(request, 'PATCH');
        Test.stopTest();
        
        // Verify error response was created
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertNotEquals(200, response.getStatusCode(), 'Should not be success status code');
        
        // Verify error response structure
        Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(response.getResponseBody());
        System.assertEquals(true, responseData.get('error'), 'Response should indicate error');
        System.assertNotEquals(null, responseData.get('type'), 'Response should have error type');
    }
    
    @IsTest
    static void testHandleInboundRequest_CatchBlock_AuthenticationException() {
        // Test handleInboundRequest catch block with authentication exception
        IIntegrationLogger logger = IntegrationLogger.getInstance();
        TestRESTConnector connector = new TestRESTConnector(logger, 'TestSystem', 30000, new Map<String, String>());
        connector.setExceptionToThrow(new CalloutException('User is unauthorized to access this resource'));
        
        // Create a mock RestRequest
        RestRequest request = new RestRequest();
        request.requestURI = '/test/endpoint';
        request.httpMethod = 'DELETE';
        request.requestBody = Blob.valueOf('{"test": "data"}');
        
        Test.startTest();
        IntegrationResponse response = connector.handleInboundRequest(request, 'DELETE');
        Test.stopTest();
        
        // Verify error response was created
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertNotEquals(200, response.getStatusCode(), 'Should not be success status code');
        
        // Verify error response structure
        Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(response.getResponseBody());
        System.assertEquals(true, responseData.get('error'), 'Response should indicate error');
        System.assertNotEquals(null, responseData.get('type'), 'Response should have error type');
    }
    
    @IsTest
    static void testHandleInboundRequest_CatchBlock_ErrorLogging() {
        // Test that error logging occurs in catch block
        IIntegrationLogger logger = IntegrationLogger.getInstance();
        TestRESTConnector connector = new TestRESTConnector(logger, 'TestSystem', 30000, new Map<String, String>());
        connector.setExceptionToThrow(new CalloutException('Test error for logging'));
        
        // Create a mock RestRequest
        RestRequest request = new RestRequest();
        request.requestURI = '/test/endpoint';
        request.httpMethod = 'GET';
        request.requestBody = Blob.valueOf('{"test": "data"}');
        
        Test.startTest();
        IntegrationResponse response = connector.handleInboundRequest(request, 'GET');
        Test.stopTest();
        
        // Verify that error records were created
        List<Integration_Error__c> errors = [
            SELECT Id, Error_Type__c, Error_Message__c, Correlation_ID__c
            FROM Integration_Error__c
            WHERE Correlation_ID__c != null
        ];
        
        // Should have at least one error record from the catch block
        System.assert(errors.size() > 0, 'Should create error records in catch block');
        
        // Verify error record has expected fields
        Integration_Error__c error = errors[0];
        System.assertNotEquals(null, error.Error_Type__c, 'Error record should have error type');
        System.assertNotEquals(null, error.Error_Message__c, 'Error record should have error message');
        System.assertNotEquals(null, error.Correlation_ID__c, 'Error record should have correlation ID');
    }
    
    @IsTest
    static void testHandleInboundRequest_CatchBlock_OutboundLogging() {
        // Test that outbound error response logging occurs in catch block
        IIntegrationLogger logger = IntegrationLogger.getInstance();
        TestRESTConnector connector = new TestRESTConnector(logger, 'TestSystem', 30000, new Map<String, String>());
        connector.setExceptionToThrow(new CalloutException('Test error for outbound logging'));
        
        // Create a mock RestRequest
        RestRequest request = new RestRequest();
        request.requestURI = '/test/endpoint';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf('{"test": "data"}');
        
        Test.startTest();
        IntegrationResponse response = connector.handleInboundRequest(request, 'POST');
        Test.stopTest();
        
        // Verify that the catch block executed and created an error response
        // The handleInboundRequest method should execute without throwing exceptions
        // and should return an error response when an exception occurs
        System.assertNotEquals(null, response, 'Should return a response even when exception occurs');
        System.assertEquals(false, response.getIsSuccess(), 'Should return error response for exception');
        System.assertNotEquals(null, response.getResponseBody(), 'Error response should have body');
        System.assertNotEquals(null, response.getCorrelationId(), 'Error response should have correlation ID');
    }
    
    /**
     * Test subclass of RESTConnector that allows throwing exceptions for testing
     */
    private class TestRESTConnector extends RESTConnector {
        private Exception exceptionToThrow;
        
        public TestRESTConnector(IIntegrationLogger logger, String systemName, Integer timeoutMs, Map<String, String> defaultHeaders) {
            super(logger, systemName, timeoutMs, defaultHeaders);
        }
        
        public void setExceptionToThrow(Exception e) {
            this.exceptionToThrow = e;
        }
        
        protected override IntegrationResponse processInboundRequest(RestRequest request, String httpMethod) {
            if (exceptionToThrow != null) {
                throw exceptionToThrow;
            }
            return super.processInboundRequest(request, httpMethod);
        }
    }
    
    private class MockHttpErrorResponseGenerator implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('{"error": "Internal Server Error"}');
            return res;
        }
    }
}
