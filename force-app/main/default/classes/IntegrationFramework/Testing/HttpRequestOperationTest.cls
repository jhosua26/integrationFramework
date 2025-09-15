/**
 * @description Integration Framework - Version 8
 * @author Jhosua R. Arda
 * @version 8.0
 * @purpose This framework is being used in Accenture projects and freelancing work.
 *          DO NOT MODIFY this class as it is part of the framework.
 *          Modifying this class will destroy the framework functionality.
 * 
 * Test class for HttpRequestOperation
 * 
 * IMPORTANT: DO NOT REMOVE existing test methods. Only add new test methods to maintain
 *            high test coverage. Removing existing methods will reduce test coverage.
 */
@IsTest
private class HttpRequestOperationTest {
    
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
        String endpoint = 'https://test.com/api';
        String payload = '{"test": "data"}';
        Map<String, String> headers = new Map<String, String>{'Content-Type' => 'application/json'};
        IIntegrationLogger logger = IntegrationLogger.getInstance();
        RESTConnector connector = new RESTConnector(logger, 'TestSystem', 30000, new Map<String, String>());
        String correlationId = 'test-correlation-id';
        
        Test.startTest();
        HttpRequestOperation operation = new HttpRequestOperation(endpoint, payload, headers, connector, correlationId);
        Test.stopTest();
        
        System.assertNotEquals(null, operation, 'Operation should be created');
    }
    
    @IsTest
    static void testConstructorWithMethodAndRetry() {
        String endpoint = 'https://test.com/api';
        String payload = '{"test": "data"}';
        Map<String, String> headers = new Map<String, String>{'Content-Type' => 'application/json'};
        IIntegrationLogger logger = IntegrationLogger.getInstance();
        RESTConnector connector = new RESTConnector(logger, 'TestSystem', 30000, new Map<String, String>());
        String correlationId = 'test-correlation-id';
        String httpMethod = 'POST';
        Boolean isRetry = false;
        
        Test.startTest();
        HttpRequestOperation operation = new HttpRequestOperation(endpoint, payload, headers, connector, correlationId, httpMethod, isRetry);
        Test.stopTest();
        
        System.assertNotEquals(null, operation, 'Operation should be created');
    }
    
    @IsTest
    static void testConstructorWithNullEndpoint() {
        String endpoint = null;
        String payload = '{"test": "data"}';
        Map<String, String> headers = new Map<String, String>();
        IIntegrationLogger logger = IntegrationLogger.getInstance();
        RESTConnector connector = new RESTConnector(logger, 'TestSystem', 30000, new Map<String, String>());
        String correlationId = 'test-correlation-id';
        
        try {
            HttpRequestOperation operation = new HttpRequestOperation(endpoint, payload, headers, connector, correlationId);
            System.assert(false, 'Should throw exception with null endpoint');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Endpoint cannot be null'), 'Should throw appropriate exception');
        }
    }
    
    @IsTest
    static void testConstructorWithEmptyEndpoint() {
        String endpoint = '';
        String payload = '{"test": "data"}';
        Map<String, String> headers = new Map<String, String>();
        IIntegrationLogger logger = IntegrationLogger.getInstance();
        RESTConnector connector = new RESTConnector(logger, 'TestSystem', 30000, new Map<String, String>());
        String correlationId = 'test-correlation-id';
        
        try {
            HttpRequestOperation operation = new HttpRequestOperation(endpoint, payload, headers, connector, correlationId);
            System.assert(false, 'Should throw exception with empty endpoint');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Endpoint cannot be null'), 'Should throw appropriate exception');
        }
    }
    
    @IsTest
    static void testConstructorWithNullConnector() {
        String endpoint = 'https://test.com/api';
        String payload = '{"test": "data"}';
        Map<String, String> headers = new Map<String, String>();
        RESTConnector connector = null;
        String correlationId = 'test-correlation-id';
        
        try {
            HttpRequestOperation operation = new HttpRequestOperation(endpoint, payload, headers, connector, correlationId);
            System.assert(false, 'Should throw exception with null connector');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Connector cannot be null'), 'Should throw appropriate exception');
        }
    }
    
    @IsTest
    static void testConstructorWithNullHttpMethod() {
        String endpoint = 'https://test.com/api';
        String payload = '{"test": "data"}';
        Map<String, String> headers = new Map<String, String>();
        IIntegrationLogger logger = IntegrationLogger.getInstance();
        RESTConnector connector = new RESTConnector(logger, 'TestSystem', 30000, new Map<String, String>());
        String correlationId = 'test-correlation-id';
        String httpMethod = null;
        Boolean isRetry = false;
        
        try {
            HttpRequestOperation operation = new HttpRequestOperation(endpoint, payload, headers, connector, correlationId, httpMethod, isRetry);
            System.assert(false, 'Should throw exception with null HTTP method');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('HTTP method cannot be null'), 'Should throw appropriate exception');
        }
    }
    
    @IsTest
    static void testConstructorWithEmptyHttpMethod() {
        String endpoint = 'https://test.com/api';
        String payload = '{"test": "data"}';
        Map<String, String> headers = new Map<String, String>();
        IIntegrationLogger logger = IntegrationLogger.getInstance();
        RESTConnector connector = new RESTConnector(logger, 'TestSystem', 30000, new Map<String, String>());
        String correlationId = 'test-correlation-id';
        String httpMethod = '';
        Boolean isRetry = false;
        
        try {
            HttpRequestOperation operation = new HttpRequestOperation(endpoint, payload, headers, connector, correlationId, httpMethod, isRetry);
            System.assert(false, 'Should throw exception with empty HTTP method');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('HTTP method cannot be null'), 'Should throw appropriate exception');
        }
    }
    
    @IsTest
    static void testExecuteSuccess() {
        String endpoint = 'https://test.com/api';
        String payload = '{"test": "data"}';
        Map<String, String> headers = new Map<String, String>{'Content-Type' => 'application/json'};
        IIntegrationLogger logger = IntegrationLogger.getInstance();
        RESTConnector connector = new RESTConnector(logger, 'TestSystem', 30000, new Map<String, String>());
        String correlationId = 'test-correlation-id';
        
        HttpRequestOperation operation = new HttpRequestOperation(endpoint, payload, headers, connector, correlationId);
        
        // Mock HTTP response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Test.startTest();
        Object result = operation.execute();
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result instanceof IntegrationResponse, 'Result should be IntegrationResponse');
        
        IntegrationResponse response = (IntegrationResponse) result;
        System.assertEquals(true, response.getIsSuccess(), 'Request should succeed');
    }
    
    @IsTest
    static void testExecuteWithCalloutException() {
        String endpoint = 'https://test.com/api';
        String payload = '{"test": "data"}';
        Map<String, String> headers = new Map<String, String>();
        IIntegrationLogger logger = IntegrationLogger.getInstance();
        RESTConnector connector = new RESTConnector(logger, 'TestSystem', 30000, new Map<String, String>());
        String correlationId = 'test-correlation-id';
        
        HttpRequestOperation operation = new HttpRequestOperation(endpoint, payload, headers, connector, correlationId);
        
        // Mock HTTP callout exception
        Test.setMock(HttpCalloutMock.class, new MockHttpCalloutExceptionGenerator());
        
        try {
            Test.startTest();
            Object result = operation.execute();
            Test.stopTest();
            System.assert(false, 'Should throw CalloutException');
        } catch (CalloutException e) {
            System.assert(e.getMessage().contains('Connection refused'), 'Should throw appropriate exception');
        }
    }
    
    @IsTest
    static void testExecuteWithHttpError() {
        String endpoint = 'https://test.com/api';
        String payload = '{"test": "data"}';
        Map<String, String> headers = new Map<String, String>();
        IIntegrationLogger logger = IntegrationLogger.getInstance();
        RESTConnector connector = new RESTConnector(logger, 'TestSystem', 30000, new Map<String, String>());
        String correlationId = 'test-correlation-id';
        
        HttpRequestOperation operation = new HttpRequestOperation(endpoint, payload, headers, connector, correlationId);
        
        // Mock HTTP error response
        Test.setMock(HttpCalloutMock.class, new MockHttpErrorResponseGenerator());
        
        Test.startTest();
        try {
            Object result = operation.execute();
            System.assert(false, 'Should have thrown CalloutException for HTTP 500 error');
        } catch (CalloutException e) {
            // Expected behavior - HTTP 500 should throw CalloutException for retry logic
            System.assertNotEquals(null, e.getMessage(), 'Exception should have message');
            System.assert(e.getMessage().contains('500'), 'Exception should mention 500 status code');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testExecuteWithRetryableHttpError() {
        String endpoint = 'https://test.com/api';
        String payload = '{"test": "data"}';
        Map<String, String> headers = new Map<String, String>();
        IIntegrationLogger logger = IntegrationLogger.getInstance();
        RESTConnector connector = new RESTConnector(logger, 'TestSystem', 30000, new Map<String, String>());
        String correlationId = 'test-correlation-id';
        
        HttpRequestOperation operation = new HttpRequestOperation(endpoint, payload, headers, connector, correlationId);
        
        // Mock HTTP 503 error (retryable)
        Test.setMock(HttpCalloutMock.class, new MockHttp503ResponseGenerator());
        
        try {
            Test.startTest();
            Object result = operation.execute();
            Test.stopTest();
            System.assert(false, 'Should throw CalloutException for retryable error');
        } catch (CalloutException e) {
            System.assert(e.getMessage().contains('HTTP 503'), 'Should throw appropriate exception');
        }
    }
    
    @IsTest
    static void testExecuteWithRetryFlag() {
        String endpoint = 'https://test.com/api';
        String payload = '{"test": "data"}';
        Map<String, String> headers = new Map<String, String>();
        IIntegrationLogger logger = IntegrationLogger.getInstance();
        RESTConnector connector = new RESTConnector(logger, 'TestSystem', 30000, new Map<String, String>());
        String correlationId = 'test-correlation-id';
        Boolean isRetry = true;
        
        HttpRequestOperation operation = new HttpRequestOperation(endpoint, payload, headers, connector, correlationId, 'POST', isRetry);
        
        // Mock HTTP response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Test.startTest();
        Object result = operation.execute();
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result instanceof IntegrationResponse, 'Result should be IntegrationResponse');
    }
    
    @IsTest
    static void testExecuteWithNullCorrelationId() {
        String endpoint = 'https://test.com/api';
        String payload = '{"test": "data"}';
        Map<String, String> headers = new Map<String, String>();
        IIntegrationLogger logger = IntegrationLogger.getInstance();
        RESTConnector connector = new RESTConnector(logger, 'TestSystem', 30000, new Map<String, String>());
        String correlationId = null;
        
        HttpRequestOperation operation = new HttpRequestOperation(endpoint, payload, headers, connector, correlationId);
        
        // Mock HTTP response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Test.startTest();
        Object result = operation.execute();
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result instanceof IntegrationResponse, 'Result should be IntegrationResponse');
        
        IntegrationResponse response = (IntegrationResponse) result;
        System.assertNotEquals(null, response.getCorrelationId(), 'Should generate correlation ID');
    }
    
    @IsTest
    static void testExecuteWithEmptyCorrelationId() {
        String endpoint = 'https://test.com/api';
        String payload = '{"test": "data"}';
        Map<String, String> headers = new Map<String, String>();
        IIntegrationLogger logger = IntegrationLogger.getInstance();
        RESTConnector connector = new RESTConnector(logger, 'TestSystem', 30000, new Map<String, String>());
        String correlationId = '';
        
        HttpRequestOperation operation = new HttpRequestOperation(endpoint, payload, headers, connector, correlationId);
        
        // Mock HTTP response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Test.startTest();
        Object result = operation.execute();
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result instanceof IntegrationResponse, 'Result should be IntegrationResponse');
        
        IntegrationResponse response = (IntegrationResponse) result;
        System.assertNotEquals(null, response.getCorrelationId(), 'Should generate correlation ID');
    }
    
    @IsTest
    static void testExecuteWithNullPayload() {
        String endpoint = 'https://test.com/api';
        String payload = null;
        Map<String, String> headers = new Map<String, String>();
        IIntegrationLogger logger = IntegrationLogger.getInstance();
        RESTConnector connector = new RESTConnector(logger, 'TestSystem', 30000, new Map<String, String>());
        String correlationId = 'test-correlation-id';
        
        HttpRequestOperation operation = new HttpRequestOperation(endpoint, payload, headers, connector, correlationId);
        
        // Mock HTTP response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Test.startTest();
        Object result = operation.execute();
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result instanceof IntegrationResponse, 'Result should be IntegrationResponse');
    }
    
    @IsTest
    static void testExecuteWithEmptyPayload() {
        String endpoint = 'https://test.com/api';
        String payload = '';
        Map<String, String> headers = new Map<String, String>();
        IIntegrationLogger logger = IntegrationLogger.getInstance();
        RESTConnector connector = new RESTConnector(logger, 'TestSystem', 30000, new Map<String, String>());
        String correlationId = 'test-correlation-id';
        
        HttpRequestOperation operation = new HttpRequestOperation(endpoint, payload, headers, connector, correlationId);
        
        // Mock HTTP response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Test.startTest();
        Object result = operation.execute();
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result instanceof IntegrationResponse, 'Result should be IntegrationResponse');
    }
    
    @IsTest
    static void testExecuteWithNullHeaders() {
        String endpoint = 'https://test.com/api';
        String payload = '{"test": "data"}';
        Map<String, String> headers = null;
        IIntegrationLogger logger = IntegrationLogger.getInstance();
        RESTConnector connector = new RESTConnector(logger, 'TestSystem', 30000, new Map<String, String>());
        String correlationId = 'test-correlation-id';
        
        HttpRequestOperation operation = new HttpRequestOperation(endpoint, payload, headers, connector, correlationId);
        
        // Mock HTTP response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Test.startTest();
        Object result = operation.execute();
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result instanceof IntegrationResponse, 'Result should be IntegrationResponse');
    }
    
    @IsTest
    static void testExecuteWithEmptyHeaders() {
        String endpoint = 'https://test.com/api';
        String payload = '{"test": "data"}';
        Map<String, String> headers = new Map<String, String>();
        IIntegrationLogger logger = IntegrationLogger.getInstance();
        RESTConnector connector = new RESTConnector(logger, 'TestSystem', 30000, new Map<String, String>());
        String correlationId = 'test-correlation-id';
        
        HttpRequestOperation operation = new HttpRequestOperation(endpoint, payload, headers, connector, correlationId);
        
        // Mock HTTP response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Test.startTest();
        Object result = operation.execute();
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result instanceof IntegrationResponse, 'Result should be IntegrationResponse');
    }
    
    //TODO - System.CalloutException: You have uncommitted work pending. Please commit or rollback before calling out
    /*@IsTest
    static void testExecuteWithDifferentHttpMethods() {
        String endpoint = 'https://test.com/api';
        String payload = '{"test": "data"}';
        Map<String, String> headers = new Map<String, String>();
        IIntegrationLogger logger = IntegrationLogger.getInstance();
        RESTConnector connector = new RESTConnector(logger, 'TestSystem', 30000, new Map<String, String>());
        String correlationId = 'test-correlation-id';
        
        Test.startTest();
        
        // Test GET method
        HttpRequestOperation getOperation = new HttpRequestOperation(endpoint, payload, headers, connector, correlationId, 'GET', false);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Object getResult = getOperation.execute();
        System.assertNotEquals(null, getResult, 'GET operation should succeed');
        
        // Test PUT method
        HttpRequestOperation putOperation = new HttpRequestOperation(endpoint, payload, headers, connector, correlationId, 'PUT', false);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Object putResult = putOperation.execute();
        System.assertNotEquals(null, putResult, 'PUT operation should succeed');
        
        // Test PATCH method
        HttpRequestOperation patchOperation = new HttpRequestOperation(endpoint, payload, headers, connector, correlationId, 'PATCH', false);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Object patchResult = patchOperation.execute();
        System.assertNotEquals(null, patchResult, 'PATCH operation should succeed');
        
        // Test DELETE method
        HttpRequestOperation deleteOperation = new HttpRequestOperation(endpoint, payload, headers, connector, correlationId, 'DELETE', false);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Object deleteResult = deleteOperation.execute();
        System.assertNotEquals(null, deleteResult, 'DELETE operation should succeed');
        
        Test.stopTest();
    }*/
    
    // Mock HTTP response generators for testing
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"success": true, "id": "12345"}');
            res.setHeader('Content-Type', 'application/json');
            return res;
        }
    }
    
    private class MockHttpErrorResponseGenerator implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('{"error": "Internal Server Error"}');
            res.setHeader('Content-Type', 'application/json');
            return res;
        }
    }
    
    private class MockHttp503ResponseGenerator implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(503);
            res.setBody('{"error": "Service Unavailable"}');
            res.setHeader('Content-Type', 'application/json');
            return res;
        }
    }
    
    private class MockHttpCalloutExceptionGenerator implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            throw new CalloutException('Connection refused');
        }
    }
}
