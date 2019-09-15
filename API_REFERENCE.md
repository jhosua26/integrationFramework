# Integration Framework - API Reference

## Core Classes

### RESTConnector

The primary connector for HTTP-based integrations.

#### Constructor
```apex
public RESTConnector(IIntegrationLogger logger, String systemName, Integer timeoutMs, Map<String, String> defaultHeaders)
```

**Parameters:**
- `logger` (IIntegrationLogger): Logger implementation
- `systemName` (String): Name of the external system
- `timeoutMs` (Integer): Request timeout in milliseconds
- `defaultHeaders` (Map<String, String>): Default headers to include in all requests

#### Methods

##### sendRequest
```apex
public IntegrationResponse sendRequest(String endpoint, String payload, Map<String, String> headers, String method, String correlationId)
```

Sends a request to the external system.

**Parameters:**
- `endpoint` (String): The endpoint URL
- `payload` (String): The request payload
- `headers` (Map<String, String>): Request headers
- `method` (String): HTTP method (GET, POST, PUT, PATCH, DELETE)
- `correlationId` (String): Unique identifier for tracking

**Returns:** `IntegrationResponse` containing the response data

**Throws:** `IllegalArgumentException` if parameters are invalid

##### handleInboundRequest
```apex
public IntegrationResponse handleInboundRequest(RestRequest request, String httpMethod)
```

Handles inbound REST API requests.

**Parameters:**
- `request` (RestRequest): RestRequest from Salesforce REST API
- `httpMethod` (String): HTTP method (GET, POST, PUT, PATCH, DELETE)

**Returns:** `IntegrationResponse` containing the response data

**Throws:** `IllegalArgumentException` if parameters are invalid

##### handleInboundGet
```apex
public IntegrationResponse handleInboundGet(RestRequest request)
```

Handles an inbound GET request.

**Parameters:**
- `request` (RestRequest): RestRequest from Salesforce REST API

**Returns:** `IntegrationResponse` containing the response data

##### handleInboundPost
```apex
public IntegrationResponse handleInboundPost(RestRequest request)
```

Handles an inbound POST request.

**Parameters:**
- `request` (RestRequest): RestRequest from Salesforce REST API

**Returns:** `IntegrationResponse` containing the response data

##### handleInboundPut
```apex
public IntegrationResponse handleInboundPut(RestRequest request)
```

Handles an inbound PUT request.

**Parameters:**
- `request` (RestRequest): RestRequest from Salesforce REST API

**Returns:** `IntegrationResponse` containing the response data

##### handleInboundPatch
```apex
public IntegrationResponse handleInboundPatch(RestRequest request)
```

Handles an inbound PATCH request.

**Parameters:**
- `request` (RestRequest): RestRequest from Salesforce REST API

**Returns:** `IntegrationResponse` containing the response data

##### handleInboundDelete
```apex
public IntegrationResponse handleInboundDelete(RestRequest request)
```

Handles an inbound DELETE request.

**Parameters:**
- `request` (RestRequest): RestRequest from Salesforce REST API

**Returns:** `IntegrationResponse` containing the response data

##### validateConfiguration
```apex
public Boolean validateConfiguration()
```

Validates that the connector is properly configured.

**Returns:** `Boolean` indicating if configuration is valid

##### getConnectorType
```apex
public String getConnectorType()
```

Gets the connector type.

**Returns:** `String` indicating the connector type ("REST")

##### getLogger
```apex
public IIntegrationLogger getLogger()
```

Gets the logger instance.

**Returns:** `IIntegrationLogger` logger instance

##### getSystemName
```apex
public String getSystemName()
```

Gets the system name.

**Returns:** `String` system name

---

### IntegrationLogger

Centralized logging component for all integration activities.

#### Constructor
```apex
public IntegrationLogger()
```

Creates a new IntegrationLogger instance.

#### Methods

##### logInboundMessage
```apex
public void logInboundMessage(String correlationId, String systemName, String payload, Map<String, Object> additionalContext)
```

Logs an inbound message.

**Parameters:**
- `correlationId` (String): Unique identifier for the integration session
- `systemName` (String): Name of the external system
- `payload` (String): The message payload
- `additionalContext` (Map<String, Object>): Additional context information

**Throws:** `IllegalArgumentException` if correlationId or systemName is blank

##### logOutboundMessage
```apex
public void logOutboundMessage(String correlationId, String systemName, String payload, Map<String, Object> additionalContext)
```

Logs an outbound message.

**Parameters:**
- `correlationId` (String): Unique identifier for the integration session
- `systemName` (String): Name of the external system
- `payload` (String): The message payload
- `additionalContext` (Map<String, Object>): Additional context information

**Throws:** `IllegalArgumentException` if correlationId or systemName is blank

##### logError
```apex
public void logError(String correlationId, String errorType, String errorMessage, String stackTrace, String severity, Map<String, Object> context)
```

Logs an integration error.

**Parameters:**
- `correlationId` (String): Unique identifier for the integration session
- `errorType` (String): Type of error
- `errorMessage` (String): Error message
- `stackTrace` (String): Stack trace
- `severity` (String): Error severity
- `context` (Map<String, Object>): Additional context information

**Throws:** `IllegalArgumentException` if required parameters are blank

##### updateLogStatus
```apex
public void updateLogStatus(String correlationId, String status, Map<String, Object> additionalData)
```

Updates the status of an existing log record.

**Parameters:**
- `correlationId` (String): Unique identifier for the integration session
- `status` (String): New status
- `additionalData` (Map<String, Object>): Additional data to update

##### getInstance
```apex
public static IntegrationLogger getInstance()
```

Gets the singleton instance of IntegrationLogger.

**Returns:** `IntegrationLogger` singleton instance

---

### RetryManager

Intelligent retry logic with configurable policies.

#### Constructor
```apex
public RetryManager(IIntegrationLogger logger, FrameworkErrorHandler errorHandler, Integer maxRetries, Integer baseDelayMs)
```

**Parameters:**
- `logger` (IIntegrationLogger): Logger implementation
- `errorHandler` (FrameworkErrorHandler): Error handler instance
- `maxRetries` (Integer): Maximum number of retry attempts
- `baseDelayMs` (Integer): Base delay in milliseconds for exponential backoff

#### Methods

##### executeWithRetry
```apex
public RetryResult executeWithRetry(RetryableOperation operation, String correlationId, String systemName, Map<String, Object> context)
```

Executes an operation with retry logic and exponential backoff.

**Parameters:**
- `operation` (RetryableOperation): The operation to execute
- `correlationId` (String): Unique identifier for tracking
- `systemName` (String): Name of the external system
- `context` (Map<String, Object>): Additional context information

**Returns:** `RetryResult` containing the result and retry information

**Throws:** `IllegalArgumentException` if parameters are invalid

##### scheduleQueueableRetry
```apex
public void scheduleQueueableRetry(RetryableOperation operation, String correlationId, String systemName, Map<String, Object> context)
```

Schedules a queueable retry for long-running operations.

**Parameters:**
- `operation` (RetryableOperation): The operation to execute
- `correlationId` (String): Unique identifier for tracking
- `systemName` (String): Name of the external system
- `context` (Map<String, Object>): Additional context information

##### getInstance
```apex
public static RetryManager getInstance()
```

Gets the singleton instance of RetryManager.

**Returns:** `RetryManager` singleton instance

##### isRetryableError
```apex
public Boolean isRetryableError(Exception ex)
```

Determines if an error is retryable.

**Parameters:**
- `ex` (Exception): The exception to check

**Returns:** `Boolean` indicating if the error is retryable

##### calculateBackoffDelay
```apex
public Integer calculateBackoffDelay(Integer retryCount)
```

Calculates the delay for exponential backoff.

**Parameters:**
- `retryCount` (Integer): Current retry count

**Returns:** `Integer` delay in milliseconds

---

### FrameworkErrorHandler

Comprehensive error handling and classification system.

#### Constructor
```apex
public FrameworkErrorHandler(IIntegrationLogger logger)
```

**Parameters:**
- `logger` (IIntegrationLogger): Logger implementation

#### Methods

##### logFrameworkError
```apex
public void logFrameworkError(String correlationId, String errorType, String errorMessage, String stackTrace, String severity, Map<String, Object> context)
```

Logs a framework error with comprehensive handling.

**Parameters:**
- `correlationId` (String): Unique identifier for tracking
- `errorType` (String): Error type classification
- `errorMessage` (String): Error message
- `stackTrace` (String): Stack trace
- `severity` (String): Error severity
- `context` (Map<String, Object>): Additional context information

##### classifyError
```apex
public String classifyError(Exception ex)
```

Classifies an exception into an error type.

**Parameters:**
- `ex` (Exception): The exception to classify

**Returns:** `String` error type classification

##### assessFrameworkSeverity
```apex
public String assessFrameworkSeverity(String errorType, String errorMessage)
```

Assesses the severity of a framework error.

**Parameters:**
- `errorType` (String): Error type classification
- `errorMessage` (String): Error message

**Returns:** `String` severity level (LOW, MEDIUM, HIGH, CRITICAL)

##### determineHttpStatusCode
```apex
public Integer determineHttpStatusCode(String errorType, String errorMessage)
```

Determines the appropriate HTTP status code for an error.

**Parameters:**
- `errorType` (String): Error type classification
- `errorMessage` (String): Error message

**Returns:** `Integer` HTTP status code

##### createStandardErrorResponse
```apex
public Map<String, Object> createStandardErrorResponse(String errorType, String errorMessage)
```

Creates a standardized error response.

**Parameters:**
- `errorType` (String): Error type classification
- `errorMessage` (String): Error message

**Returns:** `Map<String, Object>` standardized error response

---

## Data Models

### IntegrationResponse

Wrapper class for integration responses.

#### Constructors

##### Success Constructor
```apex
public IntegrationResponse(String responseBody, Integer statusCode, Map<String, String> headers, String correlationId, Long processingTimeMs)
```

**Parameters:**
- `responseBody` (String): The response body
- `statusCode` (Integer): HTTP status code
- `headers` (Map<String, String>): Response headers
- `correlationId` (String): Unique identifier for tracking
- `processingTimeMs` (Long): Processing time in milliseconds

##### Error Constructor
```apex
public IntegrationResponse(String errorMessage, Integer statusCode, String correlationId, Long processingTimeMs)
```

**Parameters:**
- `errorMessage` (String): Error message
- `statusCode` (Integer): HTTP status code
- `correlationId` (String): Unique identifier for tracking
- `processingTimeMs` (Long): Processing time in milliseconds

#### Methods

##### getIsSuccess
```apex
public Boolean getIsSuccess()
```

Gets whether the response indicates success.

**Returns:** `Boolean` indicating success

##### getResponseBody
```apex
public String getResponseBody()
```

Gets the response body.

**Returns:** `String` response body

##### getStatusCode
```apex
public Integer getStatusCode()
```

Gets the HTTP status code.

**Returns:** `Integer` status code

##### getHeaders
```apex
public Map<String, String> getHeaders()
```

Gets the response headers.

**Returns:** `Map<String, String>` response headers

##### getErrorMessage
```apex
public String getErrorMessage()
```

Gets the error message.

**Returns:** `String` error message

##### getCorrelationId
```apex
public String getCorrelationId()
```

Gets the correlation ID.

**Returns:** `String` correlation ID

##### getProcessingTimeMs
```apex
public Long getProcessingTimeMs()
```

Gets the processing time in milliseconds.

**Returns:** `Long` processing time

##### getMetadata
```apex
public Map<String, Object> getMetadata()
```

Gets the metadata.

**Returns:** `Map<String, Object>` metadata

##### addMetadata
```apex
public void addMetadata(String key, Object value)
```

Adds metadata to the response.

**Parameters:**
- `key` (String): Metadata key
- `value` (Object): Metadata value

##### isRetryableError
```apex
public Boolean isRetryableError()
```

Determines if the response represents a retryable error.

**Returns:** `Boolean` indicating if error is retryable

##### getSummary
```apex
public String getSummary()
```

Gets a summary of the response.

**Returns:** `String` response summary

---

### RetryResult

Result of a retry operation.

#### Constructor
```apex
public RetryResult(Object result, Boolean isSuccess, Integer retryCount, Long totalProcessingTime, Exception lastException)
```

**Parameters:**
- `result` (Object): The operation result
- `isSuccess` (Boolean): Whether the operation succeeded
- `retryCount` (Integer): Number of retries performed
- `totalProcessingTime` (Long): Total processing time
- `lastException` (Exception): Last exception encountered

#### Methods

##### getResult
```apex
public Object getResult()
```

Gets the operation result.

**Returns:** `Object` operation result

##### getIsSuccess
```apex
public Boolean getIsSuccess()
```

Gets whether the operation succeeded.

**Returns:** `Boolean` indicating success

##### getRetryCount
```apex
public Integer getRetryCount()
```

Gets the number of retries performed.

**Returns:** `Integer` retry count

##### getTotalProcessingTime
```apex
public Long getTotalProcessingTime()
```

Gets the total processing time.

**Returns:** `Long` total processing time

##### getLastException
```apex
public Exception getLastException()
```

Gets the last exception encountered.

**Returns:** `Exception` last exception

##### getErrorMessage
```apex
public String getErrorMessage()
```

Gets the error message.

**Returns:** `String` error message

##### wasRetried
```apex
public Boolean wasRetried()
```

Gets whether the operation was retried.

**Returns:** `Boolean` indicating if operation was retried

---

## Utility Classes

### CorrelationIdGenerator

Generates unique correlation IDs for request tracking.

#### Methods

##### generateCorrelationId
```apex
public static String generateCorrelationId()
```

Generates a unique correlation ID.

**Returns:** `String` unique correlation ID

##### generateCorrelationId
```apex
public static String generateCorrelationId(String prefix)
```

Generates a unique correlation ID with a custom prefix.

**Parameters:**
- `prefix` (String): Custom prefix (3 characters max)

**Returns:** `String` unique correlation ID with prefix

##### generateCorrelationIdFromRecord
```apex
public static String generateCorrelationIdFromRecord(SObject record)
```

Generates a correlation ID from a Salesforce record.

**Parameters:**
- `record` (SObject): Salesforce record

**Returns:** `String` unique correlation ID based on record

##### isValidCorrelationId
```apex
public static Boolean isValidCorrelationId(String correlationId)
```

Validates a correlation ID format.

**Parameters:**
- `correlationId` (String): Correlation ID to validate

**Returns:** `Boolean` indicating if correlation ID is valid

---

### IntegrationHelpers

Utility methods for common integration tasks.

#### Methods

##### createRecord
```apex
public static IntegrationResponse createRecord(String systemName, String objectType, Map<String, Object> recordData)
```

Creates a Salesforce record.

**Parameters:**
- `systemName` (String): System name
- `objectType` (String): Salesforce object type
- `recordData` (Map<String, Object>): Record data

**Returns:** `IntegrationResponse` containing the result

##### updateRecord
```apex
public static IntegrationResponse updateRecord(String systemName, String recordId, Map<String, Object> recordData)
```

Updates a Salesforce record.

**Parameters:**
- `systemName` (String): System name
- `recordId` (String): Record ID to update
- `recordData` (Map<String, Object>): Record data

**Returns:** `IntegrationResponse` containing the result

##### queryRecords
```apex
public static IntegrationResponse queryRecords(String systemName, String soqlQuery)
```

Queries Salesforce records.

**Parameters:**
- `systemName` (String): System name
- `soqlQuery` (String): SOQL query

**Returns:** `IntegrationResponse` containing the query results

##### deleteRecord
```apex
public static IntegrationResponse deleteRecord(String systemName, String recordId)
```

Deletes a Salesforce record.

**Parameters:**
- `systemName` (String): System name
- `recordId` (String): Record ID to delete

**Returns:** `IntegrationResponse` containing the result

---

## Configuration Classes

### FrameworkConfigManager

Manages framework configuration settings.

#### Methods

##### loadConfiguration
```apex
public void loadConfiguration()
```

Loads the framework configuration.

##### updateConfiguration
```apex
public void updateConfiguration(Boolean enableQueueableRetry, String environmentType)
```

Updates the framework configuration.

**Parameters:**
- `enableQueueableRetry` (Boolean): Enable queueable retries
- `environmentType` (String): Environment type

##### getConfiguration
```apex
public Integration_Framework_Config__c getConfiguration()
```

Gets the current configuration.

**Returns:** `Integration_Framework_Config__c` configuration record

---

## Interfaces

### IIntegrationLogger

Interface for integration logging.

#### Methods

##### logInboundMessage
```apex
void logInboundMessage(String correlationId, String systemName, String payload, Map<String, Object> additionalContext)
```

##### logOutboundMessage
```apex
void logOutboundMessage(String correlationId, String systemName, String payload, Map<String, Object> additionalContext)
```

##### logError
```apex
void logError(String correlationId, String errorType, String errorMessage, String stackTrace, String severity, Map<String, Object> context)
```

##### updateLogStatus
```apex
void updateLogStatus(String correlationId, String status, Map<String, Object> additionalData)
```

---

### IIntegrationConnector

Interface for integration connectors.

#### Methods

##### sendRequest
```apex
IntegrationResponse sendRequest(String endpoint, String payload, Map<String, String> headers, String method, String correlationId)
```

##### validateConfiguration
```apex
Boolean validateConfiguration()
```

##### getConnectorType
```apex
String getConnectorType()
```

---

### RetryableOperation

Interface for retryable operations.

#### Methods

##### execute
```apex
Object execute()
```

Executes the operation.

**Returns:** `Object` operation result

**Throws:** `Exception` if operation fails





