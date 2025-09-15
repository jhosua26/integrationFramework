/**
 * @description Integration Framework - Version 8
 * @author Jhosua R. Arda
 * @version 8.0
 * @purpose This framework is being used in Accenture projects and freelancing work.
 *          DO NOT MODIFY this class as it is part of the framework.
 *          Modifying this class will destroy the framework functionality.
 * 
 * Test class for FrameworkErrorHandler with framework-specific error handling capabilities
 * 
 * IMPORTANT: DO NOT REMOVE existing test methods. Only add new test methods to maintain
 *            high test coverage. Removing existing methods will reduce test coverage.
 */
@IsTest
private class FrameworkErrorHandlerTest {
    
    @IsTest
    static void testFrameworkErrorHandlerConstructor() {
        // Arrange
        IntegrationLogger logger = new IntegrationLogger();
        
        // Act
        Test.startTest();
        FrameworkErrorHandler errorHandler = new FrameworkErrorHandler(logger);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, errorHandler, 'Framework error handler should be created');
    }
    
    @IsTest
    static void testFrameworkErrorHandlerNullLogger() {
        // Act & Assert
        Test.startTest();
        try {
            new FrameworkErrorHandler(null);
            System.assert(false, 'Should have thrown an exception');
        } catch (IllegalArgumentException e) {
            System.assertEquals('Logger cannot be null', e.getMessage(), 'Should throw correct error message');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testLogFrameworkErrorIntegrationClassification() {
        // Arrange
        IntegrationLogger logger = new IntegrationLogger();
        FrameworkErrorHandler errorHandler = new FrameworkErrorHandler(logger);
        
        String correlationId = 'TEST-FRAMEWORK-001';
        String errorType = 'BASIC_ERROR';
        String errorMessage = 'Integration connection failed during HTTP request to external API';
        String stackTrace = 'Test stack trace';
        String severity = 'Medium';
        Map<String, Object> context = new Map<String, Object>{
            'systemName' => 'TestSystem',
            'endpoint' => 'https://api.test.com/endpoint'
        };
        
        // Act
        Test.startTest();
        errorHandler.logFrameworkError(correlationId, errorType, errorMessage, stackTrace, severity, context);
        Test.stopTest();
        
        // Assert
        List<Integration_Error__c> errors = [
            SELECT Id, Error_Type__c, Error_Message__c, Error_Severity__c, 
                   Business_Impact__c, Resolution_Notes__c, Status__c
            FROM Integration_Error__c 
            WHERE Correlation_ID__c = :correlationId
        ];
        
        System.assertEquals(1, errors.size(), 'Should create one error record');
        System.assertEquals('PLATFORM', errors[0].Error_Type__c, 'Should classify as PLATFORM error');
        System.assertEquals('MEDIUM', errors[0].Error_Severity__c, 'Should maintain MEDIUM severity');
        System.assertNotEquals(null, errors[0].Business_Impact__c, 'Should have business impact');
        System.assertNotEquals(null, errors[0].Resolution_Notes__c, 'Should have resolution notes');
        System.assertEquals('Open', errors[0].Status__c, 'Should set status to Open for integration errors');
    }
    
    @IsTest
    static void testLogFrameworkErrorRetryClassification() {
        // Arrange
        IntegrationLogger logger = new IntegrationLogger();
        FrameworkErrorHandler errorHandler = new FrameworkErrorHandler(logger);
        
        String correlationId = 'TEST-FRAMEWORK-002';
        String errorType = 'BASIC_ERROR';
        String errorMessage = 'Retry attempt failed with exponential backoff';
        String stackTrace = 'Test stack trace';
        String severity = 'Medium';
        Map<String, Object> context = new Map<String, Object>{
            'systemName' => 'TestSystem',
            'retryCount' => 3
        };
        
        // Act
        Test.startTest();
        errorHandler.logFrameworkError(correlationId, errorType, errorMessage, stackTrace, severity, context);
        Test.stopTest();
        
        // Assert
        List<Integration_Error__c> errors = [
            SELECT Id, Error_Type__c, Error_Message__c, Error_Severity__c, 
                   Business_Impact__c, Resolution_Notes__c, Status__c
            FROM Integration_Error__c 
            WHERE Correlation_ID__c = :correlationId
        ];
        
        System.assertEquals(1, errors.size(), 'Should create one error record');
        System.assertEquals('PLATFORM', errors[0].Error_Type__c, 'Should classify as PLATFORM error');
        System.assertEquals('MEDIUM', errors[0].Error_Severity__c, 'Should maintain MEDIUM severity');
        System.assertNotEquals(null, errors[0].Business_Impact__c, 'Should have business impact');
        System.assertNotEquals(null, errors[0].Resolution_Notes__c, 'Should have resolution notes');
        System.assertEquals('Open', errors[0].Status__c, 'Should set status to Open for platform errors');
    }
    

    
    @IsTest
    static void testLogFrameworkErrorTimeoutClassification() {
        // Arrange
        IntegrationLogger logger = new IntegrationLogger();
        FrameworkErrorHandler errorHandler = new FrameworkErrorHandler(logger);
        
        String correlationId = 'TEST-FRAMEWORK-004';
        String errorType = 'BASIC_ERROR';
        String errorMessage = 'Request timeout after 30 seconds';
        String stackTrace = 'Test stack trace';
        String severity = 'Medium';
        Map<String, Object> context = new Map<String, Object>{
            'systemName' => 'TestSystem',
            'timeoutMs' => 30000
        };
        
        // Act
        Test.startTest();
        errorHandler.logFrameworkError(correlationId, errorType, errorMessage, stackTrace, severity, context);
        Test.stopTest();
        
        // Assert
        List<Integration_Error__c> errors = [
            SELECT Id, Error_Type__c, Error_Message__c, Error_Severity__c, 
                   Business_Impact__c, Resolution_Notes__c, Status__c
            FROM Integration_Error__c 
            WHERE Correlation_ID__c = :correlationId
        ];
        
        System.assertEquals(1, errors.size(), 'Should create one error record');
        System.assertEquals('TIMEOUT', errors[0].Error_Type__c, 'Should classify as TIMEOUT error');
        System.assertEquals('HIGH', errors[0].Error_Severity__c, 'Should assess as HIGH severity for timeout');
        System.assertNotEquals(null, errors[0].Business_Impact__c, 'Should have business impact');
        System.assertNotEquals(null, errors[0].Resolution_Notes__c, 'Should have resolution notes');
        System.assertEquals('Retrying', errors[0].Status__c, 'Should set status to Retrying for timeout errors');
    }
    

    
    @IsTest
    static void testLogFrameworkErrorWithRetryContext() {
        // Arrange
        IntegrationLogger logger = new IntegrationLogger();
        FrameworkErrorHandler errorHandler = new FrameworkErrorHandler(logger);
        
        String correlationId = 'TEST-FRAMEWORK-006';
        String errorType = 'BASIC_ERROR';
        String errorMessage = 'Integration connection failed';
        String stackTrace = 'Test stack trace';
        String severity = 'Medium';
        Map<String, Object> context = new Map<String, Object>{
            'systemName' => 'TestSystem',
            'retryCount' => 5,
            'endpoint' => 'https://api.test.com/endpoint'
        };
        
        // Act
        Test.startTest();
        errorHandler.logFrameworkError(correlationId, errorType, errorMessage, stackTrace, severity, context);
        Test.stopTest();
        
        // Assert
        List<Integration_Error__c> errors = [
            SELECT Id, Resolution_Notes__c
            FROM Integration_Error__c 
            WHERE Correlation_ID__c = :correlationId
        ];
        
        System.assertEquals(1, errors.size(), 'Should create one error record');
        System.assert(errors[0].Resolution_Notes__c.contains('Retry attempts: 5'), 
                     'Should include retry count in resolution notes');
        System.assert(errors[0].Resolution_Notes__c.contains('https://api.test.com/endpoint'), 
                     'Should include endpoint in resolution notes');
    }
    
    @IsTest
    static void testLogFrameworkErrorValidation() {
        // Arrange
        IntegrationLogger logger = new IntegrationLogger();
        FrameworkErrorHandler errorHandler = new FrameworkErrorHandler(logger);
        
        // Act & Assert
        Test.startTest();
        
        // Test null correlation ID
        try {
            errorHandler.logFrameworkError(null, 'TEST', 'Test error', 'Stack trace', 'Medium', null);
            System.assert(false, 'Should have thrown an exception');
        } catch (IllegalArgumentException e) {
            System.assertEquals('Correlation ID cannot be null or empty', e.getMessage(), 'Should throw correct error message');
        }
        
        // Test null error message
        try {
            errorHandler.logFrameworkError('TEST-ID', 'TEST', null, 'Stack trace', 'Medium', null);
            System.assert(false, 'Should have thrown an exception');
        } catch (IllegalArgumentException e) {
            System.assertEquals('Error message cannot be null or empty', e.getMessage(), 'Should throw correct error message');
        }
        
        Test.stopTest();
    }
    
    @IsTest
    static void testGetFrameworkErrorAnalytics() {
        // Arrange
        IntegrationLogger logger = new IntegrationLogger();
        FrameworkErrorHandler errorHandler = new FrameworkErrorHandler(logger);
        
        String correlationId = 'TEST-FRAMEWORK-ANALYTICS-001';
        
        // Create test error records
        List<Integration_Error__c> testErrors = new List<Integration_Error__c>{
            new Integration_Error__c(
                Correlation_ID__c = correlationId,
                Error_Type__c = 'PLATFORM',
                Error_Severity__c = 'HIGH',
                Status__c = 'Open',
                Timestamp__c = Datetime.now(),
                Retry_Count__c = 2
            ),
            new Integration_Error__c(
                Correlation_ID__c = correlationId,
                Error_Type__c = 'PLATFORM',
                Error_Severity__c = 'MEDIUM',
                Status__c = 'Open',
                Timestamp__c = Datetime.now(),
                Retry_Count__c = 1
            ),
            new Integration_Error__c(
                Correlation_ID__c = correlationId,
                Error_Type__c = 'TIMEOUT',
                Error_Severity__c = 'HIGH',
                Status__c = 'Retrying',
                Timestamp__c = Datetime.now(),
                Retry_Count__c = 0
            )
        };
        
        insert testErrors;
        
        // Act
        Test.startTest();
        Map<String, Object> analytics = errorHandler.getFrameworkErrorAnalytics(correlationId);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, analytics, 'Should return analytics data');
        System.assertEquals(3, analytics.get('totalErrors'), 'Should have 3 total errors');
        System.assertEquals('IntegrationFramework', analytics.get('framework'), 'Should identify framework');
        
        Map<String, Integer> errorTypes = (Map<String, Integer>) analytics.get('errorTypes');
        System.assertEquals(2, errorTypes.get('PLATFORM'), 'Should have 2 PLATFORM errors');
        System.assertEquals(1, errorTypes.get('TIMEOUT'), 'Should have 1 TIMEOUT error');
        
        Map<String, Integer> severityDistribution = (Map<String, Integer>) analytics.get('severityDistribution');
        System.assertEquals(2, severityDistribution.get('HIGH'), 'Should have 2 HIGH severity errors');
        System.assertEquals(1, severityDistribution.get('MEDIUM'), 'Should have 1 MEDIUM severity error');
        
        Map<String, Object> retryStats = (Map<String, Object>) analytics.get('retryStats');
        System.assertEquals(3, retryStats.get('totalRetries'), 'Should have 3 total retries');
        System.assertEquals(1.0, retryStats.get('averageRetries'), 'Should have 1.0 average retries');
    }
    
    @IsTest
    static void testGetFrameworkErrorAnalyticsEmptyCorrelationId() {
        // Arrange
        IntegrationLogger logger = new IntegrationLogger();
        FrameworkErrorHandler errorHandler = new FrameworkErrorHandler(logger);
        
        // Act
        Test.startTest();
        Map<String, Object> analytics = errorHandler.getFrameworkErrorAnalytics('');
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, analytics, 'Should return empty analytics data');
        System.assertEquals(0, analytics.size(), 'Should return empty map for empty correlation ID');
    }
    
    @IsTest
    static void testGetFrameworkErrorAnalyticsNoErrors() {
        // Arrange
        IntegrationLogger logger = new IntegrationLogger();
        FrameworkErrorHandler errorHandler = new FrameworkErrorHandler(logger);
        
        String correlationId = 'TEST-FRAMEWORK-ANALYTICS-EMPTY';
        
        // Act
        Test.startTest();
        Map<String, Object> analytics = errorHandler.getFrameworkErrorAnalytics(correlationId);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, analytics, 'Should return analytics data');
        System.assertEquals(0, analytics.get('totalErrors'), 'Should have 0 total errors');
        System.assertEquals('IntegrationFramework', analytics.get('framework'), 'Should identify framework');
        
        Map<String, Object> retryStats = (Map<String, Object>) analytics.get('retryStats');
        System.assertEquals(0, retryStats.get('totalRetries'), 'Should have 0 total retries');
        System.assertEquals(0.0, retryStats.get('averageRetries'), 'Should have 0.0 average retries');
    }
    
    @IsTest
    static void testFrameworkErrorCorrelation() {
        // Arrange
        IntegrationLogger logger = new IntegrationLogger();
        FrameworkErrorHandler errorHandler = new FrameworkErrorHandler(logger);
        
        String correlationId1 = 'TEST-FRAMEWORK-CORRELATION-001';
        String correlationId2 = 'TEST-FRAMEWORK-CORRELATION-002';
        
        // Create first error
        errorHandler.logFrameworkError(
            correlationId1, 
            'BASIC_ERROR', 
            'Integration callout failed', 
            'Stack trace', 
            'Medium', 
            new Map<String, Object>{'systemName' => 'TestSystem'}
        );
        
        // Act - Create second similar error
        Test.startTest();
        errorHandler.logFrameworkError(
            correlationId2, 
            'BASIC_ERROR', 
            'Integration callout failed', 
            'Stack trace', 
            'Medium', 
            new Map<String, Object>{'systemName' => 'TestSystem'}
        );
        Test.stopTest();
        
        // Assert - Check if correlation data was added
        List<Integration_Error__c> errors = [
            SELECT Id, Context__c 
            FROM Integration_Error__c 
            WHERE Correlation_ID__c = :correlationId2
        ];
        
        System.assertEquals(1, errors.size(), 'Should have one error record');
        
        if (errors[0].Context__c != null) {
            Map<String, Object> context = (Map<String, Object>) JSON.deserializeUntyped(errors[0].Context__c);
            System.assert(context.containsKey('correlatedErrors'), 'Should have correlation data');
            System.assert(context.containsKey('frameworkErrorType'), 'Should have framework error type');
        }
    }
    
    @IsTest
    static void testDetermineHttpStatusCode_DirectMapping() {
        // Test direct error type mapping
        FrameworkErrorHandler errorHandler = new FrameworkErrorHandler();
        
        Test.startTest();
        Integer statusCode = errorHandler.determineHttpStatusCode('VALIDATION', 'Test validation error');
        Test.stopTest();
        
        System.assertEquals(400, statusCode, 'VALIDATION should map to 400');
    }
    
    @IsTest
    static void testDetermineHttpStatusCode_MessageBasedMapping() {
        // Test message-based HTTP status code mapping
        FrameworkErrorHandler errorHandler = new FrameworkErrorHandler();
        
        Test.startTest();
        // Test authentication errors
        Integer authCode = errorHandler.determineHttpStatusCode('UNMAPPED_ERROR', 'User is unauthorized to access this resource');
        System.assertEquals(401, authCode, 'Unauthorized message should map to 401');
        
        // Test forbidden errors
        Integer forbiddenCode = errorHandler.determineHttpStatusCode('UNMAPPED_ERROR', 'Access denied to this endpoint');
        System.assertEquals(403, forbiddenCode, 'Access denied message should map to 403');
        
        // Test validation errors
        Integer validationCode = errorHandler.determineHttpStatusCode('UNMAPPED_ERROR', 'Required field is missing');
        System.assertEquals(400, validationCode, 'Missing field message should map to 400');
        
        // Test not found errors
        Integer notFoundCode = errorHandler.determineHttpStatusCode('UNMAPPED_ERROR', 'Record does not exist');
        System.assertEquals(404, notFoundCode, 'Does not exist message should map to 404');
        
        // Test conflict errors
        Integer conflictCode = errorHandler.determineHttpStatusCode('UNMAPPED_ERROR', 'Record already exists');
        System.assertEquals(409, conflictCode, 'Already exists message should map to 409');
        
        // Test business logic errors
        Integer businessCode = errorHandler.determineHttpStatusCode('UNMAPPED_ERROR', 'Business rule violation');
        System.assertEquals(422, businessCode, 'Business rule message should map to 422');
        
        // Test timeout errors
        Integer timeoutCode = errorHandler.determineHttpStatusCode('UNMAPPED_ERROR', 'Request timed out');
        System.assertEquals(504, timeoutCode, 'Timed out message should map to 504');
        
        // Test service unavailable errors
        Integer serviceCode = errorHandler.determineHttpStatusCode('UNMAPPED_ERROR', 'Service is unavailable for maintenance');
        System.assertEquals(503, serviceCode, 'Service unavailable message should map to 503');
        Test.stopTest();
    }
    
    @IsTest
    static void testDetermineHttpStatusCode_DefaultFallback() {
        // Test default fallback behavior
        FrameworkErrorHandler errorHandler = new FrameworkErrorHandler();
        
        Test.startTest();
        // Test with null error type
        Integer nullCode = errorHandler.determineHttpStatusCode(null, 'Some error message');
        System.assertEquals(500, nullCode, 'Null error type should default to 500');
        
        // Test with blank error type
        Integer blankCode = errorHandler.determineHttpStatusCode('', 'Some error message');
        System.assertEquals(500, blankCode, 'Blank error type should default to 500');
        
        // Test with unknown error type and message
        Integer unknownCode = errorHandler.determineHttpStatusCode('UNKNOWN_TYPE', 'Some random error message');
        System.assertEquals(500, unknownCode, 'Unknown error type should default to 500');
        Test.stopTest();
    }
    
    @IsTest
    static void testCreateStandardErrorResponse_BasicResponse() {
        // Test basic error response creation
        FrameworkErrorHandler errorHandler = new FrameworkErrorHandler();
        
        String errorType = 'VALIDATION';
        String errorMessage = 'Required field is missing';
        String correlationId = 'TEST-CORR-001';
        Map<String, Object> additionalContext = new Map<String, Object>{
            'fieldName' => 'email',
            'systemName' => 'TestSystem'
        };
        
        Test.startTest();
        Map<String, Object> response = errorHandler.createStandardErrorResponse(errorType, errorMessage, correlationId, additionalContext);
        Test.stopTest();
        
        // Verify response structure
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertEquals(true, response.get('error'), 'Should have error flag set to true');
        System.assertEquals(errorType, response.get('type'), 'Should have correct error type');
        System.assertEquals(errorMessage, response.get('message'), 'Should have correct error message');
        System.assertEquals(400, response.get('statusCode'), 'Should have correct HTTP status code');
        System.assertEquals('HIGH', response.get('severity'), 'Should have correct severity');
        System.assertEquals(correlationId, response.get('correlationId'), 'Should have correct correlation ID');
        System.assertNotEquals(null, response.get('timestamp'), 'Should have timestamp');
        
        // Verify additional context
        Map<String, Object> context = (Map<String, Object>) response.get('context');
        System.assertNotEquals(null, context, 'Should have context');
        System.assertEquals('email', context.get('fieldName'), 'Should have field name in context');
        System.assertEquals('TestSystem', context.get('systemName'), 'Should have system name in context');
    }
    
    @IsTest
    static void testCreateStandardErrorResponse_WithoutContext() {
        // Test error response creation without additional context
        FrameworkErrorHandler errorHandler = new FrameworkErrorHandler();
        
        String errorType = 'PLATFORM';
        String errorMessage = 'System callout failed';
        String correlationId = 'TEST-CORR-002';
        
        Test.startTest();
        Map<String, Object> response = errorHandler.createStandardErrorResponse(errorType, errorMessage, correlationId, null);
        Test.stopTest();
        
        // Verify response structure
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertEquals(true, response.get('error'), 'Should have error flag set to true');
        System.assertEquals(errorType, response.get('type'), 'Should have correct error type');
        System.assertEquals(errorMessage, response.get('message'), 'Should have correct error message');
        System.assertEquals(500, response.get('statusCode'), 'Should have correct HTTP status code');
        System.assertEquals('HIGH', response.get('severity'), 'Should have correct severity');
        System.assertEquals(correlationId, response.get('correlationId'), 'Should have correct correlation ID');
        System.assertNotEquals(null, response.get('timestamp'), 'Should have timestamp');
        
        // Verify no context when null
        System.assertEquals(null, response.get('context'), 'Should not have context when null');
    }
    
    @IsTest
    static void testCreateStandardErrorResponse_EmptyContext() {
        // Test error response creation with empty context
        FrameworkErrorHandler errorHandler = new FrameworkErrorHandler();
        
        String errorType = 'TIMEOUT';
        String errorMessage = 'Request timeout occurred';
        String correlationId = 'TEST-CORR-003';
        Map<String, Object> emptyContext = new Map<String, Object>();
        
        Test.startTest();
        Map<String, Object> response = errorHandler.createStandardErrorResponse(errorType, errorMessage, correlationId, emptyContext);
        Test.stopTest();
        
        // Verify response structure
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertEquals(true, response.get('error'), 'Should have error flag set to true');
        System.assertEquals(errorType, response.get('type'), 'Should have correct error type');
        System.assertEquals(errorMessage, response.get('message'), 'Should have correct error message');
        System.assertEquals(504, response.get('statusCode'), 'Should have correct HTTP status code');
        System.assertEquals('HIGH', response.get('severity'), 'Should have correct severity');
        System.assertEquals(correlationId, response.get('correlationId'), 'Should have correct correlation ID');
        System.assertNotEquals(null, response.get('timestamp'), 'Should have timestamp');
        
        // Verify no context when empty
        System.assertEquals(null, response.get('context'), 'Should not have context when empty');
    }
}
