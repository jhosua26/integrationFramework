/**
 * @description Integration Framework - Version 8
 * @author Jhosua R. Arda
 * @version 8.0
 * @purpose This framework is being used in Accenture projects and freelancing work.
 *          DO NOT MODIFY this class as it is part of the framework.
 *          Modifying this class will destroy the framework functionality.
 * 
 * REST connector implementation for HTTP-based integrations
 */
public virtual class RESTConnector implements IIntegrationConnector {
    
    private final IIntegrationLogger logger;
    private final String systemName;
    private final Integer timeoutMs;
    private final Map<String, String> defaultHeaders;
    private final RetryManager retryManager; // Only for outbound requests
    private final FrameworkErrorHandler errorHandler;
    private String currentCorrelationId;
    
    /**
     * Constructor with dependency injection
     * 
     * logger - Logger implementation for tracking requests and responses
     * systemName - Name of the external system this connector handles
     * timeoutMs - Request timeout in milliseconds (defaults to 30 seconds)
     * defaultHeaders - Default headers to include in all requests
     */
    public RESTConnector(IIntegrationLogger logger, String systemName, Integer timeoutMs, Map<String, String> defaultHeaders) {
        if (logger == null) {
            throw new IllegalArgumentException('Logger cannot be null');
        }
        
        if (String.isBlank(systemName)) {
            throw new IllegalArgumentException('System name cannot be null or empty');
        }
        
        this.logger = logger;
        this.systemName = systemName;
        this.timeoutMs = timeoutMs != null ? timeoutMs : 30000; // Default 30 seconds
        this.defaultHeaders = defaultHeaders != null ? defaultHeaders : new Map<String, String>();
        this.errorHandler = new FrameworkErrorHandler(logger);
        this.retryManager = new RetryManager(logger, this.errorHandler, 3, 1000); // Framework retry with error handler
    }
    
    /**
     * Sends a request to the external system
     * 
     * Handles the complete outbound integration flow including logging, retry logic, and error handling.
     * Uses RetryManager for automatic retries on retryable errors.
     * 
     * endpoint - The endpoint URL to send the request to
     * payload - The request payload (JSON, XML, etc.)
     * correlationId - Unique identifier for tracking this request
     * Returns IntegrationResponse with success status and response data
     */
    public IntegrationResponse sendRequest(String endpoint, String payload, String correlationId) {
        return sendRequest(endpoint, payload, null, correlationId);
    }
    
    /**
     * Sends a request to the external system with optional headers
     * 
     * Convenience method that defaults to POST method.
     * Uses named credentials for authentication (headers are optional).
     * 
     * endpoint - The endpoint URL to send the request to
     * payload - The request payload (JSON, XML, etc.)
     * headers - Request headers (optional - named credentials handle auth)
     * correlationId - Unique identifier for tracking this request
     * Returns IntegrationResponse with success status and response data
     */
    public IntegrationResponse sendRequest(String endpoint, String payload, Map<String, String> headers, String correlationId) {
        return sendRequest(endpoint, payload, headers, 'POST', correlationId);
    }
    
    /**
     * Sends a request to the external system with method and optional headers
     * 
     * Main method for sending HTTP requests with full control over method and headers.
     * Includes automatic retry logic and comprehensive error handling.
     * 
     * endpoint - The endpoint URL to send the request to
     * payload - The request payload (JSON, XML, etc.)
     * headers - Request headers (optional - named credentials handle auth)
     * method - HTTP method (GET, POST, PUT, PATCH, DELETE)
     * correlationId - Unique identifier for tracking this request
     * @return IntegrationResponse containing the response data
     */
    public IntegrationResponse sendRequest(String endpoint, String payload, Map<String, String> headers, String method, String correlationId) {
        if (String.isBlank(endpoint)) {
            throw new IllegalArgumentException('Endpoint cannot be null or empty');
        }
        
        if (String.isBlank(correlationId)) {
            throw new IllegalArgumentException('Correlation ID cannot be null or empty');
        }
        
        if (String.isBlank(method)) {
            throw new IllegalArgumentException('HTTP method cannot be null or empty');
        }
        
        // Validate HTTP method
        String upperMethod = method.toUpperCase();
        if (!isValidHttpMethod(upperMethod)) {
            throw new IllegalArgumentException('Invalid HTTP method: ' + method + '. Supported methods: GET, POST, PUT, PATCH, DELETE');
        }
        
        // Set the correlation ID for this request
        this.currentCorrelationId = correlationId;
        
        // Create retryable operation
        RetryableOperation httpOperation = new HttpRequestOperation(endpoint, payload, headers, this, correlationId, upperMethod, false);
        
        // Execute with retry logic
        Map<String, Object> context = new Map<String, Object>{
            'endpoint' => endpoint,
            'method' => upperMethod,
            'payload' => payload,
            'headers' => headers != null ? headers : new Map<String, String>(),
            'usesNamedCredential' => headers == null || headers.isEmpty()
        };
        
        RetryResult retryResult = retryManager.executeWithRetry(httpOperation, correlationId, systemName, context);
        
        if (retryResult.getIsSuccess()) {
            return (IntegrationResponse) retryResult.getResult();
        } else {
            // Return error response with retry information
            String errorMessage = retryResult.getErrorMessage();
            if (retryResult.wasRetried()) {
                errorMessage += ' (Retried ' + retryResult.getRetryCount() + ' times)';
            }
            
            return new IntegrationResponse(
                errorMessage,
                -1,
                correlationId,
                retryResult.getTotalProcessingTime()
            );
        }
    }
    
    
    /**
     * Validates the connector configuration
     * 
     * Checks that all required components are properly configured.
     * 
     * Returns true if configuration is valid, false otherwise
     */
    public Boolean validateConfiguration() {
        return logger != null && !String.isBlank(systemName) && timeoutMs > 0;
    }
    
    /**
     * Gets the connector type
     * 
     * Returns the type of connector for identification and configuration purposes.
     * 
     * Returns 'REST' as the connector type
     */
    public String getConnectorType() {
        return 'REST';
    }
    
    /**
     * Gets the logger instance
     * 
     * Returns the logger instance used by this connector for tracking and debugging.
     * 
     * Returns IIntegrationLogger instance
     */
    public IIntegrationLogger getLogger() {
        return this.logger;
    }
    
    /**
     * @description Gets the system name
     * @return String system name
     */
    public String getSystemName() {
        return this.systemName;
    }
    
    /**
     * @description Receives a response from the external system
     * @param correlationId Unique identifier for tracking
     * @return IntegrationResponse containing the response data
     */
    public IntegrationResponse receiveResponse(String correlationId) {
        // REST connectors use request-response pattern, not message-based
        // This method is not applicable for REST connectors
        throw new UnsupportedOperationException('REST connectors do not support receiveResponse. Use sendRequest for request-response pattern.');
    }
    
    
    
    /**
     * @description Gets the timeout in milliseconds
     * @return Timeout in milliseconds
     */
    public Integer getTimeoutMs() {
        return this.timeoutMs;
    }
    
    
    /**
     * @description Validates if the HTTP method is supported
     * @param method HTTP method to validate
     * @return Boolean indicating if method is valid
     */
    private Boolean isValidHttpMethod(String method) {
        Set<String> validMethods = new Set<String>{
            'GET', 'POST', 'PUT', 'PATCH', 'DELETE'
        };
        return validMethods.contains(method);
    }
    
    // ========================================
    // INBOUND REQUEST HANDLING METHODS
    // ========================================
    
    /**
     * @description Handles an inbound REST request with framework logging and error handling
     *              NOTE: Inbound requests do NOT use retry logic - external systems control their own retries
     * @param request RestRequest from Salesforce REST API
     * @param httpMethod HTTP method (GET, POST, PUT, PATCH, DELETE)
     * @return IntegrationResponse containing the response data
     */
    public IntegrationResponse handleInboundRequest(RestRequest request, String httpMethod) {
        if (request == null) {
            throw new IllegalArgumentException('RestRequest cannot be null');
        }
        
        if (String.isBlank(httpMethod)) {
            throw new IllegalArgumentException('HTTP method cannot be null or empty');
        }
        
        if (!isValidHttpMethod(httpMethod)) {
            throw new IllegalArgumentException('Unsupported HTTP method: ' + httpMethod);
        }
        
        String correlationId = CorrelationIdGenerator.generateCorrelationId(httpMethod);
        this.currentCorrelationId = correlationId;
        
        // Log inbound request
        logger.logInboundMessage(correlationId, systemName, request.requestBody.toString(), 
                               new Map<String, Object>{
                                   'httpMethod' => httpMethod,
                                   'endpoint' => request.requestURI,
                                   'headers' => request.headers,
                                   'requestSize' => request.requestBody.toString().length()
                               });
        
        try {
            Long startTime = System.currentTimeMillis();
            
            // Process the inbound request based on HTTP method
            IntegrationResponse response = processInboundRequest(request, httpMethod);
            
            Long processingTime = System.currentTimeMillis() - startTime;
            
            // Update inbound log with processing time
            logger.updateLogStatus(correlationId, 'Received', new Map<String, Object>{
                'processingTime' => processingTime
            });
            
            // Log successful response
            logger.logOutboundMessage(correlationId, systemName, response.getResponseBody(), 
                                    new Map<String, Object>{
                                        'httpMethod' => httpMethod,
                                        'statusCode' => response.getStatusCode(),
                                        'processingTime' => processingTime,
                                        'responseSize' => response.getResponseBody() != null ? response.getResponseBody().length() : 0
                                    });
            
            return response;
            
        } catch (Exception e) {
            // Classify the error type automatically
            String errorType = classifyExceptionType(e);
            
            // Handle errors with framework error handling
            errorHandler.logFrameworkError(correlationId, errorType, e.getMessage(), 
                                  e.getStackTraceString(), 'HIGH', 
                                  new Map<String, Object>{
                                      'httpMethod' => httpMethod,
                                      'endpoint' => request.requestURI,
                                      'mode' => 'INBOUND',
                                      'requestBody' => request.requestBody.toString(),
                                      'exceptionType' => e.getTypeName()
                                  });
            
            // Create standardized error response using framework's automatic status code determination
            Map<String, Object> errorResponse = errorHandler.createStandardErrorResponse(
                errorType, 
                e.getMessage(), 
                correlationId,
                new Map<String, Object>{
                    'httpMethod' => httpMethod,
                    'endpoint' => request.requestURI,
                    'exceptionType' => e.getTypeName()
                }
            );
            
            Integer statusCode = (Integer) errorResponse.get('statusCode');
            
            IntegrationResponse errorIntegrationResponse = new IntegrationResponse(
                JSON.serialize(errorResponse),
                statusCode,
                correlationId,
                0
            );
            
            // Log the error response as outbound message
            logger.logOutboundMessage(correlationId, systemName, errorIntegrationResponse.getResponseBody(), 
                                    new Map<String, Object>{
                                        'httpMethod' => httpMethod,
                                        'statusCode' => statusCode,
                                        'processingTime' => 0,
                                        'responseSize' => errorIntegrationResponse.getResponseBody() != null ? errorIntegrationResponse.getResponseBody().length() : 0,
                                        'isErrorResponse' => true,
                                        'errorType' => errorType
                                    });
            
            return errorIntegrationResponse;
        }
    }
    
    /**
     * @description Classify exception type for automatic error handling
     * @param e Exception to classify
     * @return Error type classification
     */
    @TestVisible
    private String classifyExceptionType(Exception e) {
        String exceptionType = e.getTypeName();
        String message = e.getMessage();
        
        // Platform exceptions
        if (exceptionType == 'System.CalloutException') {
            return 'PLATFORM';
        }
        if (exceptionType == 'System.DmlException') {
            return 'DATA';
        }
        if (exceptionType == 'System.QueryException') {
            return 'DATA';
        }
        
        // Message-based classification
        if (String.isNotBlank(message)) {
            String lowerMessage = message.toLowerCase();
            
            if (lowerMessage.contains('unauthorized') || lowerMessage.contains('authentication')) {
                return 'AUTHENTICATION';
            }
            if (lowerMessage.contains('forbidden') || lowerMessage.contains('access denied')) {
                return 'AUTHENTICATION';
            }
            if (lowerMessage.contains('validation') || lowerMessage.contains('invalid') || 
                lowerMessage.contains('missing') || lowerMessage.contains('required')) {
                return 'DATA';
            }
            if (lowerMessage.contains('not found') || lowerMessage.contains('does not exist')) {
                return 'DATA';
            }
            if (lowerMessage.contains('timeout') || lowerMessage.contains('timed out')) {
                return 'TIMEOUT';
            }
            if (lowerMessage.contains('connection') || lowerMessage.contains('network')) {
                return 'NETWORK';
            }
        }
        
        // Default classification
        return 'PLATFORM';
    }
    
    /**
     * @description Handles an inbound GET request
     * @param request RestRequest from Salesforce REST API
     * @return IntegrationResponse containing the response data
     */
    public IntegrationResponse handleInboundGet(RestRequest request) {
        return handleInboundRequest(request, 'GET');
    }
    
    /**
     * @description Handles an inbound POST request
     * @param request RestRequest from Salesforce REST API
     * @return IntegrationResponse containing the response data
     */
    public IntegrationResponse handleInboundPost(RestRequest request) {
        return handleInboundRequest(request, 'POST');
    }
    
    /**
     * @description Handles an inbound PUT request
     * @param request RestRequest from Salesforce REST API
     * @return IntegrationResponse containing the response data
     */
    public IntegrationResponse handleInboundPut(RestRequest request) {
        return handleInboundRequest(request, 'PUT');
    }
    
    /**
     * @description Handles an inbound PATCH request
     * @param request RestRequest from Salesforce REST API
     * @return IntegrationResponse containing the response data
     */
    public IntegrationResponse handleInboundPatch(RestRequest request) {
        return handleInboundRequest(request, 'PATCH');
    }
    
    /**
     * @description Handles an inbound DELETE request
     * @param request RestRequest from Salesforce REST API
     * @return IntegrationResponse containing the response data
     */
    public IntegrationResponse handleInboundDelete(RestRequest request) {
        return handleInboundRequest(request, 'DELETE');
    }
    
    /**
     * @description Processes the actual inbound request logic
     * This method should be overridden by subclasses for specific business logic
     * @param request RestRequest from Salesforce REST API
     * @param httpMethod HTTP method
     * @return IntegrationResponse containing the response data
     */
    protected virtual IntegrationResponse processInboundRequest(RestRequest request, String httpMethod) {
        // Default implementation - returns a simple response
        // Subclasses should override this method with their specific business logic
        Map<String, Object> responseData = new Map<String, Object>{
            'message' => 'Request processed successfully',
            'method' => httpMethod,
            'endpoint' => request.requestURI,
            'timestamp' => System.currentTimeMillis()
        };
        
        return new IntegrationResponse(
            JSON.serialize(responseData),
            200,
            new Map<String, String>{'Content-Type' => 'application/json'},
            null, // correlationId
            0 // processingTimeMs
        );
    }
}
