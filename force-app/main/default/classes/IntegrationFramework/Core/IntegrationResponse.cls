/**
 * @description Integration Framework - Version 8
 * @author Jhosua R. Arda
 * @version 8.0
 * @purpose This framework is being used in Accenture projects and freelancing work.
 *          DO NOT MODIFY this class as it is part of the framework.
 *          Modifying this class will destroy the framework functionality.
 * 
 * Wrapper class for integration responses
 */
public class IntegrationResponse {
    
    @TestVisible
    private Boolean isSuccess;
    @TestVisible
    private String responseBody;
    @TestVisible
    private Integer statusCode;
    @TestVisible
    private Map<String, String> headers;
    @TestVisible
    private String errorMessage;
    @TestVisible
    private String correlationId;
    @TestVisible
    private Long processingTimeMs;
    @TestVisible
    private Map<String, Object> metadata;
    
    /**
     * Creates a successful response object
     * 
     * responseBody - The response body from the external system
     * statusCode - HTTP status code (200, 201, etc.)
     * headers - Response headers from the external system
     * correlationId - Unique identifier for tracking this request
     * processingTimeMs - How long the request took in milliseconds
     */
    public IntegrationResponse(String responseBody, Integer statusCode, Map<String, String> headers, 
                              String correlationId, Long processingTimeMs) {
        this.isSuccess = true;
        this.responseBody = responseBody;
        this.statusCode = statusCode;
        this.headers = headers != null ? headers : new Map<String, String>();
        this.correlationId = correlationId;
        this.processingTimeMs = processingTimeMs;
        this.metadata = new Map<String, Object>();
    }
    
    /**
     * Constructor for error responses
     * 
     * errorMessage - Error message describing what went wrong
     * statusCode - HTTP status code (if available from the external system)
     * correlationId - Unique identifier for tracking this request
     * processingTimeMs - Processing time in milliseconds
     */
    public IntegrationResponse(String errorMessage, Integer statusCode, String correlationId, Long processingTimeMs) {
        this.isSuccess = false;
        this.responseBody = errorMessage; // Set responseBody to errorMessage for consistency
        this.errorMessage = errorMessage;
        this.statusCode = statusCode;
        this.correlationId = correlationId;
        this.processingTimeMs = processingTimeMs;
        this.headers = new Map<String, String>();
        this.metadata = new Map<String, Object>();
    }
    
    // Getters
    public Boolean getIsSuccess() { return this.isSuccess; }
    public String getResponseBody() { return this.responseBody; }
    public Integer getStatusCode() { return this.statusCode; }
    public Map<String, String> getHeaders() { return this.headers; }
    public String getErrorMessage() { return this.errorMessage; }
    public String getCorrelationId() { return this.correlationId; }
    public Long getProcessingTimeMs() { return this.processingTimeMs; }
    public Map<String, Object> getMetadata() { return this.metadata; }
    
    /**
     * Adds metadata to the response
     * 
     * key - Metadata key for storing additional information
     * value - Metadata value (can be any object type)
     */
    public void addMetadata(String key, Object value) {
        if (this.metadata == null) {
            this.metadata = new Map<String, Object>();
        }
        this.metadata.put(key, value);
    }
    
    /**
     * Checks if the response indicates a retryable error
     * 
     * Returns true if the error is retryable (5xx server errors, timeouts, rate limits).
     * Returns false for client errors (4xx) or successful responses.
     */
    public Boolean isRetryableError() {
        if (this.isSuccess) return false;
        
        // Retryable HTTP status codes
        Set<Integer> retryableStatusCodes = new Set<Integer>{408, 429, 500, 502, 503, 504};
        
        return this.statusCode != null && retryableStatusCodes.contains(this.statusCode);
    }
}