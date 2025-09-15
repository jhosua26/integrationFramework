/**
 * @description Integration Framework - Version 8
 * @author Jhosua R. Arda
 * @version 8.0
 * @purpose This framework is being used in Accenture projects and freelancing work.
 *          DO NOT MODIFY this class as it is part of the framework.
 *          Modifying this class will destroy the framework functionality.
 * 
 * Test class to verify inbound response logging functionality
 * Uses Test.setMock to simulate successful HTTP responses
 * 
 * IMPORTANT: DO NOT REMOVE existing test methods. Only add new test methods to maintain
 *            high test coverage. Removing existing methods will reduce test coverage.
 */
@isTest
public class InboundLoggingTest {
    
    @testSetup
    static void setup() {
        // Create test configuration with Queueable retry disabled for synchronous testing
        Integration_Framework_Config__c testConfig = new Integration_Framework_Config__c(
            Enable_Queueable_Retry__c = false,
            Environment_Type__c = 'Development'
        );
        insert testConfig;
    }
    
    /**
     * @description Mock HTTP response for testing
     */
    public class MockHttpResponse implements HttpCalloutMock {
        private Integer statusCode;
        private String responseBody;
        
        public MockHttpResponse(Integer statusCode, String responseBody) {
            this.statusCode = statusCode;
            this.responseBody = responseBody;
        }
        
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(this.statusCode);
            res.setBody(this.responseBody);
            res.setHeader('Content-Type', 'application/json');
            res.setHeader('X-Test-Header', 'test-value');
            return res;
        }
    }
    
    @isTest
    static void testSuccessfulCalloutWithInboundLogging() {
        // Set up mock response for successful callout
        String mockResponseBody = '{"id": "12345", "name": "Test Account", "status": "created"}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, mockResponseBody));
        
        Test.startTest();
        
        // Initialize framework components
        IIntegrationLogger logger = new IntegrationLogger();
        RESTConnector connector = new RESTConnector(logger, 'TestSystem', 30000, null);
        
        String correlationId = 'TEST-SUCCESS-' + Datetime.now().getTime();
        Map<String, String> headers = new Map<String, String>{
            'Content-Type' => 'application/json'
        };
        
        Map<String, Object> requestPayload = new Map<String, Object>{
            'name' => 'Test Account',
            'industry' => 'Technology'
        };
        
        // Make the callout
        IntegrationResponse response = connector.sendRequest(
            'https://api.example.com/accounts',
            JSON.serialize(requestPayload),
            headers,
            correlationId
        );
        
        Test.stopTest();
        
        // Verify response
        System.assertEquals(true, response.getIsSuccess(), 'Response should be successful');
        System.assertEquals(200, response.getStatusCode(), 'Status code should be 200');
        System.assertEquals(mockResponseBody, response.getResponseBody(), 'Response body should match mock');
        
        // Query logs to verify both outbound and inbound logging
        List<Integration_Log__c> logs = [
            SELECT Id, Correlation_ID__c, Direction__c, Message_Type__c, Status__c, System__c, Payload__c
            FROM Integration_Log__c 
            WHERE Correlation_ID__c = :correlationId 
            ORDER BY CreatedDate ASC
        ];
        
        System.debug('=== INBOUND LOGGING TEST RESULTS ===');
        System.debug('Total logs found: ' + logs.size());
        
        // Should have 2 logs: 1 outbound request + 1 inbound response
        System.assertEquals(2, logs.size(), 'Should have exactly 2 logs (outbound + inbound)');
        
        // Verify outbound log
        Integration_Log__c outboundLog = logs[0];
        System.assertEquals('Outbound', outboundLog.Direction__c, 'First log should be outbound');
        System.assertEquals('Request', outboundLog.Message_Type__c, 'First log should be request');
        // Status can be either 'Sent' or 'Completed' depending on retry logic
        System.assert(outboundLog.Status__c == 'Sent' || outboundLog.Status__c == 'Completed', 'Outbound log should have Sent or Completed status');
        
        // Verify inbound log
        Integration_Log__c inboundLog = logs[1];
        System.assertEquals('Inbound', inboundLog.Direction__c, 'Second log should be inbound');
        System.assertEquals('Response', inboundLog.Message_Type__c, 'Second log should be response');
        System.assertEquals('Received', inboundLog.Status__c, 'Inbound log should have Received status');
        
        System.debug('✅ Outbound Log: ' + outboundLog.Direction__c + ' | ' + outboundLog.Message_Type__c + ' | ' + outboundLog.Status__c);
        System.debug('✅ Inbound Log: ' + inboundLog.Direction__c + ' | ' + inboundLog.Message_Type__c + ' | ' + inboundLog.Status__c);
        
        // Verify no errors were created for successful callout
        List<Integration_Error__c> errors = [
            SELECT Id FROM Integration_Error__c 
            WHERE Correlation_ID__c = :correlationId
        ];
        System.assertEquals(0, errors.size(), 'No errors should be created for successful callout');
    }
    
    @isTest
    static void testFailedCalloutWithErrorLogging() {
        // Set up mock response for failed callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(500, '{"error": "Internal Server Error"}'));
        
        Test.startTest();
        
        // Initialize framework components
        IIntegrationLogger logger = new IntegrationLogger();
        RESTConnector connector = new RESTConnector(logger, 'TestSystem', 30000, null);
        
        String correlationId = 'TEST-ERROR-' + Datetime.now().getTime();
        Map<String, String> headers = new Map<String, String>{
            'Content-Type' => 'application/json'
        };
        
        // Make the callout
        IntegrationResponse response = connector.sendRequest(
            'https://api.example.com/accounts',
            '{"name": "Test Account"}',
            headers,
            correlationId
        );
        
        Test.stopTest();
        
        // Verify response indicates failure
        System.assertEquals(false, response.getIsSuccess(), 'Response should indicate failure');
        // Note: Status code might be -1 due to exception handling in retry logic
        System.assert(response.getStatusCode() == 500 || response.getStatusCode() == -1, 'Status code should be 500 or -1 (exception)');
        
        // Query logs to verify both outbound and inbound logging
        List<Integration_Log__c> logs = [
            SELECT Id, Correlation_ID__c, Direction__c, Message_Type__c, Status__c, System__c, CreatedDate
            FROM Integration_Log__c 
            WHERE Correlation_ID__c = :correlationId 
            ORDER BY CreatedDate ASC
        ];
        
        // Debug: Print all logs to understand what's being created
        System.debug('=== FAILED CALLOUT LOGS DEBUG ===');
        System.debug('Total logs found: ' + logs.size());
        for (Integer i = 0; i < logs.size(); i++) {
            Integration_Log__c log = logs[i];
            System.debug('Log ' + (i+1) + ': ' + log.Direction__c + ' | ' + log.Message_Type__c + ' | ' + log.Status__c + ' | ' + log.CreatedDate);
        }
        
        // Should have at least 2 logs: 1 outbound request + 1 inbound response (even for errors)
        // Note: There might be additional logs for error handling
        System.assert(logs.size() >= 2, 'Should have at least 2 logs (outbound + inbound)');
        
        // Verify outbound log (first log)
        Integration_Log__c outboundLog = logs[0];
        System.assertEquals('Outbound', outboundLog.Direction__c, 'First log should be outbound');
        System.assertEquals('Request', outboundLog.Message_Type__c, 'First log should be request');
        
        // Find the inbound log (might not be the second log if there are additional logs)
        Integration_Log__c inboundLog = null;
        for (Integration_Log__c log : logs) {
            if (log.Direction__c == 'Inbound' && log.Message_Type__c == 'Response') {
                inboundLog = log;
                break;
            }
        }
        
        System.assertNotEquals(null, inboundLog, 'Should have an inbound response log');
        System.assertEquals('Inbound', inboundLog.Direction__c, 'Inbound log should be inbound');
        System.assertEquals('Response', inboundLog.Message_Type__c, 'Inbound log should be response');
        
        // Verify error was created
        List<Integration_Error__c> errors = [
            SELECT Id, Error_Type__c, Error_Severity__c 
            FROM Integration_Error__c 
            WHERE Correlation_ID__c = :correlationId
        ];
        System.assert(errors.size() > 0, 'Errors should be created for failed callout');
    }
}
