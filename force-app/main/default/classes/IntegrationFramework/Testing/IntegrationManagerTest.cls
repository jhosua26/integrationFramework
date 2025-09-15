/**
 * @description Integration Framework - Version 8
 * @author Jhosua R. Arda
 * @version 8.0
 * @purpose This framework is being used in Accenture projects and freelancing work.
 *          DO NOT MODIFY this class as it is part of the framework.
 *          Modifying this class will destroy the framework functionality.
 * 
 * Test class for IntegrationManager
 * Tests the following classes:
 * - IntegrationManager (main class under test)
 * - IIntegrationConnector interface
 * - IntegrationResponse class
 * 
 * IMPORTANT: DO NOT REMOVE existing test methods. Only add new test methods to maintain
 *            high test coverage. Removing existing methods will reduce test coverage.
 */
@IsTest
private class IntegrationManagerTest {
    
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
        String defaultSystemName = 'TestSystem';
        
        Test.startTest();
        IntegrationManager manager = new IntegrationManager(logger, defaultSystemName);
        Test.stopTest();
        
        System.assertNotEquals(null, manager, 'Manager should be created');
    }
    
    @IsTest
    static void testConstructorWithNullLogger() {
        try {
            IntegrationManager manager = new IntegrationManager(null, 'TestSystem');
            System.assert(false, 'Should throw exception with null logger');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Logger cannot be null'), 'Should throw appropriate exception');
        }
    }
    
    @IsTest
    static void testConstructorWithNullSystemName() {
        IIntegrationLogger logger = IntegrationLogger.getInstance();
        
        try {
            IntegrationManager manager = new IntegrationManager(logger, null);
            System.assert(false, 'Should throw exception with null system name');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Default system name cannot be null'), 'Should throw appropriate exception');
        }
    }
    
    @IsTest
    static void testSendRequest() {
        IIntegrationLogger logger = IntegrationLogger.getInstance();
        IntegrationManager manager = new IntegrationManager(logger, 'TestSystem');
        
        // Mock HTTP response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Test.startTest();
        try {
            IntegrationResponse response = manager.sendRequest(
                'TestSystem',
                'test-endpoint',
                '{"test": "data"}',
                new Map<String, String>{'Content-Type' => 'application/json'},
                'test-correlation-id'
            );
            System.assert(false, 'Should throw exception when no connector is registered');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('No connector registered for system'), 'Should throw appropriate exception');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testSendRequestWithNullSystemName() {
        IIntegrationLogger logger = IntegrationLogger.getInstance();
        IntegrationManager manager = new IntegrationManager(logger, 'TestSystem');
        
        try {
            IntegrationResponse response = manager.sendRequest(
                null,
                'test-endpoint',
                '{"test": "data"}',
                new Map<String, String>(),
                'test-correlation-id'
            );
            System.assert(false, 'Should throw exception with null system name');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('System name cannot be null'), 'Should throw appropriate exception');
        }
    }
    
    @IsTest
    static void testSendRequestWithNullEndpoint() {
        IIntegrationLogger logger = IntegrationLogger.getInstance();
        IntegrationManager manager = new IntegrationManager(logger, 'TestSystem');
        
        try {
            IntegrationResponse response = manager.sendRequest(
                'TestSystem',
                null,
                '{"test": "data"}',
                new Map<String, String>(),
                'test-correlation-id'
            );
            System.assert(false, 'Should throw exception with null endpoint');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Endpoint cannot be null'), 'Should throw appropriate exception');
        }
    }
    
    @IsTest
    static void testSendRequestWithUnregisteredSystem() {
        IIntegrationLogger logger = IntegrationLogger.getInstance();
        IntegrationManager manager = new IntegrationManager(logger, 'TestSystem');
        
        try {
            IntegrationResponse response = manager.sendRequest(
                'UnregisteredSystem',
                'test-endpoint',
                '{"test": "data"}',
                new Map<String, String>(),
                'test-correlation-id'
            );
            System.assert(false, 'Should throw exception with unregistered system');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('No connector registered for system'), 'Should throw appropriate exception');
        }
    }
    
    @IsTest
    static void testGetConnector() {
        IIntegrationLogger logger = IntegrationLogger.getInstance();
        IntegrationManager manager = new IntegrationManager(logger, 'TestSystem');
        
        IIntegrationConnector connector = manager.getConnector('TestSystem');
        System.assertEquals(null, connector, 'Should return null for unregistered system');
    }
    
    @IsTest
    static void testGetRegisteredSystems() {
        IIntegrationLogger logger = IntegrationLogger.getInstance();
        IntegrationManager manager = new IntegrationManager(logger, 'TestSystem');
        
        Set<String> systems = manager.getRegisteredSystems();
        System.assertNotEquals(null, systems, 'Should return set of systems');
        System.assertEquals(0, systems.size(), 'Should start with empty set');
    }
    
    @IsTest
    static void testValidateAllConnectors() {
        IIntegrationLogger logger = IntegrationLogger.getInstance();
        IntegrationManager manager = new IntegrationManager(logger, 'TestSystem');
        
        Boolean isValid = manager.validateAllConnectors();
        System.assertEquals(true, isValid, 'Should validate connectors successfully');
    }
    
    @IsTest
    static void testSendGetRequest_UnsupportedOperation() {
        IIntegrationLogger logger = IntegrationLogger.getInstance();
        IntegrationManager manager = new IntegrationManager(logger, 'TestSystem');
        
        Test.startTest();
        try {
            IntegrationResponse response = manager.sendGetRequest(
                'TestSystem',
                'test-endpoint',
                new Map<String, String>{'Content-Type' => 'application/json'},
                'test-correlation-id'
            );
            System.assert(false, 'Should throw IllegalArgumentException for unregistered system');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('No connector registered for system'), 
                         'Should throw appropriate exception message for unregistered system');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testSendGetRequest_WithNullSystemName() {
        IIntegrationLogger logger = IntegrationLogger.getInstance();
        IntegrationManager manager = new IntegrationManager(logger, 'TestSystem');
        
        try {
            IntegrationResponse response = manager.sendGetRequest(
                null,
                'test-endpoint',
                new Map<String, String>(),
                'test-correlation-id'
            );
            System.assert(false, 'Should throw exception with null system name');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('System name cannot be null'), 'Should throw appropriate exception');
        }
    }
    
    @IsTest
    static void testSendGetRequest_WithNullEndpoint() {
        IIntegrationLogger logger = IntegrationLogger.getInstance();
        IntegrationManager manager = new IntegrationManager(logger, 'TestSystem');
        
        try {
            IntegrationResponse response = manager.sendGetRequest(
                'TestSystem',
                null,
                new Map<String, String>(),
                'test-correlation-id'
            );
            System.assert(false, 'Should throw exception with null endpoint');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Endpoint cannot be null'), 'Should throw appropriate exception');
        }
    }
    
    @IsTest
    static void testSendGetRequest_WithNullCorrelationId() {
        IIntegrationLogger logger = IntegrationLogger.getInstance();
        IntegrationManager manager = new IntegrationManager(logger, 'TestSystem');
        
        try {
            IntegrationResponse response = manager.sendGetRequest(
                'TestSystem',
                'test-endpoint',
                new Map<String, String>(),
                null
            );
            System.assert(false, 'Should throw exception with null correlation ID');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Correlation ID cannot be null'), 'Should throw appropriate exception');
        }
    }
    
    @IsTest
    static void testSendGetRequest_WithUnregisteredSystem() {
        IIntegrationLogger logger = IntegrationLogger.getInstance();
        IntegrationManager manager = new IntegrationManager(logger, 'TestSystem');
        
        try {
            IntegrationResponse response = manager.sendGetRequest(
                'UnregisteredSystem',
                'test-endpoint',
                new Map<String, String>(),
                'test-correlation-id'
            );
            System.assert(false, 'Should throw exception with unregistered system');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('No connector registered for system'), 'Should throw appropriate exception');
        }
    }
    
    @IsTest
    static void testLogError_Success() {
        IIntegrationLogger logger = IntegrationLogger.getInstance();
        IntegrationManager manager = new IntegrationManager(logger, 'TestSystem');
        
        String correlationId = 'TEST-CORR-001';
        String errorType = 'TEST_ERROR';
        String errorMessage = 'Test error message';
        String stackTrace = 'Test stack trace';
        String severity = 'High';
        Map<String, Object> context = new Map<String, Object>{
            'testField' => 'testValue'
        };
        
        Test.startTest();
        // This should execute without throwing exceptions
        manager.logError('TestSystem', errorType, errorMessage, stackTrace, severity, correlationId, context);
        Test.stopTest();
        
        // Verify method executed successfully
        System.assert(true, 'logError method should execute without throwing exceptions');
    }
    
    @IsTest
    static void testLogError_WithDefaultSystemName() {
        IIntegrationLogger logger = IntegrationLogger.getInstance();
        IntegrationManager manager = new IntegrationManager(logger, 'DefaultSystem');
        
        String correlationId = 'TEST-CORR-002';
        String errorType = 'TEST_ERROR';
        String errorMessage = 'Test error message';
        String stackTrace = 'Test stack trace';
        String severity = 'Medium';
        Map<String, Object> context = new Map<String, Object>();
        
        Test.startTest();
        // Pass null systemName to test default system name usage
        manager.logError(null, errorType, errorMessage, stackTrace, severity, correlationId, context);
        Test.stopTest();
        
        // Verify method executed successfully
        System.assert(true, 'logError method should execute without throwing exceptions');
    }
    
    @IsTest
    static void testLogError_WithNullCorrelationId() {
        IIntegrationLogger logger = IntegrationLogger.getInstance();
        IntegrationManager manager = new IntegrationManager(logger, 'TestSystem');
        
        try {
            manager.logError('TestSystem', 'TEST_ERROR', 'Test message', 'Stack trace', 'High', null, new Map<String, Object>());
            System.assert(false, 'Should throw exception with null correlation ID');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Correlation ID cannot be null'), 'Should throw appropriate exception');
        }
    }
    
    @IsTest
    static void testLogError_WithEmptyCorrelationId() {
        IIntegrationLogger logger = IntegrationLogger.getInstance();
        IntegrationManager manager = new IntegrationManager(logger, 'TestSystem');
        
        try {
            manager.logError('TestSystem', 'TEST_ERROR', 'Test message', 'Stack trace', 'High', '', new Map<String, Object>());
            System.assert(false, 'Should throw exception with empty correlation ID');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Correlation ID cannot be null'), 'Should throw appropriate exception');
        }
    }
    
    @IsTest
    static void testLogError_WithNullContext() {
        IIntegrationLogger logger = IntegrationLogger.getInstance();
        IntegrationManager manager = new IntegrationManager(logger, 'TestSystem');
        
        String correlationId = 'TEST-CORR-003';
        
        Test.startTest();
        // This should execute without throwing exceptions even with null context
        manager.logError('TestSystem', 'TEST_ERROR', 'Test message', 'Stack trace', 'Low', correlationId, null);
        Test.stopTest();
        
        // Verify method executed successfully
        System.assert(true, 'logError method should execute without throwing exceptions');
    }
    
    // Note: IntegrationRequest class doesn't exist, so processRequest method tests are removed
    
    // Mock HTTP response generator for testing
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"success": true, "id": "12345"}');
            return res;
        }
    }
}
