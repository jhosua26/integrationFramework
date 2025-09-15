/**
 * @description Integration Framework - Version 8
 * @author Jhosua R. Arda
 * @version 8.0
 * @purpose This framework is being used in Accenture projects and freelancing work.
 *          DO NOT MODIFY this class as it is part of the framework.
 *          Modifying this class will destroy the framework functionality.
 * 
 * Utility class for generating unique correlation IDs
 */
public class CorrelationIdGenerator {
    
    private static final String CORRELATION_PREFIX = 'INT';
    private static final String TIMESTAMP_FORMAT = 'yyyyMMddHHmmssSSS';
    
    /**
     * Generates a unique correlation ID
     * 
     * Creates a unique identifier in format: INT-yyyyMMddHHmmssSSS-XXXXXX
     * Uses timestamp and random number for uniqueness.
     * 
     * Returns string correlation ID
     */
    public static String generateCorrelationId() {
        String timestamp = Datetime.now().format(TIMESTAMP_FORMAT);
        String randomSuffix = String.valueOf(Math.abs(Crypto.getRandomInteger())).rightPad(6).substring(0, 6);
        return CORRELATION_PREFIX + '-' + timestamp + '-' + randomSuffix;
    }
    
    /**
     * Generates a correlation ID with a custom prefix
     * 
     * Creates a unique identifier with your custom prefix.
     * Format: PREFIX-yyyyMMddHHmmssSSS-XXXXXX
     * 
     * prefix - Custom prefix for the correlation ID (max 3 characters)
     * Returns string correlation ID with custom prefix
     */
    public static String generateCorrelationId(String prefix) {
        if (String.isBlank(prefix)) {
            return generateCorrelationId();
        }
        
        String timestamp = Datetime.now().format(TIMESTAMP_FORMAT);
        String randomSuffix = String.valueOf(Math.abs(Crypto.getRandomInteger())).rightPad(6).substring(0, 6);
        return prefix + '-' + timestamp + '-' + randomSuffix;
    }
    
    /**
     * Generates a correlation ID based on a record ID
     * 
     * Creates a correlation ID that includes the Salesforce record ID for easy tracking.
     * Format: INT-yyyyMMddHHmmssSSS-XXXXXX-RECORDID
     * 
     * recordId - Salesforce record ID to include in the correlation ID
     * Returns string correlation ID with record ID
     */
    public static String generateCorrelationIdFromRecord(Id recordId) {
        if (recordId == null) {
            return generateCorrelationId();
        }
        
        String timestamp = Datetime.now().format(TIMESTAMP_FORMAT);
        String recordSuffix = String.valueOf(recordId).substring(0, 8);
        return CORRELATION_PREFIX + '-' + timestamp + '-' + recordSuffix;
    }
    
    /**
     * @description Validates if a string is a valid correlation ID format
     * @param correlationId Correlation ID to validate
     * @return Boolean indicating if the format is valid
     */
    public static Boolean isValidCorrelationId(String correlationId) {
        if (String.isBlank(correlationId)) {
            return false;
        }
        
        // Basic format validation: INT-YYYYMMDDHHMMSSSSS-XXXXXX
        // Simple validation without regex since Pattern.matches() doesn't exist in Apex
        List<String> parts = correlationId.split('-');
        if (parts.size() != 3) {
            return false;
        }
        
        // Check prefix (3 characters)
        if (parts[0].length() != 3) {
            return false;
        }
        
        // Check timestamp (17 digits)
        if (parts[1].length() != 17 || !parts[1].isNumeric()) {
            return false;
        }
        
        // Check suffix (6 digits or 8 characters for record-based IDs)
        if (parts[2].length() < 6 || parts[2].length() > 8) {
            return false;
        }
        
        return true;
    }
}
