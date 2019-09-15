# Integration Framework - Best Practices & Guidelines


The Integration Framework follows SOLID principles to ensure maintainable, scalable, and robust code.

### Single Responsibility Principle (SRP)

Each class has a single, well-defined purpose:

- **RESTConnector**: Handles HTTP-based integrations
- **IntegrationLogger**: Manages logging functionality
- **RetryManager**: Handles retry logic
- **FrameworkErrorHandler**: Manages error handling

**Example:**
```apex
// Good - Single responsibility
public class IntegrationLogger {
    public void logInboundMessage(String correlationId, String systemName, String payload, Map<String, Object> context) {
        // Only handles inbound message logging
    }
}

// Bad - Multiple responsibilities
public class IntegrationManager {
    public void logMessage() { /* logging */ }
    public void sendRequest() { /* HTTP */ }
    public void handleErrors() { /* error handling */ }
}
```

### Open/Closed Principle (OCP)

The framework is open for extension but closed for modification:

```apex
// Extend RESTConnector for custom business logic
public class MyRESTConnector extends RESTConnector {
    
    public MyRESTConnector(IIntegrationLogger logger, String systemName, 
                          Integer timeoutMs, Map<String, String> defaultHeaders) {
        super(logger, systemName, timeoutMs, defaultHeaders);
    }
    
    protected override IntegrationResponse processInboundRequest(RestRequest request, String httpMethod) {
        // Custom business logic without modifying base class
        return super.processInboundRequest(request, httpMethod);
    }
}
```

### Liskov Substitution Principle (LSP)

Derived classes must be substitutable for their base classes:

```apex
// All connectors implement IIntegrationConnector
IIntegrationConnector connector = new RESTConnector(logger, systemName, timeoutMs, headers);
IIntegrationConnector customConnector = new MyRESTConnector(logger, systemName, timeoutMs, headers);

// Both can be used interchangeably
IntegrationResponse response1 = connector.sendRequest(endpoint, payload, headers, method, correlationId);
IntegrationResponse response2 = customConnector.sendRequest(endpoint, payload, headers, method, correlationId);
```

### Interface Segregation Principle (ISP)

Create specific interfaces for specific use cases:

```apex
// Specific interface for logging
public interface IIntegrationLogger {
    void logInboundMessage(String correlationId, String systemName, String payload, Map<String, Object> context);
    void logOutboundMessage(String correlationId, String systemName, String payload, Map<String, Object> context);
    void logError(String correlationId, String errorType, String errorMessage, String stackTrace, String severity, Map<String, Object> context);
}

// Specific interface for connectors
public interface IIntegrationConnector {
    IntegrationResponse sendRequest(String endpoint, String payload, Map<String, String> headers, String method, String correlationId);
    Boolean validateConfiguration();
    String getConnectorType();
}
```

### Dependency Inversion Principle (DIP)

High-level modules should not depend on low-level modules:

```apex
// Good - Depends on abstraction
public class RESTConnector {
    private final IIntegrationLogger logger;  // Depends on interface
    
    public RESTConnector(IIntegrationLogger logger, String systemName, Integer timeoutMs, Map<String, String> defaultHeaders) {
        this.logger = logger;  // Injected dependency
    }
}

// Bad - Depends on concrete class
public class RESTConnector {
    private final IntegrationLogger logger;  // Depends on concrete class
    
    public RESTConnector(String systemName, Integer timeoutMs, Map<String, String> defaultHeaders) {
        this.logger = new IntegrationLogger();  // Creates dependency
    }
}
```

## Security Guidelines

### Input Validation

Always validate inputs to prevent security vulnerabilities:

```apex
public class SecureIntegrationService {
    
    public static IntegrationResponse callExternalAPI(String data) {
        // Validate inputs
        if (String.isBlank(data)) {
            throw new IllegalArgumentException('Data cannot be null or empty');
        }
        
        if (data.length() > 10000) {
            throw new IllegalArgumentException('Data size exceeds maximum limit');
        }
        
        // Sanitize input
        String sanitizedData = data.escapeHtml4();
        
        // Continue with integration
        return processIntegration(sanitizedData);
    }
}
```

### Sensitive Data Handling

Never log sensitive information:

```apex
public class SecureLogger {
    
    public void logOutboundMessage(String correlationId, String systemName, String payload, Map<String, Object> context) {
        // Remove sensitive data from payload
        String sanitizedPayload = removeSensitiveData(payload);
        
        // Don't log sensitive context
        Map<String, Object> sanitizedContext = new Map<String, Object>();
        for (String key : context.keySet()) {
            if (!isSensitiveField(key)) {
                sanitizedContext.put(key, context.get(key));
            }
        }
        
        // Log sanitized data
        createLogRecord(correlationId, systemName, sanitizedPayload, sanitizedContext);
    }
    
    private String removeSensitiveData(String payload) {
        // Remove passwords, tokens, etc.
        return payload.replaceAll('"password":"[^"]*"', '"password":"***"')
                     .replaceAll('"token":"[^"]*"', '"token":"***"');
    }
    
    private Boolean isSensitiveField(String fieldName) {
        Set<String> sensitiveFields = new Set<String>{
            'password', 'token', 'secret', 'key', 'auth'
        };
        return sensitiveFields.contains(fieldName.toLowerCase());
    }
}
```

### Named Credentials

Use named credentials for authentication:

```apex
// Good - Use named credentials
String endpoint = 'callout:MyNamedCredential/api/endpoint';

// Bad - Hardcode credentials
String endpoint = 'https://username:password@api.example.com/endpoint';
```

### Access Control

Implement proper access control:

```apex
public class SecureIntegrationEndpoint {
    
    @HttpPost
    global static void handlePost() {
        // Check user permissions
        if (!hasIntegrationPermission()) {
            RestContext.response.statusCode = 403;
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
                'error' => 'Access denied'
            }));
            return;
        }
        
        // Continue with integration
        processRequest();
    }
    
    private static Boolean hasIntegrationPermission() {
        // Check user permissions
        return FeatureManagement.checkPermission('Integration_Access');
    }
}
```

## Performance Optimization

### Bulk Operations

Process records in bulk to avoid governor limits:

```apex
public class BulkIntegrationService {
    
    public static void processAccounts(List<Account> accounts) {
        // Process in bulk
        List<Integration_Log__c> logsToInsert = new List<Integration_Log__c>();
        
        for (Account acc : accounts) {
            logsToInsert.add(createLogRecord(acc));
        }
        
        // Single DML operation
        insert logsToInsert;
    }
    
    private static Integration_Log__c createLogRecord(Account acc) {
        return new Integration_Log__c(
            Correlation_ID__c = CorrelationIdGenerator.generateCorrelationId(),
            System__c = 'AccountSystem',
            Payload__c = JSON.serialize(acc),
            Direction__c = 'Outbound',
            Message_Type__c = 'Request',
            Status__c = 'Sent'
        );
    }
}
```

### Efficient Queries

Use specific field lists and appropriate filters:

```apex
public class EfficientQueryService {
    
    public static List<Account> getAccounts(Set<Id> accountIds) {
        // Good - Specific fields, indexed filter
        return [
            SELECT Id, Name, Phone, Industry
            FROM Account 
            WHERE Id IN :accountIds
            LIMIT 200
        ];
    }
    
    public static List<Integration_Log__c> getRecentLogs(String correlationId) {
        // Good - Indexed filter, specific fields
        return [
            SELECT Id, Direction__c, Message_Type__c, Processing_Time__c
            FROM Integration_Log__c 
            WHERE Correlation_ID__c = :correlationId
            ORDER BY CreatedDate DESC
            LIMIT 10
        ];
    }
}
```

### Memory Management

Clear collections and avoid memory leaks:

```apex
public class MemoryEfficientService {
    
    public static void processLargeDataset(List<SObject> records) {
        Map<String, Object> context = new Map<String, Object>();
        
        try {
            for (SObject record : records) {
                // Process record
                context.put('recordId', record.Id);
                processRecord(record, context);
            }
        } finally {
            // Clear context to free memory
            context.clear();
        }
    }
}
```

### Caching

Implement caching for frequently accessed data:

```apex
public class CachedIntegrationService {
    
    private static Map<String, Integration_Framework_Config__c> configCache = new Map<String, Integration_Framework_Config__c>();
    
    public static Integration_Framework_Config__c getConfiguration() {
        if (configCache.isEmpty()) {
            List<Integration_Framework_Config__c> configs = [
                SELECT Id, Name, Enable_Queueable_Retry__c, Environment_Type__c
                FROM Integration_Framework_Config__c
                LIMIT 1
            ];
            
            if (!configs.isEmpty()) {
                configCache.put('default', configs[0]);
            }
        }
        
        return configCache.get('default');
    }
}
```

## Error Handling Best Practices

### Comprehensive Error Handling

Handle all possible error scenarios:

```apex
public class RobustIntegrationService {
    
    public static IntegrationResponse callExternalAPI(String data) {
        String correlationId = CorrelationIdGenerator.generateCorrelationId();
        
        try {
            // Validate input
            validateInput(data);
            
            // Make API call
            return makeAPICall(data, correlationId);
            
        } catch (IllegalArgumentException e) {
            // Handle validation errors
            return createErrorResponse('VALIDATION_ERROR', e.getMessage(), correlationId);
            
        } catch (CalloutException e) {
            // Handle callout errors
            return createErrorResponse('CALLOUT_ERROR', e.getMessage(), correlationId);
            
        } catch (Exception e) {
            // Handle unexpected errors
            return createErrorResponse('UNEXPECTED_ERROR', e.getMessage(), correlationId);
        }
    }
    
    private static void validateInput(String data) {
        if (String.isBlank(data)) {
            throw new IllegalArgumentException('Data cannot be null or empty');
        }
    }
    
    private static IntegrationResponse createErrorResponse(String errorType, String message, String correlationId) {
        // Log error
        FrameworkErrorHandler errorHandler = new FrameworkErrorHandler(new IntegrationLogger());
        errorHandler.logFrameworkError(correlationId, errorType, message, null, 'HIGH', null);
        
        // Return error response
        return new IntegrationResponse(message, 500, correlationId, 0);
    }
}
```

### Retry Logic

Implement intelligent retry logic:

```apex
public class RetryableIntegrationService {
    
    public static IntegrationResponse callWithRetry(String data) {
        RetryManager retryManager = new RetryManager(
            new IntegrationLogger(), 
            new FrameworkErrorHandler(new IntegrationLogger()), 
            3, 
            1000
        );
        
        RetryableOperation operation = new MyRetryableOperation(data);
        String correlationId = CorrelationIdGenerator.generateCorrelationId();
        
        RetryResult result = retryManager.executeWithRetry(
            operation, 
            correlationId, 
            'ExternalSystem', 
            new Map<String, Object>{'data' => data}
        );
        
        if (result.getIsSuccess()) {
            return (IntegrationResponse) result.getResult();
        } else {
            return createErrorResponse(result.getErrorMessage(), correlationId);
        }
    }
}
```

### Error Classification

Classify errors appropriately:

```apex
public class ErrorClassificationService {
    
    public static String classifyError(Exception ex) {
        if (ex instanceof CalloutException) {
            String message = ex.getMessage().toLowerCase();
            if (message.contains('timeout')) {
                return 'TIMEOUT_ERROR';
            } else if (message.contains('401')) {
                return 'AUTHENTICATION_ERROR';
            } else if (message.contains('403')) {
                return 'AUTHORIZATION_ERROR';
            } else if (message.contains('404')) {
                return 'NOT_FOUND_ERROR';
            } else if (message.contains('500')) {
                return 'SERVER_ERROR';
            }
            return 'CALLOUT_ERROR';
        } else if (ex instanceof DmlException) {
            return 'DML_ERROR';
        } else if (ex instanceof QueryException) {
            return 'QUERY_ERROR';
        } else if (ex instanceof IllegalArgumentException) {
            return 'VALIDATION_ERROR';
        }
        return 'UNKNOWN_ERROR';
    }
}
```

## Logging Best Practices

### Structured Logging

Use consistent logging structure:

```apex
public class StructuredLogger {
    
    public void logIntegrationEvent(String correlationId, String eventType, Map<String, Object> data) {
        Map<String, Object> logContext = new Map<String, Object>{
            'correlationId' => correlationId,
            'eventType' => eventType,
            'timestamp' => System.currentTimeMillis(),
            'userId' => UserInfo.getUserId(),
            'orgId' => UserInfo.getOrganizationId(),
            'data' => data
        };
        
        // Log with consistent structure
        System.debug(LoggingLevel.INFO, 'Integration Event: ' + JSON.serialize(logContext));
    }
}
```

### Log Levels

Use appropriate log levels:

```apex
public class LogLevelService {
    
    public void logDebug(String message) {
        System.debug(LoggingLevel.DEBUG, message);
    }
    
    public void logInfo(String message) {
        System.debug(LoggingLevel.INFO, message);
    }
    
    public void logWarning(String message) {
        System.debug(LoggingLevel.WARN, message);
    }
    
    public void logError(String message) {
        System.debug(LoggingLevel.ERROR, message);
    }
}
```

### Performance Logging

Log performance metrics:

```apex
public class PerformanceLogger {
    
    public void logPerformanceMetrics(String correlationId, Long processingTime, String operation) {
        Map<String, Object> metrics = new Map<String, Object>{
            'correlationId' => correlationId,
            'operation' => operation,
            'processingTime' => processingTime,
            'timestamp' => System.currentTimeMillis(),
            'cpuTime' => Limits.getCpuTime(),
            'heapSize' => Limits.getHeapSize()
        };
        
        System.debug(LoggingLevel.INFO, 'Performance Metrics: ' + JSON.serialize(metrics));
    }
}
```

## Testing Best Practices

### Comprehensive Test Coverage

Achieve 95%+ test coverage:

```apex
@IsTest
private class ComprehensiveIntegrationTest {
    
    @TestSetup
    static void setupTestData() {
        // Create all necessary test data
        createTestConfiguration();
        createTestRecords();
    }
    
    @IsTest
    static void testSuccessfulIntegration() {
        // Test happy path
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, '{"success": true}'));
        
        Test.startTest();
        IntegrationResponse response = MyIntegrationService.callExternalAPI('test data');
        Test.stopTest();
        
        // Assertions
        System.assertEquals(true, response.getIsSuccess());
        System.assertEquals(200, response.getStatusCode());
        System.assertNotEquals(null, response.getCorrelationId());
    }
    
    @IsTest
    static void testErrorHandling() {
        // Test error scenarios
        Test.startTest();
        
        try {
            MyIntegrationService.callExternalAPI(null);
            System.assert(false, 'Should have thrown exception');
        } catch (IllegalArgumentException e) {
            System.assertEquals('Data cannot be null', e.getMessage());
        }
        
        Test.stopTest();
    }
    
    @IsTest
    static void testRetryLogic() {
        // Test retry scenarios
        Test.setMock(HttpCalloutMock.class, new MockRetryableResponseGenerator());
        
        Test.startTest();
        IntegrationResponse response = MyIntegrationService.callWithRetry('test data');
        Test.stopTest();
        
        // Verify retry behavior
        System.assertEquals(true, response.getIsSuccess());
    }
}
```

### Mock External Dependencies

Mock external systems for testing:

```apex
private class MockHttpResponseGenerator implements HttpCalloutMock {
    private Integer statusCode;
    private String responseBody;
    private Integer callCount = 0;
    private Integer maxCalls;
    
    public MockHttpResponseGenerator(Integer statusCode, String responseBody) {
        this.statusCode = statusCode;
        this.responseBody = responseBody;
        this.maxCalls = 1;
    }
    
    public MockHttpResponseGenerator(Integer statusCode, String responseBody, Integer maxCalls) {
        this.statusCode = statusCode;
        this.responseBody = responseBody;
        this.maxCalls = maxCalls;
    }
    
    public HttpResponse respond(HttpRequest request) {
        callCount++;
        
        if (callCount <= maxCalls) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(statusCode);
            response.setBody(responseBody);
            response.setHeader('Content-Type', 'application/json');
            return response;
        } else {
            // Return success after retries
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setBody('{"success": true}');
            response.setHeader('Content-Type', 'application/json');
            return response;
        }
    }
}
```

### Test Data Management

Create reusable test data:

```apex
@IsTest
private class TestDataFactory {
    
    public static Integration_Framework_Config__c createTestConfig() {
        return new Integration_Framework_Config__c(
            Name = 'Test',
            Enable_Queueable_Retry__c = true,
            Environment_Type__c = 'Development'
        );
    }
    
    public static Account createTestAccount() {
        return new Account(
            Name = 'Test Account',
            Phone = '555-1234',
            Industry = 'Technology'
        );
    }
    
    public static List<Account> createTestAccounts(Integer count) {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < count; i++) {
            accounts.add(new Account(
                Name = 'Test Account ' + i,
                Phone = '555-' + String.valueOf(1000 + i),
                Industry = 'Technology'
            ));
        }
        return accounts;
    }
}
```

## Code Organization

### Project Structure

Organize code logically:

```
force-app/main/default/classes/IntegrationFramewor/
├── Core/                    # Core framework classes
│   ├── IntegrationLogger.cls
│   ├── RetryManager.cls
│   ├── FrameworkErrorHandler.cls
│   └── IntegrationResponse.cls
├── Connectors/              # Connector implementations
│   ├── RESTConnector.cls
│   └── HttpRequestOperation.cls
├── Examples/                # Example implementations
│   ├── SimpleAccountManagementDemo.cls
│   ├── ImprovedRestAPIDemo.cls
│   └── AccountRESTConnector.cls
├── Testing/                 # Test classes
│   ├── IntegrationLoggerTest.cls
│   ├── RESTConnectorTest.cls
│   └── RetryManagerTest.cls
├── Utils/                   # Utility classes
│   ├── CorrelationIdGenerator.cls
│   └── IntegrationHelpers.cls
└── Config/                  # Configuration classes
    └── FrameworkConfigManager.cls
```

### Naming Conventions

Follow consistent naming conventions:

```apex
// Classes: PascalCase
public class IntegrationLogger { }
public class RESTConnector { }
public class FrameworkErrorHandler { }

// Methods: camelCase
public void logInboundMessage() { }
public IntegrationResponse sendRequest() { }
public Boolean validateConfiguration() { }

// Variables: camelCase
String correlationId = 'REQ-001';
Map<String, Object> context = new Map<String, Object>();
List<Integration_Log__c> logs = new List<Integration_Log__c>();

// Constants: UPPER_SNAKE_CASE
private static final Integer DEFAULT_TIMEOUT_MS = 30000;
private static final String DEFAULT_SYSTEM_NAME = 'ExternalSystem';
private static final Set<String> RETRYABLE_ERRORS = new Set<String>{'TIMEOUT_ERROR', 'SERVER_ERROR'};
```

### Documentation

Document all public methods:

```apex
/**
 * @description Sends a request to the external system with retry logic
 * @param endpoint The endpoint URL to call
 * @param payload The request payload (JSON string)
 * @param headers Map of HTTP headers to include
 * @param method HTTP method (GET, POST, PUT, PATCH, DELETE)
 * @param correlationId Unique identifier for tracking this request
 * @return IntegrationResponse containing the response data and metadata
 * @throws IllegalArgumentException if endpoint, method, or correlationId is blank
 * @throws CalloutException if the HTTP callout fails
 * @example
 * IntegrationResponse response = connector.sendRequest(
 *     'callout:MyAPI/endpoint',
 *     '{"data": "value"}',
 *     new Map<String, String>{'Content-Type' => 'application/json'},
 *     'POST',
 *     'REQ-001'
 * );
 */
public IntegrationResponse sendRequest(String endpoint, String payload, 
                                     Map<String, String> headers, String method, String correlationId) {
    // Implementation
}
```

## Monitoring and Maintenance

### Health Checks

Implement regular health checks:

```apex
public class IntegrationHealthCheck {
    
    public static HealthCheckResult performHealthCheck() {
        HealthCheckResult result = new HealthCheckResult();
        
        // Check configuration
        result.configurationValid = checkConfiguration();
        
        // Check recent errors
        result.errorRate = calculateErrorRate();
        
        // Check performance
        result.averageProcessingTime = calculateAverageProcessingTime();
        
        // Check log volume
        result.logVolume = calculateLogVolume();
        
        return result;
    }
    
    private static Boolean checkConfiguration() {
        try {
            FrameworkConfigManager configManager = new FrameworkConfigManager();
            configManager.loadConfiguration();
            return configManager.getConfiguration() != null;
        } catch (Exception e) {
            return false;
        }
    }
    
    private static Decimal calculateErrorRate() {
        List<AggregateResult> results = [
            SELECT COUNT(Id) totalLogs
            FROM Integration_Log__c 
            WHERE CreatedDate = TODAY
        ];
        
        List<AggregateResult> errorResults = [
            SELECT COUNT(Id) errorLogs
            FROM Integration_Error__c 
            WHERE CreatedDate = TODAY
        ];
        
        Integer totalLogs = (Integer) results[0].get('totalLogs');
        Integer errorLogs = (Integer) errorResults[0].get('errorLogs');
        
        return totalLogs > 0 ? (Decimal.valueOf(errorLogs) / Decimal.valueOf(totalLogs)) * 100 : 0;
    }
}
```

### Performance Monitoring

Monitor integration performance:

```apex
public class PerformanceMonitor {
    
    public static void generatePerformanceReport() {
        List<AggregateResult> results = [
            SELECT System__c, 
                   AVG(Processing_Time__c) avgTime,
                   MAX(Processing_Time__c) maxTime,
                   MIN(Processing_Time__c) minTime,
                   COUNT(Id) totalCalls
            FROM Integration_Log__c 
            WHERE CreatedDate = TODAY
            GROUP BY System__c
        ];
        
        for (AggregateResult result : results) {
            String systemName = (String) result.get('System__c');
            Decimal avgTime = (Decimal) result.get('avgTime');
            Decimal maxTime = (Decimal) result.get('maxTime');
            Decimal minTime = (Decimal) result.get('minTime');
            Integer totalCalls = (Integer) result.get('totalCalls');
            
            System.debug('System: ' + systemName);
            System.debug('  Total Calls: ' + totalCalls);
            System.debug('  Average Time: ' + avgTime + 'ms');
            System.debug('  Max Time: ' + maxTime + 'ms');
            System.debug('  Min Time: ' + minTime + 'ms');
            
            // Alert on performance issues
            if (avgTime > 5000) {
                System.debug('WARNING: High average processing time for ' + systemName);
            }
        }
    }
}
```

### Data Cleanup Strategy

**Important**: The Integration Framework does not include built-in data cleanup functionality. You must implement your own cleanup strategy based on your organization's requirements.

#### Why No Built-in Cleanup?

1. **Flexibility**: Different organizations have different data retention requirements
2. **Compliance**: Some industries require specific data retention periods
3. **Performance**: Cleanup frequency should match your data volume and performance needs
4. **Control**: You decide when and how to clean up your data

#### Easy Data Cleanup Setup

**Step 1**: Copy `IntegrationDataCleanupBatch.cls` from Examples folder to your org

**Step 2**: Run this ONE line:
```apex
IntegrationDataCleanupBatch.scheduleMonthlyCleanup();
```

**Step 3**: Done! Your data will be cleaned automatically every month.

**What it does:**
- Keeps logs for 90 days, errors for 180 days
- Runs on the 1st of every month at 2 AM
- Completely automatic

**Optional - Test first:**
```apex
IntegrationDataCleanupBatch.runDryRun(); // See what would be deleted
```

**Optional - Clean up now:**
```apex
IntegrationDataCleanupBatch.runCleanupNow(); // Delete old data immediately
```

For detailed setup instructions, see `DataCleanupSetupGuide.md` in the Examples folder.

### Regular Maintenance

Implement regular maintenance tasks:

```apex
public class MaintenanceTasks {
    
    public static void checkDataVolume() {
        // Check integration logs
        List<AggregateResult> logResults = [
            SELECT COUNT(Id) totalLogs, MIN(CreatedDate) oldestLog, MAX(CreatedDate) newestLog
            FROM Integration_Log__c
        ];
        
        // Check error logs
        List<AggregateResult> errorResults = [
            SELECT COUNT(Id) totalErrors, MIN(CreatedDate) oldestError, MAX(CreatedDate) newestError
            FROM Integration_Error__c
        ];
        
        System.debug('=== Data Volume Report ===');
        System.debug('Integration Logs: ' + logResults[0].get('totalLogs'));
        System.debug('Oldest Log: ' + logResults[0].get('oldestLog'));
        System.debug('Newest Log: ' + logResults[0].get('newestLog'));
        System.debug('Error Logs: ' + errorResults[0].get('totalErrors'));
        System.debug('Oldest Error: ' + errorResults[0].get('oldestError'));
        System.debug('Newest Error: ' + errorResults[0].get('newestError'));
    }
    
    public static void archiveOldErrors() {
        Date cutoffDate = Date.today().addDays(-30);
        
        List<Integration_Error__c> oldErrors = [
            SELECT Id FROM Integration_Error__c 
            WHERE CreatedDate < :cutoffDate
            AND Status__c = 'Resolved'
        ];
        
        if (!oldErrors.isEmpty()) {
            delete oldErrors;
            System.debug('Archived ' + oldErrors.size() + ' old error records');
        }
    }
}
```

## Conclusion

Following these best practices will ensure that your integrations are:

- **Secure**: Protected against common security vulnerabilities
- **Performant**: Optimized for speed and efficiency
- **Maintainable**: Easy to understand and modify
- **Reliable**: Robust error handling and retry logic
- **Testable**: Comprehensive test coverage
- **Monitored**: Proper logging and performance tracking

The Integration Framework provides the foundation for building enterprise-grade integrations that scale with your business needs.
