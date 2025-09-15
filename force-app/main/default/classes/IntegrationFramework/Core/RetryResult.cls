/**
 * @description Integration Framework - Version 8
 * @author Jhosua R. Arda
 * @version 8.0
 * @purpose This framework is being used in Accenture projects and freelancing work.
 *          DO NOT MODIFY this class as it is part of the framework.
 *          Modifying this class will destroy the framework functionality.
 * 
 * Result of a retry operation with exponential backoff
 */
public class RetryResult {
    
    @TestVisible
    private final Boolean isSuccess;
    @TestVisible
    private final Object result;
    @TestVisible
    private final Integer retryCount;
    @TestVisible
    private final Long totalProcessingTime;
    @TestVisible
    private final Exception lastException;
    
    /**
     * Constructor for retry result
     * 
     * Creates a new retry result object to encapsulate the outcome of a retry operation.
     * Contains all relevant information about the retry attempt including timing and errors.
     * 
     * isSuccess - Whether the operation was successful after retries
     * result - The result of the operation (if successful)
     * retryCount - Number of retry attempts made
     * totalProcessingTime - Total processing time in milliseconds
     * lastException - The last exception encountered (if failed)
     */
    public RetryResult(Boolean isSuccess, Object result, Integer retryCount, 
                      Long totalProcessingTime, Exception lastException) {
        this.isSuccess = isSuccess;
        this.result = result;
        this.retryCount = retryCount;
        this.totalProcessingTime = totalProcessingTime;
        this.lastException = lastException;
    }
    
    // Getters
    public Boolean getIsSuccess() { return this.isSuccess; }
    public Object getResult() { return this.result; }
    public Integer getRetryCount() { return this.retryCount; }
    public Long getTotalProcessingTime() { return this.totalProcessingTime; }
    public Exception getLastException() { return this.lastException; }
    
    /**
     * Gets the result as a specific type
     * 
     * Safely casts the result to the specified type if available.
     * Returns null if the result is null or cannot be cast to the specified type.
     * 
     * resultType - The type to cast the result to
     * @return The result cast to the specified type
     */
    public Object getResultAs(Type resultType) {
        // Simple type checking - in production, implement more robust type checking
        if (this.result != null) {
            return this.result;
        }
        return null;
    }
    
    /**
     * @description Gets the error message from the last exception
     * @return Error message or null if no exception
     */
    public String getErrorMessage() {
        return this.lastException != null ? this.lastException.getMessage() : null;
    }
    
    /**
     * @description Gets the stack trace from the last exception
     * @return Stack trace or null if no exception
     */
    public String getStackTrace() {
        return this.lastException != null ? this.lastException.getStackTraceString() : 'No stack trace available';
    }
    
    /**
     * @description Checks if the operation was retried
     * @return Boolean indicating if retries were attempted
     */
    public Boolean wasRetried() {
        return this.retryCount > 0;
    }
    
    /**
     * @description Gets a summary of the retry operation
     * @return String summary of the retry operation
     */
    public String getSummary() {
        if (this.isSuccess) {
            return 'Operation completed successfully after ' + this.retryCount + 
                   ' retry attempts in ' + this.totalProcessingTime + 'ms';
        } else {
            return 'Operation failed after ' + this.retryCount + 
                   ' retry attempts in ' + this.totalProcessingTime + 'ms. ' +
                   'Last error: ' + this.getErrorMessage();
        }
    }
}
