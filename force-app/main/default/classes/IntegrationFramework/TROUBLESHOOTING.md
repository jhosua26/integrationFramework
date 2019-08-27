# Integration Framework V3 - Troubleshooting Guide

## Common Issues and Solutions

### Processing Time Issues

#### Issue: Processing_Time__c Field is Null
**Symptoms:**
- Integration logs show null values for Processing_Time__c
- Performance monitoring is incomplete

**Root Causes:**
1. Using outdated framework version
2. Processing time not passed in context
3. Logging methods called without processing time parameter

**Solutions:**

1. **Update to Latest Framework Version**
   ```apex
   // Ensure you're using the latest framework
   // Check that logOutboundMessage includes processing time
   logger.logOutboundMessage(correlationId, systemName, payload, new Map<String, Object>{
       'processingTime' => processingTime  // Include this
   });
   ```

2. **Verify Method Calls**
   ```apex
   // For HttpRequestOperation
   logOutboundMessage(correlationId, processingTime);  // Pass processing time
   
   // For RESTConnector
   logger.updateLogStatus(correlationId, 'Received', new Map<String, Object>{
       'processingTime' => processingTime  // Update inbound log
   });
   ```

3. **Check Context Parameters**
   ```apex
   Map<String, Object> context = new Map<String, Object>{
       'processingTime' => processingTime,  // Must be included
       'statusCode' => statusCode,
       'otherData' => otherData
   };
   ```

#### Issue: Processing Time Shows 0
**Symptoms:**
- Processing_Time__c shows 0 instead of actual time
- Performance metrics are inaccurate

**Root Causes:**
1. Hardcoded processing time in IntegrationResponse
2. Timing calculation issues
3. Incorrect method usage

**Solutions:**

1. **Remove Hardcoded Values**
   ```apex
   // Wrong - hardcoded processing time
   return new IntegrationResponse(
       responseBody, statusCode, headers, correlationId, 0  // Don't hardcode
   );
   
   // Correct - let parent calculate
   return new IntegrationResponse(
       responseBody, statusCode, headers, correlationId, -1  // Placeholder
   );
   ```

2. **Verify Timing Calculation**
   ```apex
   Long startTime = System.currentTimeMillis();
   // ... perform operation ...
   Long processingTime = System.currentTimeMillis() - startTime;
   ```

### Retry Logic Issues

#### Issue: Retries Not Working
**Symptoms:**
- Requests fail immediately without retries
- Retry count remains 0
- No retry logs created

**Root Causes:**
1. Errors classified as non-retryable
2. Retry configuration not set
3. Exception handling issues

**Solutions:**

1. **Check Error Classification**
   ```apex
   // Verify isRetryableError method
   RetryManager retryManager = new RetryManager(logger, errorHandler, 3, 1000);
   Boolean isRetryable = retryManager.isRetryableError(exception);
   System.debug('Is retryable: ' + isRetryable);
   ```

2. **Configure Retry Settings**
   ```apex
   // Enable queueable retries
   FrameworkConfigManager configManager = new FrameworkConfigManager();
   configManager.loadConfiguration();
   configManager.updateConfiguration(true, 'Production');
   ```

3. **Check Exception Types**
   ```apex
   // CalloutException is generally retryable
   if (ex instanceof CalloutException) {
       // Should be retryable unless it's a 4xx error
   }
   ```

#### Issue: Infinite Retry Loop
**Symptoms:**
- Retries continue indefinitely
- System performance degraded
- Governor limit errors

**Root Causes:**
1. Max retries not set properly
2. All errors classified as retryable
3. Retry delay calculation issues

**Solutions:**

1. **Set Max Retries**
   ```apex
   RetryManager retryManager = new RetryManager(logger, errorHandler, 3, 1000);
   // Max retries = 3, Base delay = 1000ms
   ```

2. **Review Error Classification**
   ```apex
   // Don't retry 4xx client errors
   if (ex instanceof CalloutException) {
       String message = ex.getMessage().toLowerCase();
       if (message.contains('400') || message.contains('401') || 
           message.contains('403') || message.contains('404')) {
           return false;  // Don't retry client errors
       }
   }
   ```

### Correlation ID Issues

#### Issue: Missing Correlation IDs
**Symptoms:**
- Logs show null correlation IDs
- Request tracking is incomplete
- Duplicate correlation IDs

**Root Causes:**
1. Correlation ID not generated
2. Correlation ID not passed through flow
3. Null handling issues

**Solutions:**

1. **Generate Correlation ID**
   ```apex
   // Always generate for new requests
   String correlationId = CorrelationIdGenerator.generateCorrelationId('API');
   ```

2. **Pass Through Flow**
   ```apex
   // Pass correlation ID through entire flow
   IntegrationResponse response = connector.sendRequest(
       endpoint, payload, headers, method, correlationId  // Pass it here
   );
   ```

3. **Handle Null Values**
   ```apex
   if (String.isBlank(correlationId)) {
       correlationId = CorrelationIdGenerator.generateCorrelationId();
   }
   ```

#### Issue: Duplicate Correlation IDs
**Symptoms:**
- Multiple requests with same correlation ID
- Log confusion and tracking issues

**Root Causes:**
1. Static correlation ID generation
2. Reusing correlation IDs
3. Timing issues

**Solutions:**

1. **Use Unique Generation**
   ```apex
   // Each request gets unique ID
   String correlationId = CorrelationIdGenerator.generateCorrelationId();
   ```

2. **Include Timestamp**
   ```apex
   // Include timestamp for uniqueness
   String correlationId = 'API-' + System.currentTimeMillis() + '-' + Math.random();
   ```

### Error Handling Issues

#### Issue: Errors Not Logged
**Symptoms:**
- Exceptions occur but no error logs created
- Error tracking is incomplete

**Root Causes:**
1. Error handler not initialized
2. Exception not caught properly
3. Logging method not called

**Solutions:**

1. **Initialize Error Handler**
   ```apex
   FrameworkErrorHandler errorHandler = new FrameworkErrorHandler(logger);
   errorHandler.logFrameworkError(correlationId, errorType, errorMessage, 
                                 stackTrace, severity, context);
   ```

2. **Catch All Exceptions**
   ```apex
   try {
       // Integration logic
   } catch (Exception e) {
       // Log the error
       errorHandler.logFrameworkError(correlationId, 'GENERAL_ERROR', e.getMessage(), 
                                     e.getStackTraceString(), 'HIGH', null);
   }
   ```

#### Issue: Error Classification Incorrect
**Symptoms:**
- Errors classified with wrong type or severity
- Inappropriate retry behavior

**Root Causes:**
1. Error classification logic issues
2. Exception message patterns not recognized
3. Severity mapping incorrect

**Solutions:**

1. **Review Classification Logic**
   ```apex
   // Check error classification
   String errorType = errorHandler.classifyError(exception);
   String severity = errorHandler.assessFrameworkSeverity(errorType, errorMessage);
   System.debug('Error Type: ' + errorType + ', Severity: ' + severity);
   ```

2. **Update Classification Rules**
   ```apex
   // Add custom classification logic
   if (errorMessage.contains('timeout')) {
       return 'TIMEOUT_ERROR';
   }
   ```

### Performance Issues

#### Issue: Slow Integration Performance
**Symptoms:**
- High processing times
- Timeout errors
- Poor user experience

**Root Causes:**
1. Inefficient queries
2. Large payload sizes
3. External system delays
4. Governor limit issues

**Solutions:**

1. **Optimize Queries**
   ```apex
   // Use specific field lists
   List<Account> accounts = [
       SELECT Id, Name, Phone  // Only needed fields
       FROM Account 
       WHERE Id = :accountId
       LIMIT 1
   ];
   ```

2. **Reduce Payload Size**
   ```apex
   // Only include necessary data
   Map<String, Object> payload = new Map<String, Object>{
       'id' => record.Id,
       'name' => record.Name
       // Don't include all fields
   };
   ```

3. **Implement Timeouts**
   ```apex
   // Set appropriate timeouts
   RESTConnector connector = new RESTConnector(logger, 'System', 30000, null);
   // 30 second timeout
   ```

#### Issue: Governor Limit Errors
**Symptoms:**
- "Too many SOQL queries" errors
- "CPU time limit exceeded" errors
- "DML rows limit exceeded" errors

**Root Causes:**
1. Queries in loops
2. Excessive DML operations
3. Complex processing logic

**Solutions:**

1. **Avoid Queries in Loops**
   ```apex
   // Wrong - query in loop
   for (String id : ids) {
       Account acc = [SELECT Id, Name FROM Account WHERE Id = :id];
   }
   
   // Correct - bulk query
   List<Account> accounts = [SELECT Id, Name FROM Account WHERE Id IN :ids];
   ```

2. **Bulk DML Operations**
   ```apex
   // Wrong - individual DML
   for (Account acc : accounts) {
       insert acc;
   }
   
   // Correct - bulk DML
   insert accounts;
   ```

### Logging Issues

#### Issue: Logs Not Created
**Symptoms:**
- Integration runs but no logs appear
- Missing request/response tracking

**Root Causes:**
1. Logger not initialized
2. DML operations before callout
3. Exception in logging code

**Solutions:**

1. **Initialize Logger**
   ```apex
   IIntegrationLogger logger = new IntegrationLogger();
   // Use the logger instance
   ```

2. **Avoid DML Before Callout**
   ```apex
   // Wrong - DML before callout
   insert logRecord;
   HttpRequest request = new HttpRequest();
   HttpResponse response = http.send(request);
   
   // Correct - DML after callout
   HttpRequest request = new HttpRequest();
   HttpResponse response = http.send(request);
   insert logRecord;
   ```

3. **Handle Logging Exceptions**
   ```apex
   try {
       logger.logOutboundMessage(correlationId, systemName, payload, context);
   } catch (Exception e) {
       System.debug('Logging failed: ' + e.getMessage());
       // Don't let logging errors break integration
   }
   ```

#### Issue: Incomplete Log Data
**Symptoms:**
- Logs created but missing fields
- Incomplete context information

**Root Causes:**
1. Context not passed properly
2. Field mapping issues
3. Data type mismatches

**Solutions:**

1. **Pass Complete Context**
   ```apex
   Map<String, Object> context = new Map<String, Object>{
       'endpoint' => endpoint,
       'method' => httpMethod,
       'processingTime' => processingTime,
       'statusCode' => statusCode,
       'headers' => headers
   };
   ```

2. **Verify Field Mapping**
   ```apex
   // Check that context keys match expected fields
   if (context.containsKey('processingTime')) {
       Object processingTimeObj = context.get('processingTime');
       if (processingTimeObj instanceof Long) {
           processingTime = (Long) processingTimeObj;
       }
   }
   ```

## Debugging Techniques

### Enable Debug Logging

1. **Set Debug Level**
   ```apex
   System.debug(LoggingLevel.DEBUG, 'Integration request: ' + requestData);
   System.debug(LoggingLevel.ERROR, 'Integration error: ' + errorMessage);
   ```

2. **Use Debug Statements**
   ```apex
   System.debug('=== INTEGRATION DEBUG ===');
   System.debug('Correlation ID: ' + correlationId);
   System.debug('Endpoint: ' + endpoint);
   System.debug('Method: ' + httpMethod);
   System.debug('Payload: ' + payload);
   System.debug('Processing Time: ' + processingTime + 'ms');
   ```

### Query Integration Logs

```apex
// Query recent logs
List<Integration_Log__c> logs = [
    SELECT Correlation_ID__c, Direction__c, Message_Type__c, 
           Status__c, Processing_Time__c, Payload__c, System__c
    FROM Integration_Log__c 
    WHERE CreatedDate = TODAY
    ORDER BY CreatedDate DESC
    LIMIT 10
];

for (Integration_Log__c log : logs) {
    System.debug('Log: ' + log.Direction__c + ' ' + log.Message_Type__c + 
                ' Status: ' + log.Status__c + ' Time: ' + log.Processing_Time__c + 'ms');
}
```

### Query Error Logs

```apex
// Query recent errors
List<Integration_Error__c> errors = [
    SELECT Error_Type__c, Error_Severity__c, Error_Message__c, 
           Business_Impact__c, Status__c, CreatedDate
    FROM Integration_Error__c 
    WHERE CreatedDate = TODAY
    ORDER BY CreatedDate DESC
    LIMIT 10
];

for (Integration_Error__c error : errors) {
    System.debug('Error: ' + error.Error_Type__c + ' Severity: ' + error.Error_Severity__c);
    System.debug('Message: ' + error.Error_Message__c);
}
```

### Performance Monitoring

```apex
// Monitor integration performance
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
```

## Testing and Validation

### Unit Testing

```apex
@IsTest
private class IntegrationTroubleshootingTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test configuration
        Integration_Framework_Config__c config = new Integration_Framework_Config__c(
            Name = 'Test',
            Enable_Queueable_Retry__c = true,
            Environment_Type__c = 'Development'
        );
        insert config;
    }
    
    @IsTest
    static void testErrorHandling() {
        // Test error scenarios
        Test.startTest();
        
        try {
            // Trigger error condition
            MyIntegrationService.callExternalAPI(null);
            System.assert(false, 'Should have thrown exception');
        } catch (IllegalArgumentException e) {
            System.assertEquals('Data cannot be null', e.getMessage());
        }
        
        Test.stopTest();
        
        // Verify error logging
        List<Integration_Error__c> errors = [
            SELECT Error_Type__c, Error_Severity__c 
            FROM Integration_Error__c 
            WHERE CreatedDate = TODAY
        ];
        System.assertEquals(1, errors.size(), 'Should have one error log');
    }
}
```

### Integration Testing

```apex
@IsTest
private class IntegrationEndToEndTest {
    
    @IsTest
    static void testCompleteFlow() {
        // Test complete integration flow
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, '{"success": true}'));
        
        Test.startTest();
        IntegrationResponse response = MyIntegrationService.callExternalAPI('test data');
        Test.stopTest();
        
        // Verify response
        System.assertEquals(true, response.getIsSuccess());
        System.assertEquals(200, response.getStatusCode());
        
        // Verify logging
        List<Integration_Log__c> logs = [
            SELECT Direction__c, Message_Type__c, Processing_Time__c
            FROM Integration_Log__c 
            WHERE CreatedDate = TODAY
        ];
        System.assertEquals(2, logs.size(), 'Should have outbound and inbound logs');
        
        for (Integration_Log__c log : logs) {
            System.assertNotEquals(null, log.Processing_Time__c, 'Processing time should not be null');
        }
    }
}
```

## Maintenance Tasks

### Data Cleanup Strategy

**Important**: The Integration Framework V3 does not include built-in data cleanup functionality. You must implement your own cleanup strategy.

#### Why No Built-in Cleanup?

1. **Flexibility**: Different organizations have different data retention requirements
2. **Compliance**: Some industries require specific data retention periods  
3. **Performance**: Cleanup frequency should match your data volume
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

### Performance Monitoring

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

### Health Checks

```apex
// Perform integration health checks
public class IntegrationHealthCheck {
    
    public static void performHealthCheck() {
        // Check for recent errors
        List<Integration_Error__c> recentErrors = [
            SELECT Error_Type__c, Error_Severity__c, COUNT(Id) errorCount
            FROM Integration_Error__c 
            WHERE CreatedDate = TODAY
            GROUP BY Error_Type__c, Error_Severity__c
        ];
        
        for (AggregateResult error : recentErrors) {
            System.debug('Error Type: ' + error.get('Error_Type__c') + 
                        ' Severity: ' + error.get('Error_Severity__c') +
                        ' Count: ' + error.get('errorCount'));
        }
        
        // Check processing times
        List<AggregateResult> performanceResults = [
            SELECT System__c, AVG(Processing_Time__c) avgTime
            FROM Integration_Log__c 
            WHERE CreatedDate = TODAY
            GROUP BY System__c
        ];
        
        for (AggregateResult result : performanceResults) {
            Decimal avgTime = (Decimal) result.get('avgTime');
            if (avgTime > 5000) {  // More than 5 seconds
                System.debug('WARNING: High processing time for ' + result.get('System__c') + 
                           ': ' + avgTime + 'ms');
            }
        }
    }
}
```

## Getting Help

### Debug Information to Collect

When reporting issues, collect the following information:

1. **Error Messages**: Complete error messages and stack traces
2. **Log Data**: Integration logs and error logs
3. **Configuration**: Framework configuration settings
4. **Code**: Relevant code snippets
5. **Environment**: Salesforce org version and edition
6. **Timing**: When the issue occurs and frequency

### Support Resources

1. **Documentation**: Check README.md and API_REFERENCE.md
2. **Examples**: Review code in the Examples folder
3. **Test Classes**: Reference test classes for usage patterns
4. **Debug Logs**: Enable debug logging for detailed information
5. **Community**: Check Salesforce developer community forums

### Escalation Process

1. **Check Documentation**: Review relevant documentation first
2. **Enable Debug Logging**: Collect detailed debug information
3. **Test in Sandbox**: Reproduce issue in sandbox environment
4. **Gather Information**: Collect all relevant logs and configuration
5. **Contact Support**: Provide complete information for assistance
