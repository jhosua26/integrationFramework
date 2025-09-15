/**
 * @description Integration Framework - Version 8
 * @author Jhosua R. Arda
 * @version 8.0
 * @purpose This framework is being used in Accenture projects and freelancing work.
 *          DO NOT MODIFY this class as it is part of the framework.
 *          Modifying this class will destroy the framework functionality.
 * 
 * Test class for IntegrationResponse
 * Tests the following classes:
 * - IntegrationResponse (main class under test)
 * 
 * IMPORTANT: DO NOT REMOVE existing test methods. Only add new test methods to maintain
 *            high test coverage. Removing existing methods will reduce test coverage.
 */
@IsTest
private class IntegrationResponseTest {
    
    @IsTest
    static void testSuccessConstructor() {
        String responseBody = '{"success": true, "id": "12345"}';
        Integer statusCode = 200;
        Map<String, String> headers = new Map<String, String>{'Content-Type' => 'application/json'};
        String correlationId = 'test-correlation-id';
        Long processingTime = 1500L;
        
        Test.startTest();
        IntegrationResponse response = new IntegrationResponse(
            responseBody,
            statusCode,
            headers,
            correlationId,
            processingTime
        );
        Test.stopTest();
        
        System.assertEquals(true, response.getIsSuccess(), 'Should be successful');
        System.assertEquals(responseBody, response.getResponseBody(), 'Should return correct response body');
        System.assertEquals(statusCode, response.getStatusCode(), 'Should return correct status code');
        System.assertEquals(headers, response.getHeaders(), 'Should return correct headers');
        System.assertEquals(correlationId, response.getCorrelationId(), 'Should return correct correlation ID');
        System.assertEquals(processingTime, response.getProcessingTimeMs(), 'Should return correct processing time');
    }
    
    @IsTest
    static void testErrorConstructor() {
        String errorMessage = 'HTTP 500 error: Internal Server Error';
        Integer statusCode = 500;
        String correlationId = 'test-correlation-id';
        Long processingTime = 2000L;
        
        Test.startTest();
        IntegrationResponse response = new IntegrationResponse(
            errorMessage,
            statusCode,
            correlationId,
            processingTime
        );
        Test.stopTest();
        
        System.assertEquals(false, response.getIsSuccess(), 'Should not be successful');
        System.assertEquals(errorMessage, response.getResponseBody(), 'Should return error message');
        System.assertEquals(statusCode, response.getStatusCode(), 'Should return correct status code');
        System.assertEquals(correlationId, response.getCorrelationId(), 'Should return correct correlation ID');
        System.assertEquals(processingTime, response.getProcessingTimeMs(), 'Should return correct processing time');
    }
    
    @IsTest
    static void testSuccessConstructorWithNullHeaders() {
        String responseBody = '{"success": true}';
        Integer statusCode = 200;
        String correlationId = 'test-correlation-id';
        Long processingTime = 1000L;
        
        Test.startTest();
        IntegrationResponse response = new IntegrationResponse(
            responseBody,
            statusCode,
            null,
            correlationId,
            processingTime
        );
        Test.stopTest();
        
        System.assertEquals(true, response.getIsSuccess(), 'Should be successful');
        System.assertEquals(responseBody, response.getResponseBody(), 'Should return correct response body');
        System.assertEquals(statusCode, response.getStatusCode(), 'Should return correct status code');
        System.assertEquals(new Map<String, String>(), response.getHeaders(), 'Should return empty headers map');
        System.assertEquals(correlationId, response.getCorrelationId(), 'Should return correct correlation ID');
        System.assertEquals(processingTime, response.getProcessingTimeMs(), 'Should return correct processing time');
    }
    
    @IsTest
    static void testSuccessConstructorWithEmptyHeaders() {
        String responseBody = '{"success": true}';
        Integer statusCode = 200;
        Map<String, String> headers = new Map<String, String>();
        String correlationId = 'test-correlation-id';
        Long processingTime = 1000L;
        
        Test.startTest();
        IntegrationResponse response = new IntegrationResponse(
            responseBody,
            statusCode,
            headers,
            correlationId,
            processingTime
        );
        Test.stopTest();
        
        System.assertEquals(true, response.getIsSuccess(), 'Should be successful');
        System.assertEquals(responseBody, response.getResponseBody(), 'Should return correct response body');
        System.assertEquals(statusCode, response.getStatusCode(), 'Should return correct status code');
        System.assertEquals(headers, response.getHeaders(), 'Should return empty headers');
        System.assertEquals(correlationId, response.getCorrelationId(), 'Should return correct correlation ID');
        System.assertEquals(processingTime, response.getProcessingTimeMs(), 'Should return correct processing time');
    }
    
    @IsTest
    static void testErrorConstructorWithNullMessage() {
        String errorMessage = null;
        Integer statusCode = 500;
        String correlationId = 'test-correlation-id';
        Long processingTime = 1000L;
        
        Test.startTest();
        IntegrationResponse response = new IntegrationResponse(
            errorMessage,
            statusCode,
            correlationId,
            processingTime
        );
        Test.stopTest();
        
        System.assertEquals(false, response.getIsSuccess(), 'Should not be successful');
        System.assertEquals(null, response.getResponseBody(), 'Should return null response body');
        System.assertEquals(statusCode, response.getStatusCode(), 'Should return correct status code');
        System.assertEquals(correlationId, response.getCorrelationId(), 'Should return correct correlation ID');
        System.assertEquals(processingTime, response.getProcessingTimeMs(), 'Should return correct processing time');
    }
    
    @IsTest
    static void testErrorConstructorWithEmptyMessage() {
        String errorMessage = '';
        Integer statusCode = 404;
        String correlationId = 'test-correlation-id';
        Long processingTime = 500L;
        
        Test.startTest();
        IntegrationResponse response = new IntegrationResponse(
            errorMessage,
            statusCode,
            correlationId,
            processingTime
        );
        Test.stopTest();
        
        System.assertEquals(false, response.getIsSuccess(), 'Should not be successful');
        System.assertEquals('', response.getResponseBody(), 'Should return empty response body');
        System.assertEquals(statusCode, response.getStatusCode(), 'Should return correct status code');
        System.assertEquals(correlationId, response.getCorrelationId(), 'Should return correct correlation ID');
        System.assertEquals(processingTime, response.getProcessingTimeMs(), 'Should return correct processing time');
    }
    
    @IsTest
    static void testSuccessConstructorWithNullCorrelationId() {
        String responseBody = '{"success": true}';
        Integer statusCode = 200;
        Map<String, String> headers = new Map<String, String>();
        String correlationId = null;
        Long processingTime = 1000L;
        
        Test.startTest();
        IntegrationResponse response = new IntegrationResponse(
            responseBody,
            statusCode,
            headers,
            correlationId,
            processingTime
        );
        Test.stopTest();
        
        System.assertEquals(true, response.getIsSuccess(), 'Should be successful');
        System.assertEquals(responseBody, response.getResponseBody(), 'Should return correct response body');
        System.assertEquals(statusCode, response.getStatusCode(), 'Should return correct status code');
        System.assertEquals(headers, response.getHeaders(), 'Should return correct headers');
        System.assertEquals(null, response.getCorrelationId(), 'Should return null correlation ID');
        System.assertEquals(processingTime, response.getProcessingTimeMs(), 'Should return correct processing time');
    }
    
    @IsTest
    static void testSuccessConstructorWithZeroProcessingTime() {
        String responseBody = '{"success": true}';
        Integer statusCode = 200;
        Map<String, String> headers = new Map<String, String>();
        String correlationId = 'test-correlation-id';
        Long processingTime = 0L;
        
        Test.startTest();
        IntegrationResponse response = new IntegrationResponse(
            responseBody,
            statusCode,
            headers,
            correlationId,
            processingTime
        );
        Test.stopTest();
        
        System.assertEquals(true, response.getIsSuccess(), 'Should be successful');
        System.assertEquals(responseBody, response.getResponseBody(), 'Should return correct response body');
        System.assertEquals(statusCode, response.getStatusCode(), 'Should return correct status code');
        System.assertEquals(headers, response.getHeaders(), 'Should return correct headers');
        System.assertEquals(correlationId, response.getCorrelationId(), 'Should return correct correlation ID');
        System.assertEquals(0L, response.getProcessingTimeMs(), 'Should return zero processing time');
    }
    
    @IsTest
    static void testSuccessConstructorWithNegativeProcessingTime() {
        String responseBody = '{"success": true}';
        Integer statusCode = 200;
        Map<String, String> headers = new Map<String, String>();
        String correlationId = 'test-correlation-id';
        Long processingTime = -100L;
        
        Test.startTest();
        IntegrationResponse response = new IntegrationResponse(
            responseBody,
            statusCode,
            headers,
            correlationId,
            processingTime
        );
        Test.stopTest();
        
        System.assertEquals(true, response.getIsSuccess(), 'Should be successful');
        System.assertEquals(responseBody, response.getResponseBody(), 'Should return correct response body');
        System.assertEquals(statusCode, response.getStatusCode(), 'Should return correct status code');
        System.assertEquals(headers, response.getHeaders(), 'Should return correct headers');
        System.assertEquals(correlationId, response.getCorrelationId(), 'Should return correct correlation ID');
        System.assertEquals(-100L, response.getProcessingTimeMs(), 'Should return negative processing time');
    }
    
    @IsTest
    static void testVariousStatusCodeRanges() {
        // Test 2xx success codes
        IntegrationResponse success200 = new IntegrationResponse('OK', 200, new Map<String, String>(), 'test-id', 1000L);
        System.assertEquals(true, success200.getIsSuccess(), '200 should be success');
        
        IntegrationResponse success201 = new IntegrationResponse('Created', 201, new Map<String, String>(), 'test-id', 1000L);
        System.assertEquals(true, success201.getIsSuccess(), '201 should be success');
        
        IntegrationResponse success299 = new IntegrationResponse('OK', 299, new Map<String, String>(), 'test-id', 1000L);
        System.assertEquals(true, success299.getIsSuccess(), '299 should be success');
        
        // Test 4xx error codes
        IntegrationResponse error400 = new IntegrationResponse('Bad Request', 400, 'test-id', 1000L);
        System.assertEquals(false, error400.getIsSuccess(), '400 should be error');
        
        IntegrationResponse error404 = new IntegrationResponse('Not Found', 404, 'test-id', 1000L);
        System.assertEquals(false, error404.getIsSuccess(), '404 should be error');
        
        // Test 5xx error codes
        IntegrationResponse error500 = new IntegrationResponse('Internal Server Error', 500, 'test-id', 1000L);
        System.assertEquals(false, error500.getIsSuccess(), '500 should be error');
        
        IntegrationResponse error503 = new IntegrationResponse('Service Unavailable', 503, 'test-id', 1000L);
        System.assertEquals(false, error503.getIsSuccess(), '503 should be error');
    }
    
    @IsTest
    static void testLargeResponseBody() {
        String largeResponseBody = '{"data": "' + 'x'.repeat(10000) + '"}';
        Integer statusCode = 200;
        Map<String, String> headers = new Map<String, String>();
        String correlationId = 'test-correlation-id';
        Long processingTime = 1000L;
        
        Test.startTest();
        IntegrationResponse response = new IntegrationResponse(
            largeResponseBody,
            statusCode,
            headers,
            correlationId,
            processingTime
        );
        Test.stopTest();
        
        System.assertEquals(true, response.getIsSuccess(), 'Should be successful');
        System.assertEquals(largeResponseBody, response.getResponseBody(), 'Should return large response body');
        System.assertEquals(statusCode, response.getStatusCode(), 'Should return correct status code');
    }
    
    @IsTest
    static void testMultipleHeaders() {
        String responseBody = '{"success": true}';
        Integer statusCode = 200;
        Map<String, String> headers = new Map<String, String>{
            'Content-Type' => 'application/json',
            'Cache-Control' => 'no-cache',
            'X-Custom-Header' => 'custom-value'
        };
        String correlationId = 'test-correlation-id';
        Long processingTime = 1000L;
        
        Test.startTest();
        IntegrationResponse response = new IntegrationResponse(
            responseBody,
            statusCode,
            headers,
            correlationId,
            processingTime
        );
        Test.stopTest();
        
        System.assertEquals(true, response.getIsSuccess(), 'Should be successful');
        System.assertEquals(headers, response.getHeaders(), 'Should return all headers');
        System.assertEquals('application/json', response.getHeaders().get('Content-Type'), 'Should return correct content type');
        System.assertEquals('no-cache', response.getHeaders().get('Cache-Control'), 'Should return correct cache control');
        System.assertEquals('custom-value', response.getHeaders().get('X-Custom-Header'), 'Should return correct custom header');
    }
    
    @IsTest
    static void testAddMetadata_Success() {
        String responseBody = '{"success": true}';
        Integer statusCode = 200;
        Map<String, String> headers = new Map<String, String>();
        String correlationId = 'test-correlation-id';
        Long processingTime = 1000L;
        
        Test.startTest();
        IntegrationResponse response = new IntegrationResponse(
            responseBody,
            statusCode,
            headers,
            correlationId,
            processingTime
        );
        
        // Add metadata
        response.addMetadata('requestId', 'req-12345');
        response.addMetadata('retryCount', 3);
        response.addMetadata('endpoint', '/api/v1/users');
        response.addMetadata('timestamp', System.currentTimeMillis());
        Test.stopTest();
        
        Map<String, Object> metadata = response.getMetadata();
        System.assertEquals(4, metadata.size(), 'Should have 4 metadata entries');
        System.assertEquals('req-12345', metadata.get('requestId'), 'Should store request ID');
        System.assertEquals(3, metadata.get('retryCount'), 'Should store retry count');
        System.assertEquals('/api/v1/users', metadata.get('endpoint'), 'Should store endpoint');
        System.assertNotEquals(null, metadata.get('timestamp'), 'Should store timestamp');
    }
    
    @IsTest
    static void testAddMetadata_OverwriteExisting() {
        String responseBody = '{"success": true}';
        Integer statusCode = 200;
        Map<String, String> headers = new Map<String, String>();
        String correlationId = 'test-correlation-id';
        Long processingTime = 1000L;
        
        Test.startTest();
        IntegrationResponse response = new IntegrationResponse(
            responseBody,
            statusCode,
            headers,
            correlationId,
            processingTime
        );
        
        // Add initial metadata
        response.addMetadata('key1', 'value1');
        response.addMetadata('key2', 'value2');
        
        // Overwrite existing metadata
        response.addMetadata('key1', 'updated-value1');
        response.addMetadata('key3', 'value3');
        Test.stopTest();
        
        Map<String, Object> metadata = response.getMetadata();
        System.assertEquals(3, metadata.size(), 'Should have 3 metadata entries');
        System.assertEquals('updated-value1', metadata.get('key1'), 'Should overwrite existing value');
        System.assertEquals('value2', metadata.get('key2'), 'Should keep original value');
        System.assertEquals('value3', metadata.get('key3'), 'Should add new value');
    }
    
    @IsTest
    static void testAddMetadata_NullValue() {
        String responseBody = '{"success": true}';
        Integer statusCode = 200;
        Map<String, String> headers = new Map<String, String>();
        String correlationId = 'test-correlation-id';
        Long processingTime = 1000L;
        
        Test.startTest();
        IntegrationResponse response = new IntegrationResponse(
            responseBody,
            statusCode,
            headers,
            correlationId,
            processingTime
        );
        
        // Add metadata with null value
        response.addMetadata('nullKey', null);
        response.addMetadata('validKey', 'validValue');
        Test.stopTest();
        
        Map<String, Object> metadata = response.getMetadata();
        System.assertEquals(2, metadata.size(), 'Should have 2 metadata entries');
        System.assertEquals(null, metadata.get('nullKey'), 'Should store null value');
        System.assertEquals('validValue', metadata.get('validKey'), 'Should store valid value');
    }
    
    @IsTest
    static void testAddMetadata_EmptyStringKey() {
        String responseBody = '{"success": true}';
        Integer statusCode = 200;
        Map<String, String> headers = new Map<String, String>();
        String correlationId = 'test-correlation-id';
        Long processingTime = 1000L;
        
        Test.startTest();
        IntegrationResponse response = new IntegrationResponse(
            responseBody,
            statusCode,
            headers,
            correlationId,
            processingTime
        );
        
        // Add metadata with empty string key
        response.addMetadata('', 'empty-key-value');
        response.addMetadata('normalKey', 'normal-value');
        Test.stopTest();
        
        Map<String, Object> metadata = response.getMetadata();
        System.assertEquals(2, metadata.size(), 'Should have 2 metadata entries');
        System.assertEquals('empty-key-value', metadata.get(''), 'Should store empty string key');
        System.assertEquals('normal-value', metadata.get('normalKey'), 'Should store normal key');
    }
    
    @IsTest
    static void testIsRetryableError_SuccessResponse() {
        String responseBody = '{"success": true}';
        Integer statusCode = 200;
        Map<String, String> headers = new Map<String, String>();
        String correlationId = 'test-correlation-id';
        Long processingTime = 1000L;
        
        Test.startTest();
        IntegrationResponse response = new IntegrationResponse(
            responseBody,
            statusCode,
            headers,
            correlationId,
            processingTime
        );
        Test.stopTest();
        
        System.assertEquals(false, response.isRetryableError(), 'Success response should not be retryable');
    }
    
    @IsTest
    static void testIsRetryableError_RetryableStatusCodes() {
        // Test all retryable status codes: 408, 429, 500, 502, 503, 504
        List<Integer> retryableCodes = new List<Integer>{408, 429, 500, 502, 503, 504};
        
        for (Integer statusCode : retryableCodes) {
            IntegrationResponse response = new IntegrationResponse(
                'Error message for ' + statusCode,
                statusCode,
                'test-correlation-id',
                1000L
            );
            
            System.assertEquals(true, response.isRetryableError(), 
                               'Status code ' + statusCode + ' should be retryable');
        }
    }
    
    @IsTest
    static void testIsRetryableError_NonRetryableStatusCodes() {
        // Test non-retryable status codes
        List<Integer> nonRetryableCodes = new List<Integer>{400, 401, 403, 404, 405, 422, 451};
        
        for (Integer statusCode : nonRetryableCodes) {
            IntegrationResponse response = new IntegrationResponse(
                'Error message for ' + statusCode,
                statusCode,
                'test-correlation-id',
                1000L
            );
            
            System.assertEquals(false, response.isRetryableError(), 
                               'Status code ' + statusCode + ' should not be retryable');
        }
    }
    
    @IsTest
    static void testIsRetryableError_NullStatusCode() {
        String errorMessage = 'Unknown error';
        String correlationId = 'test-correlation-id';
        Long processingTime = 1000L;
        
        Test.startTest();
        IntegrationResponse response = new IntegrationResponse(
            errorMessage,
            null, // null status code
            correlationId,
            processingTime
        );
        Test.stopTest();
        
        System.assertEquals(false, response.isRetryableError(), 'Null status code should not be retryable');
    }
    
    @IsTest
    static void testIsRetryableError_EdgeCaseStatusCodes() {
        // Test edge cases
        IntegrationResponse response1 = new IntegrationResponse('Error', 0, 'test-id', 1000L);
        System.assertEquals(false, response1.isRetryableError(), 'Status code 0 should not be retryable');
        
        IntegrationResponse response2 = new IntegrationResponse('Error', 999, 'test-id', 1000L);
        System.assertEquals(false, response2.isRetryableError(), 'Status code 999 should not be retryable');
        
        IntegrationResponse response3 = new IntegrationResponse('Error', 507, 'test-id', 1000L);
        System.assertEquals(false, response3.isRetryableError(), 'Status code 507 should not be retryable');
    }
    
    @IsTest
    static void testIsRetryableError_WithMetadata() {
        String errorMessage = 'Server error';
        Integer statusCode = 500;
        String correlationId = 'test-correlation-id';
        Long processingTime = 1000L;
        
        Test.startTest();
        IntegrationResponse response = new IntegrationResponse(
            errorMessage,
            statusCode,
            correlationId,
            processingTime
        );
        
        // Add metadata to error response
        response.addMetadata('retryAttempt', 1);
        response.addMetadata('maxRetries', 3);
        Test.stopTest();
        
        System.assertEquals(true, response.isRetryableError(), '500 error should be retryable');
        Map<String, Object> metadata = response.getMetadata();
        System.assertEquals(2, metadata.size(), 'Should have metadata');
        System.assertEquals(1, metadata.get('retryAttempt'), 'Should have retry attempt metadata');
        System.assertEquals(3, metadata.get('maxRetries'), 'Should have max retries metadata');
    }
}
