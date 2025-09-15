# Integration Framework - Complete Documentation

## Table of Contents
1. [Overview & Getting Started](#overview--getting-started)
2. [Core Components](#core-components)
3. [Configuration & Setup](#configuration--setup)
4. [Usage Examples & Patterns](#usage-examples--patterns)
5. [Advanced Features](#advanced-features)
6. [Testing & Quality Assurance](#testing--quality-assurance)
7. [Troubleshooting & Maintenance](#troubleshooting--maintenance)
8. [API Reference](#api-reference)
9. [Best Practices & Guidelines](#best-practices--guidelines)
10. [Migration & Upgrade](#migration--upgrade)

---

## Overview & Getting Started

### What is Integration Framework?

Integration Framework is a comprehensive, production-ready Salesforce framework designed to simplify and standardize integration development. It provides a robust foundation for building both inbound and outbound integrations with built-in logging, error handling, retry logic, and monitoring capabilities.

### Key Features

- **Unified Integration Interface**: Consistent API for both inbound and outbound integrations
- **Comprehensive Logging**: Automatic request/response logging with processing time tracking
- **Intelligent Error Handling**: Automatic error classification and severity assessment
- **Configurable Retry Logic**: Exponential backoff with customizable retry policies
- **Correlation Tracking**: End-to-end request tracing across systems
- **Performance Monitoring**: Built-in processing time and performance metrics
- **SOLID Compliance**: Follows SOLID principles

## ⚠️ Important: Data Cleanup Required

**This framework does NOT include built-in data cleanup functionality.** The framework creates `Integration_Log__c` and `Integration_Error__c` records for every integration request, which will accumulate over time and impact your org's storage and performance.

### Why No Built-in Cleanup?

We intentionally excluded automatic data cleanup to give developers complete freedom to implement their own data retention policies based on:
- **Compliance Requirements**: Different industries have varying data retention mandates
- **Business Needs**: Some organizations need to keep integration data for years, others only days
- **Storage Costs**: Developers can optimize cleanup frequency based on their storage budget
- **Audit Requirements**: Custom retention periods for different types of integrations

### Recommended Solution: Batch Apex Data Cleanup

**Use Salesforce Batch Apex for data cleanup** - it's the most efficient and scalable approach for large datasets.

#### Quick Setup (3 Steps):

1. **Deploy the Sample Batch Class**:
   ```apex
   // Run this in Anonymous Apex to set up monthly cleanup
   IntegrationDataCleanupBatch.scheduleMonthlyCleanup();
   ```

2. **Or Create Your Own Custom Batch**:
   ```apex
   global class MyCustomCleanupBatch implements Database.Batchable<SObject>, Schedulable {
       public Database.QueryLocator start(Database.BatchableContext bc) {
           Date cutoffDate = Date.today().addDays(-90); // Keep 90 days
           return Database.getQueryLocator([
               SELECT Id FROM Integration_Log__c 
               WHERE CreatedDate < :cutoffDate
           ]);
       }
       
       public void execute(Database.BatchableContext bc, List<SObject> records) {
           delete records; // Delete old logs
       }
       
       public void finish(Database.BatchableContext bc) {
           // Schedule next run
           System.schedule('Next Cleanup', '0 0 2 1 * ?', new MyCustomCleanupBatch());
       }
       
       public void execute(SchedulableContext sc) {
           Database.executeBatch(new MyCustomCleanupBatch(), 200);
       }
   }
   ```

3. **Schedule Your Batch Process**:
   ```apex
   // Monthly cleanup (1st of every month at 2 AM)
   System.schedule('Integration Cleanup', '0 0 2 1 * ?', new MyCustomCleanupBatch());
   ```

#### Salesforce Batch Apex Best Practices:

- **Batch Size**: Use 200 records per batch for optimal performance
- **Governor Limits**: Batch Apex can process up to 50 million records
- **Scheduling**: Use Cron expressions for automatic scheduling
- **Monitoring**: Check Apex Jobs in Setup to monitor batch execution
- **Error Handling**: Implement proper error handling in your batch classes

#### Sample Retention Policies:

| Data Type | Recommended Retention | Reason |
|-----------|----------------------|---------|
| Integration Logs | 30-90 days | Debugging and troubleshooting |
| Error Logs | 90-180 days | Compliance and audit requirements |
| Success Logs | 7-30 days | Minimal retention for successful calls |

### Architecture Overview

The framework follows a layered architecture:

```
┌─────────────────────────────────────────────────────────────┐
│                    Application Layer                        │
│  (SimpleAccountManagementDemo, ImprovedRestAPIDemo)        │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                    Connector Layer                          │
│  (RESTConnector, AccountRESTConnector)                     │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                    Core Framework Layer                     │
│  (IntegrationLogger, RetryManager, FrameworkErrorHandler)  │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                    Infrastructure Layer                     │
│  (Custom Objects, Named Credentials, Configuration)        │
└─────────────────────────────────────────────────────────────┘
```

### Quick Start Guide

#### Prerequisites

1. **Salesforce Org** with API access
2. **Custom Objects** deployed:
   - `Integration_Log__c`
   - `Integration_Error__c`
   - `Integration_Framework_Config__c`
3. **Named Credentials** configured for external systems
4. **Appropriate Permissions** for integration users

#### Basic Setup

1. **Deploy the Framework**:
   ```bash
   sf project deploy start --target-org your-org
   ```

2. **Configure Framework Settings**:
   ```apex
   // Create framework configuration
   Integration_Framework_Config__c config = new Integration_Framework_Config__c(
       Name = 'Default',
       Enable_Queueable_Retry__c = true,
       Environment_Type__c = 'Production'
   );
   insert config;
   ```

3. **Create Your First Integration**:
   ```apex
   // Outbound integration example
   IIntegrationLogger logger = new IntegrationLogger();
   RESTConnector connector = new RESTConnector(logger, 'ExternalSystem', 30000, null);
   
   IntegrationResponse response = connector.sendRequest(
       'callout:ExternalSystem/api/endpoint',
       '{"data": "value"}',
       new Map<String, String>{'Content-Type' => 'application/json'},
       'POST',
       'REQ-001'
   );
   ```

---

## Core Components

### RESTConnector

The primary connector for HTTP-based integrations.

**Key Features:**
- HTTP method support (GET, POST, PUT, PATCH, DELETE)
- Automatic retry logic with exponential backoff
- Comprehensive error handling and logging
- Named credential integration
- Request/response correlation tracking

**Basic Usage:**
```apex
RESTConnector connector = new RESTConnector(
    logger,           // IIntegrationLogger instance
    'SystemName',     // External system identifier
    30000,           // Timeout in milliseconds
    defaultHeaders    // Optional default headers
);

IntegrationResponse response = connector.sendRequest(
    endpoint,         // Target endpoint URL
    payload,          // Request payload
    headers,          // Request headers
    method,           // HTTP method
    correlationId     // Unique request identifier
);
```

### IntegrationLogger

Centralized logging component for all integration activities.

**Key Features:**
- Automatic request/response logging
- Processing time tracking
- Error logging and classification
- Correlation ID management
- Configurable log levels

**Basic Usage:**
```apex
IIntegrationLogger logger = new IntegrationLogger();

// Log outbound request
logger.logOutboundMessage(correlationId, systemName, payload, context);

// Log inbound response
logger.logInboundMessage(correlationId, systemName, responseBody, context);

// Log errors
logger.logError(correlationId, errorType, errorMessage, stackTrace, severity, context);
```

### RetryManager

Intelligent retry logic with configurable policies.

**Key Features:**
- Exponential backoff with jitter
- Configurable retry counts and delays
- Retryable vs non-retryable error classification
- Queueable retry support for long-running operations
- Comprehensive retry result tracking

**Basic Usage:**
```apex
RetryManager retryManager = new RetryManager(logger, errorHandler, 3, 1000);

RetryResult result = retryManager.executeWithRetry(
    operation,        // RetryableOperation to execute
    correlationId,    // Request correlation ID
    systemName,       // System name
    context          // Additional context
);
```

### FrameworkErrorHandler

Comprehensive error handling and classification system.

**Key Features:**
- Automatic error type classification
- Severity assessment and mapping
- HTTP status code determination
- Standardized error response generation
- Integration with logging system

**Basic Usage:**
```apex
FrameworkErrorHandler errorHandler = new FrameworkErrorHandler(logger);

errorHandler.logFrameworkError(
    correlationId,    // Request correlation ID
    errorType,        // Error type classification
    errorMessage,     // Error message
    stackTrace,       // Stack trace
    severity,         // Error severity
    context          // Additional context
);
```

---

## Configuration & Setup

### Custom Objects Setup

#### Integration_Log__c
Tracks all integration requests and responses.

**Required Fields:**
- `Correlation_ID__c` (Text) - Unique request identifier
- `Direction__c` (Picklist) - Inbound/Outbound
- `Message_Type__c` (Picklist) - Request/Response
- `Payload__c` (Long Text) - Request/response payload
- `Processing_Time__c` (Number) - Processing time in milliseconds
- `Status__c` (Picklist) - Sent/Received/Error
- `System__c` (Text) - External system name
- `Timestamp__c` (DateTime) - Log timestamp

#### Integration_Error__c
Tracks integration errors and exceptions.

**Required Fields:**
- `Correlation_ID__c` (Text) - Request correlation ID
- `Error_Type__c` (Text) - Error type classification
- `Error_Severity__c` (Picklist) - Error severity level
- `Error_Message__c` (Long Text) - Error message
- `Status__c` (Picklist) - Error status
- `Business_Impact__c` (Text) - Business impact assessment

#### Integration_Framework_Config__c
Framework configuration settings.

**Required Fields:**
- `Enable_Queueable_Retry__c` (Checkbox) - Enable queueable retries
- `Environment_Type__c` (Text) - Environment type (Production/Sandbox/Development)

### Named Credentials Configuration

1. **Setup Named Credential**:
   - Go to Setup > Named Credentials
   - Create new named credential
   - Configure authentication method
   - Set endpoint URL

2. **Use in Code**:
   ```apex
   // Use named credential in endpoint
   String endpoint = 'callout:YourNamedCredential/api/endpoint';
   ```

### Framework Configuration

#### Initial Setup
```apex
// Create default configuration
Integration_Framework_Config__c config = new Integration_Framework_Config__c(
    Name = 'Default',
    Enable_Queueable_Retry__c = true,
    Environment_Type__c = 'Production'
);
insert config;
```

#### Configuration Management
```apex
FrameworkConfigManager configManager = new FrameworkConfigManager();

// Load configuration
configManager.loadConfiguration();

// Update configuration
configManager.updateConfiguration(true, 'Production');

// Get configuration
Integration_Framework_Config__c config = configManager.getConfiguration();
```

---

## Usage Examples & Patterns

### Outbound Integration Examples

#### Basic REST API Call
```apex
public class MyIntegrationService {
    
    public static IntegrationResponse callExternalAPI(String data) {
        // Initialize framework components
        IIntegrationLogger logger = new IntegrationLogger();
        RESTConnector connector = new RESTConnector(logger, 'ExternalAPI', 30000, null);
        
        // Generate correlation ID
        String correlationId = CorrelationIdGenerator.generateCorrelationId('API');
        
        // Prepare request
        Map<String, String> headers = new Map<String, String>{
            'Content-Type' => 'application/json',
            'Accept' => 'application/json'
        };
        
        String payload = JSON.serialize(new Map<String, Object>{
            'data' => data,
            'timestamp' => System.currentTimeMillis()
        });
        
        // Make API call
        IntegrationResponse response = connector.sendRequest(
            'callout:ExternalAPI/v1/endpoint',
            payload,
            headers,
            'POST',
            correlationId
        );
        
        return response;
    }
}
```

#### Error Handling Pattern
```apex
public class RobustIntegrationService {
    
    public static IntegrationResponse callWithErrorHandling(String data) {
        try {
            // Integration logic here
            return callExternalAPI(data);
            
        } catch (CalloutException e) {
            // Handle callout-specific errors
            System.debug('Callout failed: ' + e.getMessage());
            return createErrorResponse('CALLOUT_ERROR', e.getMessage());
            
        } catch (Exception e) {
            // Handle general errors
            System.debug('Integration failed: ' + e.getMessage());
            return createErrorResponse('GENERAL_ERROR', e.getMessage());
        }
    }
    
    private static IntegrationResponse createErrorResponse(String errorType, String message) {
        return new IntegrationResponse(
            JSON.serialize(new Map<String, Object>{
                'error' => true,
                'type' => errorType,
                'message' => message
            }),
            500,
            new Map<String, String>{'Content-Type' => 'application/json'},
            null,
            0
        );
    }
}
```

### Inbound Integration Examples

#### REST Endpoint Implementation
```apex
@RestResource(urlMapping='/my-api/v1/')
global class MyRESTEndpoint {
    
    @HttpPost
    global static void handlePost() {
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
        
        try {
            // Initialize connector
            IIntegrationLogger logger = new IntegrationLogger();
            MyRESTConnector connector = new MyRESTConnector(logger, 'MySystem', 30000, null);
            
            // Process request
            IntegrationResponse integrationResponse = connector.handleInboundPost(request);
            
            // Set response
            response.statusCode = integrationResponse.getStatusCode();
            response.addHeader('Content-Type', 'application/json');
            response.responseBody = Blob.valueOf(integrationResponse.getResponseBody());
            
        } catch (Exception e) {
            // Handle errors
            response.statusCode = 500;
            response.addHeader('Content-Type', 'application/json');
            response.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
                'error' => true,
                'message' => e.getMessage()
            }));
        }
    }
}
```

#### Custom Connector Implementation
```apex
public class MyRESTConnector extends RESTConnector {
    
    public MyRESTConnector(IIntegrationLogger logger, String systemName, 
                          Integer timeoutMs, Map<String, String> defaultHeaders) {
        super(logger, systemName, timeoutMs, defaultHeaders);
    }
    
    protected override IntegrationResponse processInboundRequest(RestRequest request, String httpMethod) {
        try {
            // Process business logic based on HTTP method
            Map<String, Object> result = processBusinessLogic(request, httpMethod);
            
            // Determine status code
            Integer statusCode = (httpMethod == 'POST') ? 201 : 200;
            
            // Return response
            return new IntegrationResponse(
                JSON.serialize(result),
                statusCode,
                new Map<String, String>{'Content-Type' => 'application/json'},
                null, // correlationId - set by parent
                -1    // processingTimeMs - calculated by parent
            );
            
        } catch (Exception e) {
            // Re-throw for parent error handling
            throw e;
        }
    }
    
    private Map<String, Object> processBusinessLogic(RestRequest request, String httpMethod) {
        // Implement your business logic here
        return new Map<String, Object>{
            'success' => true,
            'method' => httpMethod,
            'timestamp' => System.currentTimeMillis()
        };
    }
}
```

---

## Advanced Features

### Retry Logic Configuration

#### Basic Retry Setup
```apex
// Configure retry manager
RetryManager retryManager = new RetryManager(
    logger,           // Logger instance
    errorHandler,     // Error handler instance
    3,               // Max retries
    1000             // Base delay in milliseconds
);
```

#### Custom Retry Policies
```apex
public class CustomRetryManager extends RetryManager {
    
    public CustomRetryManager(IIntegrationLogger logger, FrameworkErrorHandler errorHandler, 
                             Integer maxRetries, Integer baseDelayMs) {
        super(logger, errorHandler, maxRetries, baseDelayMs);
    }
    
    protected override Boolean isRetryableError(Exception ex) {
        // Custom retry logic
        if (ex instanceof CalloutException) {
            String message = ex.getMessage().toLowerCase();
            // Don't retry on 4xx client errors
            if (message.contains('400') || message.contains('401') || 
                message.contains('403') || message.contains('404')) {
                return false;
            }
            return true;
        }
        return false;
    }
}
```

### Queueable Retry Support

#### Enabling Queueable Retries
```apex
// Update framework configuration
FrameworkConfigManager configManager = new FrameworkConfigManager();
configManager.loadConfiguration();
configManager.updateConfiguration(true, 'Production');
```

#### Queueable Retry Implementation
```apex
public class MyRetryableOperation implements RetryableOperation {
    
    private String endpoint;
    private String payload;
    private Map<String, String> headers;
    
    public MyRetryableOperation(String endpoint, String payload, Map<String, String> headers) {
        this.endpoint = endpoint;
        this.payload = payload;
        this.headers = headers;
    }
    
    public Object execute() {
        // Implementation that may fail and need retry
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('POST');
        request.setBody(payload);
        
        if (headers != null) {
            for (String key : headers.keySet()) {
                request.setHeader(key, headers.get(key));
            }
        }
        
        Http http = new Http();
        HttpResponse response = http.send(request);
        
        if (response.getStatusCode() >= 400) {
            throw new CalloutException('HTTP Error: ' + response.getStatusCode());
        }
        
        return response;
    }
}
```

### Error Analytics and Monitoring

#### Error Classification
```apex
// Automatic error classification
FrameworkErrorHandler errorHandler = new FrameworkErrorHandler(logger);

String errorType = errorHandler.classifyError(exception);
String severity = errorHandler.assessFrameworkSeverity(errorType, errorMessage);
Integer statusCode = errorHandler.determineHttpStatusCode(errorType, errorMessage);
```

#### Performance Monitoring
```apex
// Processing time tracking is automatic
// Access processing time from logs
List<Integration_Log__c> logs = [
    SELECT Processing_Time__c, Status__c, System__c
    FROM Integration_Log__c 
    WHERE Correlation_ID__c = :correlationId
    ORDER BY CreatedDate
];

for (Integration_Log__c log : logs) {
    System.debug('Processing Time: ' + log.Processing_Time__c + 'ms');
    System.debug('Status: ' + log.Status__c);
}
```

---

## Testing & Quality Assurance

### Test Coverage Guidelines

The framework requires 95%+ test coverage for all classes. Follow these patterns:

#### Basic Test Structure
```apex
@IsTest
private class MyIntegrationTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test data
        Integration_Framework_Config__c config = new Integration_Framework_Config__c(
            Name = 'Test',
            Enable_Queueable_Retry__c = true,
            Environment_Type__c = 'Development'
        );
        insert config;
    }
    
    @IsTest
    static void testSuccessfulIntegration() {
        // Test successful integration
        Test.startTest();
        
        IntegrationResponse response = MyIntegrationService.callExternalAPI('test data');
        
        Test.stopTest();
        
        // Assertions
        System.assertEquals(true, response.getIsSuccess(), 'Integration should succeed');
        System.assertEquals(200, response.getStatusCode(), 'Status code should be 200');
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
}
```

#### Mock HTTP Responses
```apex
@IsTest
private class MockHttpResponseGenerator implements HttpCalloutMock {
    
    private Integer statusCode;
    private String responseBody;
    
    public MockHttpResponseGenerator(Integer statusCode, String responseBody) {
        this.statusCode = statusCode;
        this.responseBody = responseBody;
    }
    
    public HttpResponse respond(HttpRequest request) {
        HttpResponse response = new HttpResponse();
        response.setStatusCode(statusCode);
        response.setBody(responseBody);
        response.setHeader('Content-Type', 'application/json');
        return response;
    }
}

// Usage in test
@IsTest
static void testWithMockResponse() {
    Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, '{"success": true}'));
    
    Test.startTest();
    IntegrationResponse response = MyIntegrationService.callExternalAPI('test');
    Test.stopTest();
    
    System.assertEquals(200, response.getStatusCode());
}
```

### Testing Patterns

#### Unit Testing
- Test individual methods in isolation
- Use dependency injection for testability
- Mock external dependencies
- Test both success and error scenarios

#### Integration Testing
- Test complete integration flows
- Use realistic test data
- Test with actual external systems (in sandbox)
- Verify logging and error handling

#### Performance Testing
- Test with large payloads
- Measure processing times
- Test retry scenarios
- Verify memory usage

---

## Troubleshooting & Maintenance

### Common Issues

#### Issue: Processing Time Not Recorded
**Symptoms:** `Processing_Time__c` field is null in integration logs

**Solutions:**
1. Ensure you're using the latest framework version
2. Check that `logOutboundMessage` and `logInboundMessage` are called with processing time
3. Verify the `IntegrationLogger.createLogRecord` method is extracting processing time correctly

#### Issue: Retry Logic Not Working
**Symptoms:** Requests fail immediately without retries

**Solutions:**
1. Check `RetryManager.isRetryableError` method
2. Verify error types are classified correctly
3. Ensure retry configuration is set properly

#### Issue: Correlation ID Not Generated
**Symptoms:** Missing or duplicate correlation IDs

**Solutions:**
1. Use `CorrelationIdGenerator.generateCorrelationId()` for new requests
2. Pass correlation ID through the entire request flow
3. Check for null correlation ID handling

### Debugging Guide

#### Enable Debug Logging
```apex
// Set debug level for integration classes
System.debug(LoggingLevel.DEBUG, 'Integration request: ' + requestData);
System.debug(LoggingLevel.ERROR, 'Integration error: ' + errorMessage);
```

#### Check Integration Logs
```apex
// Query integration logs for debugging
List<Integration_Log__c> logs = [
    SELECT Correlation_ID__c, Direction__c, Message_Type__c, 
           Status__c, Processing_Time__c, Payload__c
    FROM Integration_Log__c 
    WHERE Correlation_ID__c = :correlationId
    ORDER BY CreatedDate
];

for (Integration_Log__c log : logs) {
    System.debug('Log: ' + log.Direction__c + ' ' + log.Message_Type__c + 
                ' Status: ' + log.Status__c + ' Time: ' + log.Processing_Time__c);
}
```

#### Check Error Logs
```apex
// Query error logs for debugging
List<Integration_Error__c> errors = [
    SELECT Error_Type__c, Error_Severity__c, Error_Message__c, 
           Business_Impact__c, Status__c
    FROM Integration_Error__c 
    WHERE Correlation_ID__c = :correlationId
    ORDER BY CreatedDate
];

for (Integration_Error__c error : errors) {
    System.debug('Error: ' + error.Error_Type__c + ' Severity: ' + error.Error_Severity__c);
}
```

### Maintenance Tasks

#### Data Cleanup Strategy

**Important Note**: The Integration Framework does not include built-in data cleanup functionality. This is intentional to give developers full control over their data retention policies. You must implement your own data cleanup strategy based on your organization's requirements.

#### Why No Built-in Cleanup?

1. **Flexibility**: Different organizations have different data retention requirements
2. **Compliance**: Some industries require specific data retention periods
3. **Performance**: Cleanup frequency should match your data volume and performance needs
4. **Control**: You decide when and how to clean up your data

#### Easy Data Cleanup Setup

**Step 1**: Copy the `IntegrationDataCleanupBatch.cls` file from the Examples folder to your org

**Step 2**: Schedule the cleanup (choose one option):

**Option A - Using Code (Recommended):**
```apex
IntegrationDataCleanupBatch.scheduleMonthlyCleanup();
```

**Option B - Using Salesforce Setup UI:**
1. Go to **Setup** → **Apex Jobs** → **Scheduled Jobs**
2. Click **Schedule Apex**
3. Configure:
   - **Job Name**: `Integration Data Cleanup - Monthly`
   - **Apex Class**: Select `IntegrationDataCleanupBatch`
   - **Frequency**: Monthly → 1st day of month
   - **Start Time**: 2:00 AM
4. Click **Save**

**Step 3**: You're done! Your data will be cleaned up automatically every month.

**What it does:**
- Keeps integration logs for 90 days
- Keeps error logs for 180 days  
- Runs on the 1st of every month at 2 AM
- Completely automatic - no manual work needed

**Optional - Test first:**
```apex
// See what would be deleted (doesn't actually delete anything)
IntegrationDataCleanupBatch.runDryRun();
```

**Optional - Clean up now:**
```apex
// Delete old data immediately
IntegrationDataCleanupBatch.runCleanupNow();
```

**Optional - Check your data:**
```apex
// See how much data you have
IntegrationDataCleanupBatch.checkDataVolume();
```

For more details, see the `DataCleanupSetupGuide.md` file in the Examples folder.

#### Usage Examples

```apex
// Run cleanup immediately
IntegrationDataCleanupBatch.runCleanupNow();

// Run dry run to see what would be deleted
IntegrationDataCleanupBatch.runDryRun();

// Schedule monthly cleanup
IntegrationDataCleanupBatch.scheduleMonthlyCleanup();

// Custom retention periods
IntegrationDataCleanupBatch customCleanup = new IntegrationDataCleanupBatch(60, 120, false);
Database.executeBatch(customCleanup, 200);

// Schedule with custom retention
System.schedule('Custom Cleanup', '0 0 3 1 * ?', new IntegrationDataCleanupBatch(30, 90, false));
```

#### Configuration Recommendations

1. **Integration Logs**: 30-90 days (adjust based on volume)
2. **Error Logs**: 90-180 days (keep longer for analysis)
3. **Frequency**: Monthly or quarterly
4. **Batch Size**: 200 records per batch
5. **Schedule Time**: Off-peak hours (2-4 AM)

#### Monitoring Cleanup

```apex
// Check data volume before cleanup
public class DataVolumeChecker {
    
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
}
```

#### Performance Monitoring
```apex
// Monitor integration performance
public class IntegrationPerformanceMonitor {
    
    public static void generatePerformanceReport() {
        List<AggregateResult> results = [
            SELECT System__c, AVG(Processing_Time__c) avgTime, 
                   MAX(Processing_Time__c) maxTime, COUNT(Id) totalCalls
            FROM Integration_Log__c 
            WHERE CreatedDate = TODAY
            GROUP BY System__c
        ];
        
        for (AggregateResult result : results) {
            System.debug('System: ' + result.get('System__c') + 
                        ' Avg Time: ' + result.get('avgTime') + 'ms' +
                        ' Max Time: ' + result.get('maxTime') + 'ms' +
                        ' Total Calls: ' + result.get('totalCalls'));
        }
    }
}
```

---

## API Reference

### Core Classes

#### RESTConnector
```apex
public class RESTConnector implements IIntegrationConnector {
    
    // Constructor
    public RESTConnector(IIntegrationLogger logger, String systemName, 
                        Integer timeoutMs, Map<String, String> defaultHeaders)
    
    // Main methods
    public IntegrationResponse sendRequest(String endpoint, String payload, 
                                         Map<String, String> headers, String method, String correlationId)
    
    public IntegrationResponse handleInboundRequest(RestRequest request, String httpMethod)
    public IntegrationResponse handleInboundGet(RestRequest request)
    public IntegrationResponse handleInboundPost(RestRequest request)
    public IntegrationResponse handleInboundPut(RestRequest request)
    public IntegrationResponse handleInboundPatch(RestRequest request)
    public IntegrationResponse handleInboundDelete(RestRequest request)
    
    // Utility methods
    public Boolean validateConfiguration()
    public String getConnectorType()
    public IIntegrationLogger getLogger()
    public String getSystemName()
}
```

#### IntegrationLogger
```apex
public class IntegrationLogger implements IIntegrationLogger {
    
    // Logging methods
    public void logInboundMessage(String correlationId, String systemName, 
                                 String payload, Map<String, Object> additionalContext)
    
    public void logOutboundMessage(String correlationId, String systemName, 
                                  String payload, Map<String, Object> additionalContext)
    
    public void logError(String correlationId, String errorType, String errorMessage, 
                        String stackTrace, String severity, Map<String, Object> context)
    
    public void updateLogStatus(String correlationId, String status, 
                               Map<String, Object> additionalData)
    
    // Utility methods
    public static IntegrationLogger getInstance()
}
```

#### RetryManager
```apex
public class RetryManager {
    
    // Constructor
    public RetryManager(IIntegrationLogger logger, FrameworkErrorHandler errorHandler, 
                       Integer maxRetries, Integer baseDelayMs)
    
    // Main methods
    public RetryResult executeWithRetry(RetryableOperation operation, String correlationId, 
                                       String systemName, Map<String, Object> context)
    
    public void scheduleQueueableRetry(RetryableOperation operation, String correlationId, 
                                     String systemName, Map<String, Object> context)
    
    // Utility methods
    public static RetryManager getInstance()
    public Boolean isRetryableError(Exception ex)
    public Integer calculateBackoffDelay(Integer retryCount)
}
```

#### FrameworkErrorHandler
```apex
public class FrameworkErrorHandler {
    
    // Constructor
    public FrameworkErrorHandler(IIntegrationLogger logger)
    
    // Main methods
    public void logFrameworkError(String correlationId, String errorType, String errorMessage, 
                                 String stackTrace, String severity, Map<String, Object> context)
    
    public String classifyError(Exception ex)
    public String assessFrameworkSeverity(String errorType, String errorMessage)
    public Integer determineHttpStatusCode(String errorType, String errorMessage)
    public Map<String, Object> createStandardErrorResponse(String errorType, String errorMessage)
}
```

### Data Models

#### IntegrationResponse
```apex
public class IntegrationResponse {
    
    // Constructors
    public IntegrationResponse(String responseBody, Integer statusCode, 
                             Map<String, String> headers, String correlationId, Long processingTimeMs)
    
    public IntegrationResponse(String errorMessage, Integer statusCode, 
                             String correlationId, Long processingTimeMs)
    
    // Getters
    public Boolean getIsSuccess()
    public String getResponseBody()
    public Integer getStatusCode()
    public Map<String, String> getHeaders()
    public String getErrorMessage()
    public String getCorrelationId()
    public Long getProcessingTimeMs()
    public Map<String, Object> getMetadata()
    
    // Utility methods
    public void addMetadata(String key, Object value)
    public Boolean isRetryableError()
    public String getSummary()
}
```

#### RetryResult
```apex
public class RetryResult {
    
    // Constructors
    public RetryResult(Object result, Boolean isSuccess, Integer retryCount, 
                      Long totalProcessingTime, Exception lastException)
    
    // Getters
    public Object getResult()
    public Boolean getIsSuccess()
    public Integer getRetryCount()
    public Long getTotalProcessingTime()
    public Exception getLastException()
    public String getErrorMessage()
    public Boolean wasRetried()
}
```

---

## Best Practices & Guidelines


The framework follows Apex Well-Architected Framework principles:

#### Single Responsibility Principle
- Each class has a single, well-defined purpose
- Methods are focused and do one thing well
- Clear separation between logging, error handling, and business logic

#### Open/Closed Principle
- Framework is open for extension through inheritance
- New connector types can be added without modifying existing code
- Strategy pattern used for retry logic and error handling

#### Dependency Inversion Principle
- High-level modules depend on abstractions (interfaces)
- Dependency injection used throughout the framework
- Easy to mock dependencies for testing

### Security Guidelines

#### Input Validation
```apex
// Always validate inputs
if (String.isBlank(endpoint)) {
    throw new IllegalArgumentException('Endpoint cannot be null or empty');
}

if (String.isBlank(correlationId)) {
    throw new IllegalArgumentException('Correlation ID cannot be null or empty');
}
```

#### Sensitive Data Handling
```apex
// Don't log sensitive data
Map<String, Object> context = new Map<String, Object>{
    'endpoint' => endpoint,
    'method' => httpMethod,
    // Don't include passwords or tokens
    'hasAuth' => headers.containsKey('Authorization')
};
```

#### Named Credentials
- Use named credentials for authentication
- Never hardcode credentials in code
- Rotate credentials regularly

### Performance Optimization

#### Bulk Operations
```apex
// Process records in bulk
List<Integration_Log__c> logsToInsert = new List<Integration_Log__c>();
for (String correlationId : correlationIds) {
    logsToInsert.add(createLogRecord(correlationId, ...));
}
insert logsToInsert;
```

#### Efficient Queries
```apex
// Use specific field lists
List<Integration_Log__c> logs = [
    SELECT Id, Correlation_ID__c, Processing_Time__c, Status__c
    FROM Integration_Log__c 
    WHERE Correlation_ID__c = :correlationId
    LIMIT 1
];
```

#### Memory Management
```apex
// Clear collections when done
Map<String, Object> context = new Map<String, Object>();
// ... use context
context.clear(); // Free memory
```

### Code Organization

#### Project Structure
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
└── Testing/                 # Test classes
    ├── IntegrationLoggerTest.cls
    ├── RESTConnectorTest.cls
    └── RetryManagerTest.cls
```

#### Naming Conventions
- Classes: PascalCase (e.g., `IntegrationLogger`)
- Methods: camelCase (e.g., `logInboundMessage`)
- Variables: camelCase (e.g., `correlationId`)
- Constants: UPPER_SNAKE_CASE (e.g., `DEFAULT_TIMEOUT_MS`)

---

## Migration & Upgrade

### Version History

#### Version 8.0 (Current)
- Fixed processing time tracking for both inbound and outbound logs
- Enhanced error handling and classification
- Improved retry logic with better error detection
- Added comprehensive test coverage
- Performance optimizations

#### Previous Versions
- Version 7.x: Initial framework implementation
- Version 6.x: Basic logging and error handling
- Version 5.x: Core integration patterns

### Migration Guide

#### From Version 7.x to 8.0

1. **Update Processing Time Handling**:
   ```apex
   // Old way (Version 7.x)
   logger.logOutboundMessage(correlationId, systemName, payload, context);
   
   // New way (Version 8.0)
   logger.logOutboundMessage(correlationId, systemName, payload, context);
   // Processing time is now automatically included
   ```

2. **Update Error Handling**:
   ```apex
   // Old way
   try {
       // integration logic
   } catch (Exception e) {
       logger.logError(correlationId, 'GENERAL_ERROR', e.getMessage(), null, 'HIGH', null);
   }
   
   // New way
   try {
       // integration logic
   } catch (Exception e) {
       FrameworkErrorHandler errorHandler = new FrameworkErrorHandler(logger);
       errorHandler.logFrameworkError(correlationId, 'GENERAL_ERROR', e.getMessage(), 
                                     e.getStackTraceString(), 'HIGH', null);
   }
   ```

### Breaking Changes

#### Version 8.0 Breaking Changes
1. **Processing Time Parameter**: `logOutboundMessage` now requires processing time in context
2. **Error Handler Integration**: Error logging now uses `FrameworkErrorHandler`
3. **Retry Logic**: Retry behavior has been updated for better error detection

#### Compatibility Matrix
| Salesforce Version | Framework Version | Status |
|-------------------|-------------------|---------|
| 64.0+ | 8.0 | Supported |
| 63.0 | 7.x | Supported |
| 62.0 | 7.x | Supported |
| < 62.0 | 6.x | Legacy |

### Upgrade Checklist

1. **Backup Current Implementation**
   - Export current integration code
   - Document current configuration
   - Test current functionality

2. **Deploy New Framework**
   - Deploy new framework classes
   - Update custom objects if needed
   - Verify configuration

3. **Update Integration Code**
   - Update method calls to match new API
   - Test error handling changes
   - Verify processing time tracking

4. **Test Thoroughly**
   - Run all existing tests
   - Test error scenarios
   - Verify logging functionality
   - Performance testing

5. **Monitor and Validate**
   - Monitor integration logs
   - Check error rates
   - Verify processing times
   - User acceptance testing

---

## Support and Resources

### Getting Help

1. **Documentation**: This comprehensive guide covers all aspects of the framework
2. **Code Examples**: Check the Examples folder for implementation patterns
3. **Test Classes**: Reference test classes for usage examples
4. **Debug Logs**: Enable debug logging for troubleshooting

### Contributing

1. **Code Standards**: Follow SOLID principles and naming conventions
2. **Testing**: Maintain 95%+ test coverage
3. **Documentation**: Update documentation for any changes
4. **Review Process**: All changes must be reviewed and tested

### Framework Maintenance

The Integration Framework is actively maintained and updated. Regular updates include:
- Bug fixes and performance improvements
- New features and capabilities
- Security updates and best practices
- Compatibility updates for new Salesforce versions

For the latest updates and announcements, refer to the framework documentation and release notes.
