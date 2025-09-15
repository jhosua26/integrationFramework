/**
 * @description Integration Framework - Version 8
 * @author Jhosua R. Arda
 * @version 8.0
 * @purpose This framework is being used in Accenture projects and freelancing work.
 *          DO NOT MODIFY this class as it is part of the framework.
 *          Modifying this class will destroy the framework functionality.
 * 
 * Test class for RetryResult
 * 
 * IMPORTANT: DO NOT REMOVE existing test methods. Only add new test methods to maintain
 *            high test coverage. Removing existing methods will reduce test coverage.
 */
@IsTest
private class RetryResultTest {
    
    @IsTest
    static void testSuccessConstructor() {
        Boolean isSuccess = true;
        String result = 'Success result';
        Integer retryCount = 0;
        Long totalProcessingTime = 1500L;
        Exception lastException = null;
        
        Test.startTest();
        RetryResult retryResult = new RetryResult(
            isSuccess,
            result,
            retryCount,
            totalProcessingTime,
            lastException
        );
        Test.stopTest();
        
        System.assertEquals(true, retryResult.getIsSuccess(), 'Should be successful');
        System.assertEquals(result, retryResult.getResult(), 'Should return correct result');
        System.assertEquals(retryCount, retryResult.getRetryCount(), 'Should return correct retry count');
        System.assertEquals(totalProcessingTime, retryResult.getTotalProcessingTime(), 'Should return correct processing time');
        System.assertEquals(lastException, retryResult.getLastException(), 'Should return null exception');
    }
    
    @IsTest
    static void testFailureConstructor() {
        Boolean isSuccess = false;
        String result = null;
        Integer retryCount = 3;
        Long totalProcessingTime = 5000L;
        Exception lastException = new CalloutException('Connection timeout');
        
        Test.startTest();
        RetryResult retryResult = new RetryResult(
            isSuccess,
            result,
            retryCount,
            totalProcessingTime,
            lastException
        );
        Test.stopTest();
        
        System.assertEquals(false, retryResult.getIsSuccess(), 'Should not be successful');
        System.assertEquals(result, retryResult.getResult(), 'Should return null result');
        System.assertEquals(retryCount, retryResult.getRetryCount(), 'Should return correct retry count');
        System.assertEquals(totalProcessingTime, retryResult.getTotalProcessingTime(), 'Should return correct processing time');
        System.assertEquals(lastException, retryResult.getLastException(), 'Should return correct exception');
    }
    
    @IsTest
    static void testGetResultAs() {
        Boolean isSuccess = true;
        String result = '{"id": "12345", "name": "Test"}';
        Integer retryCount = 0;
        Long totalProcessingTime = 1000L;
        Exception lastException = null;
        
        RetryResult retryResult = new RetryResult(
            isSuccess,
            result,
            retryCount,
            totalProcessingTime,
            lastException
        );
        
        Test.startTest();
        String stringResult = (String) retryResult.getResultAs(String.class);
        Test.stopTest();
        
        System.assertEquals(result, stringResult, 'Should return result as string');
    }
    
    @IsTest
    static void testGetResultAsWithNullResult() {
        Boolean isSuccess = false;
        String result = null;
        Integer retryCount = 1;
        Long totalProcessingTime = 2000L;
        Exception lastException = new CalloutException('Test exception');
        
        RetryResult retryResult = new RetryResult(
            isSuccess,
            result,
            retryCount,
            totalProcessingTime,
            lastException
        );
        
        Test.startTest();
        String stringResult = (String) retryResult.getResultAs(String.class);
        Test.stopTest();
        
        System.assertEquals(null, stringResult, 'Should return null for null result');
    }
    
    @IsTest
    static void testGetErrorMessage() {
        Boolean isSuccess = false;
        String result = null;
        Integer retryCount = 2;
        Long totalProcessingTime = 3000L;
        Exception lastException = new CalloutException('Connection failed');
        
        RetryResult retryResult = new RetryResult(
            isSuccess,
            result,
            retryCount,
            totalProcessingTime,
            lastException
        );
        
        Test.startTest();
        String errorMessage = retryResult.getErrorMessage();
        Test.stopTest();
        
        System.assertEquals('Connection failed', errorMessage, 'Should return correct error message');
    }
    
    @IsTest
    static void testGetErrorMessageWithNullException() {
        Boolean isSuccess = true;
        String result = 'Success';
        Integer retryCount = 0;
        Long totalProcessingTime = 1000L;
        Exception lastException = null;
        
        RetryResult retryResult = new RetryResult(
            isSuccess,
            result,
            retryCount,
            totalProcessingTime,
            lastException
        );
        
        Test.startTest();
        String errorMessage = retryResult.getErrorMessage();
        Test.stopTest();
        
        System.assertEquals(null, errorMessage, 'Should return null when no exception');
    }
    
    @IsTest
    static void testGetStackTrace() {
        Boolean isSuccess = false;
        String result = null;
        Integer retryCount = 1;
        Long totalProcessingTime = 2000L;
        Exception lastException = new CalloutException('Test exception');
        
        RetryResult retryResult = new RetryResult(
            isSuccess,
            result,
            retryCount,
            totalProcessingTime,
            lastException
        );
        
        Test.startTest();
        String stackTrace = retryResult.getStackTrace();
        Test.stopTest();
        
        System.assertNotEquals(null, stackTrace, 'Should return stack trace');
        System.assert(stackTrace.length() > 0, 'Should have non-empty stack trace');
    }
    
    @IsTest
    static void testGetStackTraceWithNullException() {
        Boolean isSuccess = true;
        String result = 'Success';
        Integer retryCount = 0;
        Long totalProcessingTime = 1000L;
        Exception lastException = null;
        
        RetryResult retryResult = new RetryResult(
            isSuccess,
            result,
            retryCount,
            totalProcessingTime,
            lastException
        );
        
        Test.startTest();
        String stackTrace = retryResult.getStackTrace();
        Test.stopTest();
        
        System.assertEquals('No stack trace available', stackTrace, 'Should return default stack trace');
    }
    
    @IsTest
    static void testWasRetried() {
        Boolean isSuccess = true;
        String result = 'Success';
        Integer retryCount = 0;
        Long totalProcessingTime = 1000L;
        Exception lastException = null;
        
        RetryResult retryResult = new RetryResult(
            isSuccess,
            result,
            retryCount,
            totalProcessingTime,
            lastException
        );
        
        Test.startTest();
        Boolean wasRetried = retryResult.wasRetried();
        Test.stopTest();
        
        System.assertEquals(false, wasRetried, 'Should not be retried with count 0');
    }
    
    @IsTest
    static void testWasRetriedWithRetries() {
        Boolean isSuccess = true;
        String result = 'Success after retry';
        Integer retryCount = 2;
        Long totalProcessingTime = 3000L;
        Exception lastException = null;
        
        RetryResult retryResult = new RetryResult(
            isSuccess,
            result,
            retryCount,
            totalProcessingTime,
            lastException
        );
        
        Test.startTest();
        Boolean wasRetried = retryResult.wasRetried();
        Test.stopTest();
        
        System.assertEquals(true, wasRetried, 'Should be retried with count > 0');
    }
    
    @IsTest
    static void testGetSummary() {
        Boolean isSuccess = true;
        String result = 'Success result';
        Integer retryCount = 1;
        Long totalProcessingTime = 2000L;
        Exception lastException = null;
        
        RetryResult retryResult = new RetryResult(
            isSuccess,
            result,
            retryCount,
            totalProcessingTime,
            lastException
        );
        
        Test.startTest();
        String summary = retryResult.getSummary();
        Test.stopTest();
        
        System.assertNotEquals(null, summary, 'Should return summary');
        System.assert(summary.contains('successfully'), 'Should contain success status');
        System.assert(summary.contains('1'), 'Should contain retry count');
        System.assert(summary.contains('2000'), 'Should contain processing time');
    }
    
    @IsTest
    static void testGetSummaryWithFailure() {
        Boolean isSuccess = false;
        String result = null;
        Integer retryCount = 3;
        Long totalProcessingTime = 5000L;
        Exception lastException = new CalloutException('Connection timeout');
        
        RetryResult retryResult = new RetryResult(
            isSuccess,
            result,
            retryCount,
            totalProcessingTime,
            lastException
        );
        
        Test.startTest();
        String summary = retryResult.getSummary();
        Test.stopTest();
        
        System.assertNotEquals(null, summary, 'Should return summary');
        System.assert(summary.contains('failed'), 'Should contain failure status');
        System.assert(summary.contains('3'), 'Should contain retry count');
        System.assert(summary.contains('5000'), 'Should contain processing time');
        System.assert(summary.contains('Connection timeout'), 'Should contain error message');
    }
    
    @IsTest
    static void testEdgeCases() {
        // Test with zero processing time
        RetryResult zeroTime = new RetryResult(true, 'Success', 0, 0L, null);
        System.assertEquals(0L, zeroTime.getTotalProcessingTime(), 'Should handle zero processing time');
        
        // Test with negative processing time
        RetryResult negativeTime = new RetryResult(true, 'Success', 0, -100L, null);
        System.assertEquals(-100L, negativeTime.getTotalProcessingTime(), 'Should handle negative processing time');
        
        // Test with large retry count
        RetryResult largeRetry = new RetryResult(false, null, 100, 10000L, new CalloutException('Max retries'));
        System.assertEquals(100, largeRetry.getRetryCount(), 'Should handle large retry count');
        System.assertEquals(true, largeRetry.wasRetried(), 'Should indicate retries were performed');
        
        // Test with empty string result
        RetryResult emptyResult = new RetryResult(true, '', 0, 1000L, null);
        System.assertEquals('', emptyResult.getResult(), 'Should handle empty string result');
    }
    
    @IsTest
    static void testVariousExceptionTypes() {
        // Test CalloutException
        Exception calloutEx = new CalloutException('Callout failed');
        RetryResult calloutResult = new RetryResult(false, null, 1, 2000L, calloutEx);
        System.assertEquals('Callout failed', calloutResult.getErrorMessage(), 'Should handle CalloutException');
        
        // Test DmlException
        Exception dmlEx = new DmlException('DML failed');
        RetryResult dmlResult = new RetryResult(false, null, 1, 2000L, dmlEx);
        System.assertEquals('DML failed', dmlResult.getErrorMessage(), 'Should handle DmlException');
        
        // Test QueryException
        Exception queryEx = new QueryException('Query failed');
        RetryResult queryResult = new RetryResult(false, null, 1, 2000L, queryEx);
        System.assertEquals('Query failed', queryResult.getErrorMessage(), 'Should handle QueryException');
        
        // Test generic Exception
        CalloutException genericEx = new CalloutException('Generic error');
        RetryResult genericResult = new RetryResult(false, null, 1, 2000L, genericEx);
        System.assertEquals('Generic error', genericResult.getErrorMessage(), 'Should handle generic Exception');
    }
}
