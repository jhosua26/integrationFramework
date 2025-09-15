/**
 * @description Integration Framework - Version 8
 * @author Jhosua R. Arda
 * @version 8.0
 * @purpose This framework is being used in Accenture projects and freelancing work.
 *          DO NOT MODIFY this class as it is part of the framework.
 *          Modifying this class will destroy the framework functionality.
 * 
 * HTTP request operation that can be retried with exponential backoff
 */
public class HttpRequestOperation implements RetryableOperation {
    
    private final String endpoint;
    private final String payload;
    private final Map<String, String> headers;
    private final RESTConnector connector;
    private final String httpMethod;
    private String correlationId;
    private final Boolean isRetry;
    
    /**
     * Constructor for HTTP request operation
     * 
     * Creates a new HTTP request operation that can be executed and retried.
     * Defaults to POST method and first attempt (not a retry).
     * 
     * endpoint - The endpoint URL to send the request to
     * payload - The request payload (JSON, XML, etc.)
     * headers - Request headers (optional - named credentials handle auth)
     * connector - The REST connector instance to use
     * correlationId - Unique identifier for tracking this request
     */
    public HttpRequestOperation(String endpoint, String payload, Map<String, String> headers, RESTConnector connector, String correlationId) {
        this(endpoint, payload, headers, connector, correlationId, 'POST', false);
    }
    
    /**
     * Constructor for HTTP request operation with method and retry flag
     * 
     * Creates a new HTTP request operation with full control over method and retry behavior.
     * Used internally by the retry mechanism for subsequent attempts.
     * 
     * endpoint - The endpoint URL to send the request to
     * payload - The request payload (JSON, XML, etc.)
     * headers - Request headers (optional - named credentials handle auth)
     * connector - The REST connector instance to use
     * correlationId - Unique identifier for tracking this request
     * httpMethod - HTTP method (GET, POST, PUT, PATCH, DELETE)
     * isRetry - Boolean indicating if this is a retry attempt
     */
    public HttpRequestOperation(String endpoint, String payload, Map<String, String> headers, RESTConnector connector, String correlationId, String httpMethod, Boolean isRetry) {
        if (String.isBlank(endpoint)) {
            throw new IllegalArgumentException('Endpoint cannot be null or empty');
        }
        
        if (connector == null) {
            throw new IllegalArgumentException('Connector cannot be null');
        }
        
        if (String.isBlank(httpMethod)) {
            throw new IllegalArgumentException('HTTP method cannot be null or empty');
        }
        
        // Headers are optional - named credentials handle authentication
        
        this.endpoint = endpoint;
        this.payload = payload;
        this.headers = headers;
        this.connector = connector;
        this.httpMethod = httpMethod.toUpperCase();
        this.correlationId = correlationId;
        this.isRetry = isRetry != null ? isRetry : false;
    }
    
    /**
     * @description Executes the HTTP request operation
     * @return IntegrationResponse containing the response data
     */
    public Object execute() {
        // Use the correlation ID passed from the constructor
        // This ensures all retry attempts use the same correlation ID
        if (String.isBlank(this.correlationId)) {
            this.correlationId = CorrelationIdGenerator.generateCorrelationId();
        }
        
        Long startTime = System.currentTimeMillis();
        HttpResponse response = null;
        Exception calloutException = null;
        
        try {
            // Prepare and send request FIRST (no DML operations before callout)
            HttpRequest request = prepareHttpRequest(endpoint, payload, headers, httpMethod);
            Http http = new Http();
            response = http.send(request);
            
        } catch (Exception e) {
            // Capture exception but don't log yet (avoid DML before callout)
            calloutException = e;
        }
        
        Long processingTime = System.currentTimeMillis() - startTime;
        
        // NOW we can do all DML operations (after callout)
        try {
            // Log outbound message (after callout)
            logOutboundMessage(this.correlationId, processingTime);
            
            if (calloutException != null) {
                // Log error after callout failure
                logError(this.correlationId, calloutException, processingTime);
                
                // Re-throw the exception for retry logic
                throw calloutException;
            }
            
            // Extract response headers
            Map<String, String> responseHeaders = extractResponseHeaders(response);
            
            // Log inbound message (after callout)
            logInboundMessage(this.correlationId, response, processingTime);
            
            // Create response object based on HTTP status code
            IntegrationResponse integrationResponse;
            if (response.getStatusCode() >= 200 && response.getStatusCode() < 300) {
                // Success response
                integrationResponse = new IntegrationResponse(
                    response.getBody(),
                    response.getStatusCode(),
                    responseHeaders,
                    this.correlationId,
                    processingTime
                );
            } else {
                // Error response - log error for HTTP error status codes
                String errorMessage = 'HTTP ' + response.getStatusCode() + ' error: ' + response.getBody();
                
                // Create error record for HTTP error status codes
                logHttpError(this.correlationId, response, processingTime);
                
                // For HTTP errors, throw an exception to trigger retry logic
                // Only throw for retryable errors (5xx, 429, etc.)
                if (response.getStatusCode() >= 500 || response.getStatusCode() == 429) {
                    throw new CalloutException(errorMessage);
                }
                
                // For non-retryable errors (4xx), return error response
                integrationResponse = new IntegrationResponse(
                    errorMessage,
                    response.getStatusCode(),
                    this.correlationId,
                    processingTime
                );
            }
            
            return integrationResponse;
            
        } catch (Exception e) {
            // Handle logging exceptions
            System.debug(LoggingLevel.ERROR, 'Failed to process callout result: ' + e.getMessage());
            
            // Re-throw the original callout exception if it exists
            if (calloutException != null) {
                throw calloutException;
            }
            
            // Otherwise re-throw the logging exception
            throw e;
        }
    }
    
    /**
     * @description Logs the outbound request message
     * @param correlationId Unique identifier for tracking
     * @param processingTime Processing time in milliseconds
     */
    private void logOutboundMessage(String correlationId, Long processingTime) {
        try {
            // Skip logging if this is a retry attempt (RetryQueueable will handle logging)
            if (isRetryAttempt()) {
                return;
            }
            
            Map<String, Object> context = new Map<String, Object>{
                'endpoint' => endpoint,
                'method' => httpMethod,
                'headers' => headers != null ? headers : new Map<String, String>(),
                'usesNamedCredential' => headers == null || headers.isEmpty(),
                'retryCount' => isRetryAttempt() ? 1 : 0,
                'processingTime' => processingTime
            };
            
            connector.getLogger().logOutboundMessage(
                correlationId,
                connector.getSystemName(),
                payload,
                context
            );
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to log outbound message: ' + e.getMessage());
        }
    }
    
    /**
     * @description Logs the inbound response message
     * @param correlationId Unique identifier for tracking
     * @param response HTTP response
     * @param processingTime Processing time in milliseconds
     */
    private void logInboundMessage(String correlationId, HttpResponse response, Long processingTime) {
        try {
            // Skip logging if this is a retry attempt (RetryQueueable will handle logging)
            if (isRetryAttempt()) {
                return;
            }
            
            Map<String, Object> context = new Map<String, Object>{
                'statusCode' => response.getStatusCode(),
                'processingTime' => processingTime,
                'responseHeaders' => extractResponseHeaders(response),
                'success' => response.getStatusCode() >= 200 && response.getStatusCode() < 300
            };
            
            connector.getLogger().logInboundMessage(
                correlationId,
                connector.getSystemName(),
                response.getBody(),
                context
            );
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to log inbound message: ' + e.getMessage());
        }
    }
    
    /**
     * @description Check if this is a retry attempt
     * @return Boolean indicating if this is a retry attempt
     */
    private Boolean isRetryAttempt() {
        return this.isRetry;
    }
    
    /**
     * @description Logs error information for exceptions
     * @param correlationId Unique identifier for tracking
     * @param ex The exception that occurred
     * @param processingTime Processing time in milliseconds
     */
    private void logError(String correlationId, Exception ex, Long processingTime) {
        try {
            // Skip error logging if this is a retry attempt (RetryQueueable will handle error logging)
            if (isRetryAttempt()) {
                return;
            }
            
            Map<String, Object> context = new Map<String, Object>{
                'endpoint' => endpoint,
                'processingTime' => processingTime,
                'exceptionType' => ex.getTypeName(),
                'systemName' => connector.getSystemName(),
                'payload' => payload,
                'headers' => headers != null ? headers : new Map<String, String>()
            };
            
            connector.getLogger().logError(
                correlationId,
                'HTTP_CALLOUT_ERROR',
                'HTTP callout failed: ' + ex.getMessage(),
                ex.getStackTraceString(),
                'HIGH',
                context
            );
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to log error: ' + e.getMessage());
        }
    }
    
    /**
     * @description Logs error information for HTTP error status codes
     * @param correlationId Unique identifier for tracking
     * @param response HTTP response with error status code
     * @param processingTime Processing time in milliseconds
     */
    private void logHttpError(String correlationId, HttpResponse response, Long processingTime) {
        try {
            // Skip error logging if this is a retry attempt (RetryQueueable will handle error logging)
            if (isRetryAttempt()) {
                return;
            }
            
            Map<String, Object> context = new Map<String, Object>{
                'endpoint' => endpoint,
                'processingTime' => processingTime,
                'statusCode' => response.getStatusCode(),
                'responseHeaders' => extractResponseHeaders(response),
                'systemName' => connector.getSystemName(),
                'payload' => payload,
                'headers' => headers != null ? headers : new Map<String, String>()
            };
            
            String severity = response.getStatusCode() >= 500 ? 'HIGH' : 'MEDIUM';
            String errorMessage = 'HTTP ' + response.getStatusCode() + ' error: ' + response.getBody();
            
            connector.getLogger().logError(
                correlationId,
                'HTTP_CALLOUT_ERROR',
                errorMessage,
                'HTTP Error: Status ' + response.getStatusCode() + ' returned from endpoint: ' + endpoint,
                severity,
                context
            );
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to log HTTP error: ' + e.getMessage());
        }
    }
    
    /**
     * @description Extracts response headers from HttpResponse
     * @param response HTTP response
     * @return Map of response headers
     */
    private Map<String, String> extractResponseHeaders(HttpResponse response) {
        Map<String, String> headers = new Map<String, String>();
        
        if (response != null) {
            // Get all header keys
            List<String> headerKeys = response.getHeaderKeys();
            if (headerKeys != null) {
                for (String key : headerKeys) {
                    String value = response.getHeader(key);
                    if (value != null) {
                        headers.put(key, value);
                    }
                }
            }
        }
        
        return headers;
    }
    
    /**
     * @description Prepares an HTTP request with the given parameters
     * @param endpoint The endpoint URL
     * @param payload The request payload
     * @param headers Request headers (optional - named credentials handle auth)
     * @param method HTTP method (GET, POST, PUT, PATCH, DELETE)
     * @return HttpRequest prepared request
     */
    private HttpRequest prepareHttpRequest(String endpoint, String payload, Map<String, String> headers, String method) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod(method);
        request.setTimeout(connector.getTimeoutMs());
        
        // Only set body for methods that support it
        if (!String.isBlank(payload) && (method == 'POST' || method == 'PUT' || method == 'PATCH')) {
            request.setBody(payload);
        }
        
        // Add custom headers (only if provided and not using named credentials)
        if (headers != null && !headers.isEmpty()) {
            for (String key : headers.keySet()) {
                request.setHeader(key, headers.get(key));
            }
        }
        
        return request;
    }
}
