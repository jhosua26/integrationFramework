# Integration Framework V3 - Quick Start Guide

## Prerequisites

Before you begin, ensure you have:

1. **Salesforce Org** with API access
2. **Custom Objects** deployed (see Setup section)
3. **Named Credentials** configured for external systems
4. **Appropriate Permissions** for integration users

## Step 1: Deploy the Framework

Deploy the Integration Framework V3 to your Salesforce org:

```bash
sf project deploy start --target-org your-org
```

## Step 2: Setup Custom Objects

### Create Integration_Log__c
```apex
// This object tracks all integration requests and responses
// Fields: Correlation_ID__c (Text), Direction__c (Picklist), 
// Message_Type__c (Picklist), Payload__c (Long Text), 
// Processing_Time__c (Number), Status__c (Picklist), 
// System__c (Text), Timestamp__c (DateTime)
```

### Create Integration_Error__c
```apex
// This object tracks integration errors and exceptions
// Fields: Correlation_ID__c (Text), Error_Type__c (Text), 
// Error_Severity__c (Picklist), Error_Message__c (Long Text), 
// Status__c (Picklist), Business_Impact__c (Text)
```

### Create Integration_Framework_Config__c
```apex
// This object stores framework configuration
// Fields: Enable_Queueable_Retry__c (Checkbox), 
// Environment_Type__c (Text)
```

## Step 3: Configure Framework Settings

```apex
// Create framework configuration
Integration_Framework_Config__c config = new Integration_Framework_Config__c(
    Name = 'Default',
    Enable_Queueable_Retry__c = true,
    Environment_Type__c = 'Production'
);
insert config;
```

## Step 4: Create Your First Outbound Integration

```apex
public class MyFirstIntegration {
    
    public static IntegrationResponse callExternalAPI(String data) {
        // Initialize framework components
        IIntegrationLogger logger = new IntegrationLogger();
        RESTConnector connector = new RESTConnector(logger, 'ExternalSystem', 30000, null);
        
        // Generate correlation ID for tracking
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
            'callout:ExternalSystem/v1/endpoint',
            payload,
            headers,
            'POST',
            correlationId
        );
        
        return response;
    }
}
```

## Step 5: Create Your First Inbound Integration

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

## Step 6: Create Custom Connector

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

## Step 7: Test Your Integration

```apex
@IsTest
private class MyIntegrationTest {
    
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
    static void testOutboundIntegration() {
        // Mock HTTP response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, '{"success": true}'));
        
        Test.startTest();
        IntegrationResponse response = MyFirstIntegration.callExternalAPI('test data');
        Test.stopTest();
        
        // Assertions
        System.assertEquals(true, response.getIsSuccess(), 'Integration should succeed');
        System.assertEquals(200, response.getStatusCode(), 'Status code should be 200');
    }
    
    @IsTest
    static void testInboundIntegration() {
        // Create test request
        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf('{"data": "test"}');
        request.requestURI = '/my-api/v1/';
        request.httpMethod = 'POST';
        RestContext.request = request;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        MyRESTEndpoint.handlePost();
        Test.stopTest();
        
        // Assertions
        System.assertEquals(201, RestContext.response.statusCode, 'Status code should be 201');
    }
}

// Mock HTTP response generator
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
```

## Step 8: Monitor Your Integration

### Check Integration Logs
```apex
// Query integration logs
List<Integration_Log__c> logs = [
    SELECT Correlation_ID__c, Direction__c, Message_Type__c, 
           Status__c, Processing_Time__c, System__c
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

### Check Error Logs
```apex
// Query error logs
List<Integration_Error__c> errors = [
    SELECT Error_Type__c, Error_Severity__c, Error_Message__c
    FROM Integration_Error__c 
    WHERE CreatedDate = TODAY
    ORDER BY CreatedDate DESC
    LIMIT 10
];

for (Integration_Error__c error : errors) {
    System.debug('Error: ' + error.Error_Type__c + ' Severity: ' + error.Error_Severity__c);
}
```

## Next Steps

1. **Explore Examples**: Check the Examples folder for more complex integration patterns
2. **Read Full Documentation**: See README.md for comprehensive documentation
3. **Configure Retry Logic**: Set up retry policies for your specific needs
4. **Set Up Monitoring**: Implement monitoring and alerting for your integrations
5. **Performance Tuning**: Optimize your integrations for better performance
6. **Implement Data Cleanup**: Set up data cleanup strategy using the provided batch process

## Important: Data Cleanup

**The Integration Framework V3 does not include built-in data cleanup functionality.** You must implement your own data cleanup strategy based on your organization's requirements.

### Quick Setup for Data Cleanup

**Step 1**: Copy `IntegrationDataCleanupBatch.cls` from Examples folder to your org

**Step 2**: Schedule the cleanup (choose one):

**Option A - Using Code:**
```apex
IntegrationDataCleanupBatch.scheduleMonthlyCleanup();
```

**Option B - Using Salesforce Setup UI:**
1. **Setup** → **Apex Jobs** → **Scheduled Jobs** → **Schedule Apex**
2. **Job Name**: `Integration Data Cleanup - Monthly`
3. **Apex Class**: `IntegrationDataCleanupBatch`
4. **Frequency**: Monthly → 1st day of month
5. **Start Time**: 2:00 AM
6. Click **Save**

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

## Common Issues and Solutions

### Issue: Processing Time Not Recorded
**Solution**: Ensure you're using the latest framework version and that processing time is passed in the context.

### Issue: Retry Logic Not Working
**Solution**: Check that errors are classified as retryable and that retry configuration is set properly.

### Issue: Correlation ID Missing
**Solution**: Use `CorrelationIdGenerator.generateCorrelationId()` for new requests and pass it through the entire flow.

## Support

For additional help:
1. Check the full documentation in README.md
2. Review the test classes for usage examples
3. Enable debug logging for troubleshooting
4. Check the Examples folder for implementation patterns
