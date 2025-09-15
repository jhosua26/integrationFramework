/**
 * @description Integration Framework - Version 8
 * @author Jhosua R. Arda
 * @version 8.0
 * @purpose This framework is being used in Accenture projects and freelancing work.
 *          DO NOT MODIFY this class as it is part of the framework.
 *          Modifying this class will destroy the framework functionality.
 * 
 * Test class for RetryManager with exponential backoff
 * 
 * IMPORTANT: DO NOT REMOVE existing test methods. Only add new test methods to maintain
 *            high test coverage. Removing existing methods will reduce test coverage.
 */
@IsTest
private class RetryManagerTest {
    
    @TestSetup
    static void setup() {
        // Reset singleton to ensure clean state
        FrameworkConfigManager.resetInstance();
        
        // Delete any existing configurations to ensure clean state
        delete [SELECT Id FROM Integration_Framework_Config__c];
        
        // Create test configuration with Queueable retry disabled for synchronous testing
        Integration_Framework_Config__c testConfig = new Integration_Framework_Config__c(
            Enable_Queueable_Retry__c = false,
            Environment_Type__c = 'Development'
        );
        insert testConfig;
    }
    
    @IsTest
    static void testRetryManagerSuccessOnFirstAttempt() {
        // Arrange
        IntegrationLogger logger = new IntegrationLogger();
        RetryManager retryManager = new RetryManager(logger, 3, 100);
        
        String correlationId = 'TEST-RETRY-001';
        String systemName = 'TestSystem';
        Map<String, Object> context = new Map<String, Object>{
            'test' => 'data'
        };
        
        // Create a successful operation
        RetryableOperation successfulOperation = new SuccessfulTestOperation();
        
        // Act
        Test.startTest();
        RetryResult result = retryManager.executeWithRetry(successfulOperation, correlationId, systemName, context);
        Test.stopTest();
        
        // Assert
        System.assertEquals(true, result.getIsSuccess(), 'Operation should be successful');
        System.assertEquals(0, result.getRetryCount(), 'Should not have retried');
        System.assertEquals('Success', result.getResult(), 'Result should be "Success"');
        System.assert(result.getTotalProcessingTime() >= 0, 'Should have processing time');
        System.assertEquals(null, result.getLastException(), 'Should not have exception');
    }
    
    @IsTest
    static void testRetryManagerSuccessAfterRetries() {
        // Arrange
        IntegrationLogger logger = new IntegrationLogger();
        RetryManager retryManager = new RetryManager(logger, 3, 100);
        
        String correlationId = 'TEST-RETRY-002';
        String systemName = 'TestSystem';
        Map<String, Object> context = new Map<String, Object>{
            'test' => 'data'
        };
        
        // Create an operation that fails twice then succeeds
        RetryableOperation retryableOperation = new RetryableTestOperation(2);
        
        // Act
        Test.startTest();
        RetryResult result = retryManager.executeWithRetry(retryableOperation, correlationId, systemName, context);
        Test.stopTest();
        
        // Assert
        System.assertEquals(true, result.getIsSuccess(), 'Operation should be successful');
        System.assertEquals(2, result.getRetryCount(), 'Should have retried 2 times');
        System.assertEquals('Success', result.getResult(), 'Result should be "Success"');
        System.assert(result.getTotalProcessingTime() >= 0, 'Should have processing time');
        System.assertEquals(null, result.getLastException(), 'Should not have exception');
    }
    
    @IsTest
    static void testRetryManagerExhausted() {
        // Arrange
        IntegrationLogger logger = new IntegrationLogger();
        RetryManager retryManager = new RetryManager(logger, 2, 100);
        
        String correlationId = 'TEST-RETRY-003';
        String systemName = 'TestSystem';
        Map<String, Object> context = new Map<String, Object>{
            'test' => 'data'
        };
        
        // Create an operation that always fails
        RetryableOperation failingOperation = new FailingTestOperation();
        
        // Act
        Test.startTest();
        RetryResult result = retryManager.executeWithRetry(failingOperation, correlationId, systemName, context);
        Test.stopTest();
        
        // Assert
        System.assertEquals(false, result.getIsSuccess(), 'Operation should fail');
        System.assertEquals(2, result.getRetryCount(), 'Should have retried 2 times');
        System.assertEquals(null, result.getResult(), 'Should not have result');
        System.assert(result.getTotalProcessingTime() >= 0, 'Should have processing time');
        System.assertNotEquals(null, result.getLastException(), 'Should have exception');
        System.assertEquals('Test failure', result.getErrorMessage(), 'Should have correct error message');
    }
    
    @IsTest
    static void testRetryManagerNonRetryableError() {
        // Arrange
        IntegrationLogger logger = new IntegrationLogger();
        RetryManager retryManager = new RetryManager(logger, 3, 100);
        
        String correlationId = 'TEST-RETRY-004';
        String systemName = 'TestSystem';
        Map<String, Object> context = new Map<String, Object>{
            'test' => 'data'
        };
        
        // Create an operation that throws a non-retryable error
        RetryableOperation nonRetryableOperation = new NonRetryableTestOperation();
        
        // Act
        Test.startTest();
        RetryResult result = retryManager.executeWithRetry(nonRetryableOperation, correlationId, systemName, context);
        Test.stopTest();
        
        // Assert
        System.assertEquals(false, result.getIsSuccess(), 'Operation should fail');
        System.assertEquals(0, result.getRetryCount(), 'Should not have retried');
        System.assertEquals(null, result.getResult(), 'Should not have result');
        System.assertNotEquals(null, result.getLastException(), 'Should have exception');
    }
    
    @IsTest
    static void testRetryCountUpdate() {
        // Arrange
        IntegrationLogger logger = new IntegrationLogger();
        RetryManager retryManager = new RetryManager(logger, 2, 100);
        
        String correlationId = 'TEST-RETRY-005';
        
        // Create an error record first
        Integration_Error__c errorRecord = new Integration_Error__c(
            Correlation_ID__c = correlationId,
            Error_Type__c = 'NETWORK',
            Error_Message__c = 'Test error',
            Error_Severity__c = 'MEDIUM',
            Status__c = 'Open',
            Retry_Count__c = 0
        );
        
        insert errorRecord;
        
        // Act
        Test.startTest();
        retryManager.updateRetryCount(correlationId, 3);
        Test.stopTest();
        
        // Assert
        List<Integration_Error__c> updatedErrors = [
            SELECT Retry_Count__c 
            FROM Integration_Error__c 
            WHERE Correlation_ID__c = :correlationId
        ];
        
        System.assertEquals(1, updatedErrors.size(), 'Should find one error record');
        System.assertEquals(3, updatedErrors[0].Retry_Count__c, 'Retry count should be updated to 3');
    }
    
    @IsTest
    static void testGetRetryCount() {
        // Arrange
        IntegrationLogger logger = new IntegrationLogger();
        RetryManager retryManager = new RetryManager(logger, 2, 100);
        
        String correlationId = 'TEST-RETRY-006';
        
        // Create an error record with retry count
        Integration_Error__c errorRecord = new Integration_Error__c(
            Correlation_ID__c = correlationId,
            Error_Type__c = 'NETWORK',
            Error_Message__c = 'Test error',
            Error_Severity__c = 'MEDIUM',
            Status__c = 'Open',
            Retry_Count__c = 5
        );
        
        insert errorRecord;
        
        // Act
        Test.startTest();
        Integer retryCount = retryManager.getRetryCount(correlationId);
        Test.stopTest();
        
        // Assert
        System.assertEquals(5, retryCount, 'Should return correct retry count');
    }
    
    @IsTest
    static void testGetRetryCountNotFound() {
        // Arrange
        IntegrationLogger logger = new IntegrationLogger();
        RetryManager retryManager = new RetryManager(logger, 2, 100);
        
        // Act
        Test.startTest();
        Integer retryCount = retryManager.getRetryCount('NONEXISTENT-ID');
        Test.stopTest();
        
        // Assert
        System.assertEquals(0, retryCount, 'Should return 0 for non-existent correlation ID');
    }
    
    @IsTest
    static void testRetryManagerValidation() {
        // Arrange
        IntegrationLogger logger = new IntegrationLogger();
        
        // Act & Assert
        Test.startTest();
        
        // Test null logger
        try {
            new RetryManager(null, 3, 100);
            System.assert(false, 'Should have thrown an exception');
        } catch (IllegalArgumentException e) {
            System.assertEquals('Logger cannot be null', e.getMessage(), 'Should throw correct error message');
        }
        
        // Test null operation
        RetryManager retryManager = new RetryManager(logger, 3, 100);
        try {
            retryManager.executeWithRetry(null, 'TEST-ID', 'TestSystem', null);
            System.assert(false, 'Should have thrown an exception');
        } catch (IllegalArgumentException e) {
            System.assertEquals('Operation cannot be null', e.getMessage(), 'Should throw correct error message');
        }
        
        // Test null correlation ID
        try {
            retryManager.executeWithRetry(new SuccessfulTestOperation(), null, 'TestSystem', null);
            System.assert(false, 'Should have thrown an exception');
        } catch (IllegalArgumentException e) {
            System.assertEquals('Correlation ID cannot be null or empty', e.getMessage(), 'Should throw correct error message');
        }
        
        // Test null system name
        try {
            retryManager.executeWithRetry(new SuccessfulTestOperation(), 'TEST-ID', null, null);
            System.assert(false, 'Should have thrown an exception');
        } catch (IllegalArgumentException e) {
            System.assertEquals('System name cannot be null or empty', e.getMessage(), 'Should throw correct error message');
        }
        
        Test.stopTest();
    }
    
    @IsTest
    static void testRetryManagerConfiguration() {
        // Arrange
        IntegrationLogger logger = new IntegrationLogger();
        RetryManager retryManager = new RetryManager(logger, 5, 2000);
        
        // Act
        Test.startTest();
        Integer maxRetries = retryManager.getMaxRetries();
        Integer baseDelay = retryManager.getBaseDelayMs();
        Test.stopTest();
        
        // Assert
        System.assertEquals(5, maxRetries, 'Should return correct max retries');
        System.assertEquals(2000, baseDelay, 'Should return correct base delay');
    }
    
    @IsTest
    static void testGetInstance() {
        // Test singleton pattern
        Test.startTest();
        RetryManager instance1 = RetryManager.getInstance();
        RetryManager instance2 = RetryManager.getInstance();
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, instance1, 'Instance should not be null');
        System.assertEquals(instance1, instance2, 'Should return same instance (singleton)');
        System.assertEquals(3, instance1.getMaxRetries(), 'Should have default max retries');
        System.assertEquals(1000, instance1.getBaseDelayMs(), 'Should have default base delay');
    }
    
    @IsTest
    static void testConstructorWithNullLogger() {
        // Test constructor validation
        Test.startTest();
        try {
            RetryManager retryManager = new RetryManager(null, 3, 1000);
            System.assert(false, 'Should throw IllegalArgumentException for null logger');
        } catch (IllegalArgumentException e) {
            System.assertEquals('Logger cannot be null', e.getMessage(), 'Should throw correct error message');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testConstructorWithNullMaxRetries() {
        // Test constructor with null maxRetries (should use default)
        IntegrationLogger logger = new IntegrationLogger();
        
        Test.startTest();
        RetryManager retryManager = new RetryManager(logger, null, 1000);
        Test.stopTest();
        
        // Assert
        System.assertEquals(3, retryManager.getMaxRetries(), 'Should use default max retries when null');
        System.assertEquals(1000, retryManager.getBaseDelayMs(), 'Should use provided base delay');
    }
    
    @IsTest
    static void testConstructorWithNullBaseDelay() {
        // Test constructor with null baseDelayMs (should use default)
        IntegrationLogger logger = new IntegrationLogger();
        
        Test.startTest();
        RetryManager retryManager = new RetryManager(logger, 3, null);
        Test.stopTest();
        
        // Assert
        System.assertEquals(3, retryManager.getMaxRetries(), 'Should use provided max retries');
        System.assertEquals(1000, retryManager.getBaseDelayMs(), 'Should use default base delay when null');
    }
    
    @IsTest
    static void testScheduleQueueableRetry() {
        // Test Queueable retry scheduling (indirectly through production environment)
        IntegrationLogger logger = new IntegrationLogger();
        RetryManager retryManager = new RetryManager(logger, 2, 100);
        
        String correlationId = 'TEST-QUEUEABLE-001';
        String systemName = 'TestSystem';
        Map<String, Object> context = new Map<String, Object>{
            'endpoint' => 'https://test.example.com/api',
            'payload' => '{"test": "data"}',
            'headers' => new Map<String, String>{'Content-Type' => 'application/json'},
            'method' => 'POST',
            'test' => 'data'
        };
        
        // Create an operation that fails
        RetryableOperation failingOperation = new FailingTestOperation();
        
        // Enable Queueable retry for this test
        FrameworkConfigManager.getInstance().updateConfiguration(true, 'Production');
        
        Test.startTest();
        RetryResult result = retryManager.executeWithRetry(failingOperation, correlationId, systemName, context);
        Test.stopTest();
        
        // Assert
        System.assertEquals(false, result.getIsSuccess(), 'Operation should fail');
        System.assertEquals(0, result.getRetryCount(), 'Should not retry synchronously when using Queueable');
        System.assertNotEquals(null, result.getLastException(), 'Should have exception');
    }
    
    @IsTest
    static void testScheduleQueueableRetryWithMissingContext() {
        // Test Queueable retry with missing context data
        IntegrationLogger logger = new IntegrationLogger();
        RetryManager retryManager = new RetryManager(logger, 2, 100);
        
        String correlationId = 'TEST-QUEUEABLE-002';
        String systemName = 'TestSystem';
        Map<String, Object> context = new Map<String, Object>{
            'test' => 'data'
            // Missing endpoint, payload, headers, method
        };
        
        // Create an operation that fails
        RetryableOperation failingOperation = new FailingTestOperation();
        
        // Enable Queueable retry for this test
        FrameworkConfigManager.getInstance().updateConfiguration(true, 'Production');
        
        Test.startTest();
        RetryResult result = retryManager.executeWithRetry(failingOperation, correlationId, systemName, context);
        Test.stopTest();
        
        // Assert
        System.assertEquals(false, result.getIsSuccess(), 'Operation should fail');
        System.assertEquals(0, result.getRetryCount(), 'Should not retry synchronously when using Queueable');
        System.assertNotEquals(null, result.getLastException(), 'Should have exception');
    }
    
    // Test operation implementations
    private class SuccessfulTestOperation implements RetryableOperation {
        public Object execute() {
            return 'Success';
        }
    }
    
    private class RetryableTestOperation implements RetryableOperation {
        private Integer failCount;
        private Integer currentAttempt = 0;
        
        public RetryableTestOperation(Integer failCount) {
            this.failCount = failCount;
        }
        
        public Object execute() {
            currentAttempt++;
            if (currentAttempt <= failCount) {
                throw new CalloutException('Temporary failure - attempt ' + currentAttempt);
            }
            return 'Success';
        }
    }
    
    private class FailingTestOperation implements RetryableOperation {
        public Object execute() {
            throw new CalloutException('Test failure');
        }
    }
    
    private class NonRetryableTestOperation implements RetryableOperation {
        public Object execute() {
            throw new IllegalArgumentException('Non-retryable error');
        }
    }
}
