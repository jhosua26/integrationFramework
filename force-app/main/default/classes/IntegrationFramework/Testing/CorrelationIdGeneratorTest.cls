/**
 * @description Integration Framework - Version 8
 * @author Jhosua R. Arda
 * @version 8.0
 * @purpose This framework is being used in Accenture projects and freelancing work.
 *          DO NOT MODIFY this class as it is part of the framework.
 *          Modifying this class will destroy the framework functionality.
 * 
 * Test class for CorrelationIdGenerator functionality
 * 
 * IMPORTANT: DO NOT REMOVE existing test methods. Only add new test methods to maintain
 *            high test coverage. Removing existing methods will reduce test coverage.
 */
@isTest
public class CorrelationIdGeneratorTest {
    
    @isTest
    static void testGenerateCorrelationId() {
        Test.startTest();
        String correlationId1 = CorrelationIdGenerator.generateCorrelationId();
        String correlationId2 = CorrelationIdGenerator.generateCorrelationId();
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, correlationId1, 'Correlation ID should not be null');
        System.assertNotEquals(null, correlationId2, 'Correlation ID should not be null');
        System.assertNotEquals(correlationId1, correlationId2, 'Correlation IDs should be unique');
        
        // Validate format
        System.assert(CorrelationIdGenerator.isValidCorrelationId(correlationId1), 'Generated correlation ID should be valid');
        System.assert(CorrelationIdGenerator.isValidCorrelationId(correlationId2), 'Generated correlation ID should be valid');
        
        // Check prefix
        System.assert(correlationId1.startsWith('INT-'), 'Should start with INT- prefix');
        System.assert(correlationId2.startsWith('INT-'), 'Should start with INT- prefix');
    }
    
    @isTest
    static void testGenerateCorrelationIdWithCustomPrefix() {
        String customPrefix = 'TES';
        
        Test.startTest();
        String correlationId = CorrelationIdGenerator.generateCorrelationId(customPrefix);
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, correlationId, 'Correlation ID should not be null');
        System.assert(correlationId.startsWith(customPrefix + '-'), 'Should start with custom prefix');
        System.assert(CorrelationIdGenerator.isValidCorrelationId(correlationId), 'Generated correlation ID should be valid');
    }
    
    @isTest
    static void testGenerateCorrelationIdWithNullPrefix() {
        Test.startTest();
        String correlationId = CorrelationIdGenerator.generateCorrelationId(null);
        Test.stopTest();
        
        // Should fallback to default prefix
        System.assertNotEquals(null, correlationId, 'Correlation ID should not be null');
        System.assert(correlationId.startsWith('INT-'), 'Should start with default INT- prefix');
        System.assert(CorrelationIdGenerator.isValidCorrelationId(correlationId), 'Generated correlation ID should be valid');
    }
    
    @isTest
    static void testGenerateCorrelationIdWithEmptyPrefix() {
        Test.startTest();
        String correlationId = CorrelationIdGenerator.generateCorrelationId('');
        Test.stopTest();
        
        // Should fallback to default prefix
        System.assertNotEquals(null, correlationId, 'Correlation ID should not be null');
        System.assert(correlationId.startsWith('INT-'), 'Should start with default INT- prefix');
        System.assert(CorrelationIdGenerator.isValidCorrelationId(correlationId), 'Generated correlation ID should be valid');
    }
    
    @isTest
    static void testGenerateCorrelationIdWithBlankPrefix() {
        Test.startTest();
        String correlationId = CorrelationIdGenerator.generateCorrelationId('   ');
        Test.stopTest();
        
        // Should fallback to default prefix
        System.assertNotEquals(null, correlationId, 'Correlation ID should not be null');
        System.assert(correlationId.startsWith('INT-'), 'Should start with default INT- prefix');
        System.assert(CorrelationIdGenerator.isValidCorrelationId(correlationId), 'Generated correlation ID should be valid');
    }
    
    @isTest
    static void testGenerateCorrelationIdFromRecord() {
        // Create a test account to get a real record ID
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        Test.startTest();
        String correlationId = CorrelationIdGenerator.generateCorrelationIdFromRecord(testAccount.Id);
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, correlationId, 'Correlation ID should not be null');
        System.assert(correlationId.startsWith('INT-'), 'Should start with INT- prefix');
        System.assert(CorrelationIdGenerator.isValidCorrelationId(correlationId), 'Generated correlation ID should be valid');
        
        // Check that record ID is included in suffix
        String recordPrefix = String.valueOf(testAccount.Id).substring(0, 8);
        System.assert(correlationId.contains(recordPrefix), 'Should contain record ID prefix');
    }
    
    @isTest
    static void testGenerateCorrelationIdFromNullRecord() {
        Test.startTest();
        String correlationId = CorrelationIdGenerator.generateCorrelationIdFromRecord(null);
        Test.stopTest();
        
        // Should fallback to default generation
        System.assertNotEquals(null, correlationId, 'Correlation ID should not be null');
        System.assert(correlationId.startsWith('INT-'), 'Should start with default INT- prefix');
        System.assert(CorrelationIdGenerator.isValidCorrelationId(correlationId), 'Generated correlation ID should be valid');
    }
    
    @isTest
    static void testIsValidCorrelationIdValidFormat() {
        String validCorrelationId = 'INT-20240101120000000-123456';
        
        Test.startTest();
        Boolean isValid = CorrelationIdGenerator.isValidCorrelationId(validCorrelationId);
        Test.stopTest();
        
        System.assertEquals(true, isValid, 'Valid correlation ID should return true');
    }
    
    @isTest
    static void testIsValidCorrelationIdWithRecordSuffix() {
        String validCorrelationId = 'INT-20240101120000000-001XXXXX';
        
        Test.startTest();
        Boolean isValid = CorrelationIdGenerator.isValidCorrelationId(validCorrelationId);
        Test.stopTest();
        
        System.assertEquals(true, isValid, 'Valid correlation ID with record suffix should return true');
    }
    
    @isTest
    static void testIsValidCorrelationIdNullInput() {
        Test.startTest();
        Boolean isValid = CorrelationIdGenerator.isValidCorrelationId(null);
        Test.stopTest();
        
        System.assertEquals(false, isValid, 'Null correlation ID should return false');
    }
    
    @isTest
    static void testIsValidCorrelationIdEmptyInput() {
        Test.startTest();
        Boolean isValid = CorrelationIdGenerator.isValidCorrelationId('');
        Test.stopTest();
        
        System.assertEquals(false, isValid, 'Empty correlation ID should return false');
    }
    
    @isTest
    static void testIsValidCorrelationIdBlankInput() {
        Test.startTest();
        Boolean isValid = CorrelationIdGenerator.isValidCorrelationId('   ');
        Test.stopTest();
        
        System.assertEquals(false, isValid, 'Blank correlation ID should return false');
    }
    
    @isTest
    static void testIsValidCorrelationIdInvalidFormatTooFewParts() {
        String invalidCorrelationId = 'INT-20240101120000000';
        
        Test.startTest();
        Boolean isValid = CorrelationIdGenerator.isValidCorrelationId(invalidCorrelationId);
        Test.stopTest();
        
        System.assertEquals(false, isValid, 'Correlation ID with too few parts should return false');
    }
    
    @isTest
    static void testIsValidCorrelationIdInvalidFormatTooManyParts() {
        String invalidCorrelationId = 'INT-20240101120000000-123456-extra';
        
        Test.startTest();
        Boolean isValid = CorrelationIdGenerator.isValidCorrelationId(invalidCorrelationId);
        Test.stopTest();
        
        System.assertEquals(false, isValid, 'Correlation ID with too many parts should return false');
    }
    
    @isTest
    static void testIsValidCorrelationIdInvalidPrefixLength() {
        String invalidCorrelationId = 'IN-20240101120000000-123456';
        
        Test.startTest();
        Boolean isValid = CorrelationIdGenerator.isValidCorrelationId(invalidCorrelationId);
        Test.stopTest();
        
        System.assertEquals(false, isValid, 'Correlation ID with invalid prefix length should return false');
    }
    
    @isTest
    static void testIsValidCorrelationIdInvalidTimestampLength() {
        String invalidCorrelationId = 'INT-2024010112000000-123456';
        
        Test.startTest();
        Boolean isValid = CorrelationIdGenerator.isValidCorrelationId(invalidCorrelationId);
        Test.stopTest();
        
        System.assertEquals(false, isValid, 'Correlation ID with invalid timestamp length should return false');
    }
    
    @isTest
    static void testIsValidCorrelationIdNonNumericTimestamp() {
        String invalidCorrelationId = 'INT-2024010112000000a-123456';
        
        Test.startTest();
        Boolean isValid = CorrelationIdGenerator.isValidCorrelationId(invalidCorrelationId);
        Test.stopTest();
        
        System.assertEquals(false, isValid, 'Correlation ID with non-numeric timestamp should return false');
    }
    
    @isTest
    static void testIsValidCorrelationIdInvalidSuffixLength() {
        String invalidCorrelationId = 'INT-20240101120000000-12345';
        
        Test.startTest();
        Boolean isValid = CorrelationIdGenerator.isValidCorrelationId(invalidCorrelationId);
        Test.stopTest();
        
        System.assertEquals(false, isValid, 'Correlation ID with invalid suffix length should return false');
    }
    
    @isTest
    static void testIsValidCorrelationIdSuffixTooLong() {
        String invalidCorrelationId = 'INT-20240101120000000-123456789';
        
        Test.startTest();
        Boolean isValid = CorrelationIdGenerator.isValidCorrelationId(invalidCorrelationId);
        Test.stopTest();
        
        System.assertEquals(false, isValid, 'Correlation ID with suffix too long should return false');
    }
    
    @isTest
    static void testMultipleGenerationsUniqueness() {
        Set<String> generatedIds = new Set<String>();
        
        Test.startTest();
        for (Integer i = 0; i < 10; i++) {
            String correlationId = CorrelationIdGenerator.generateCorrelationId();
            generatedIds.add(correlationId);
        }
        Test.stopTest();
        
        // All generated IDs should be unique
        System.assertEquals(10, generatedIds.size(), 'All generated correlation IDs should be unique');
        
        // All should be valid
        for (String correlationId : generatedIds) {
            System.assert(CorrelationIdGenerator.isValidCorrelationId(correlationId), 'All generated correlation IDs should be valid');
        }
    }
    
    @isTest
    static void testCorrelationIdFormatComponents() {
        Test.startTest();
        String correlationId = CorrelationIdGenerator.generateCorrelationId();
        Test.stopTest();
        
        // Split the correlation ID into parts
        List<String> parts = correlationId.split('-');
        
        // Should have exactly 3 parts
        System.assertEquals(3, parts.size(), 'Correlation ID should have exactly 3 parts');
        
        // First part should be prefix (3 characters)
        System.assertEquals(3, parts[0].length(), 'Prefix should be exactly 3 characters');
        System.assertEquals('INT', parts[0], 'Prefix should be INT');
        
        // Second part should be timestamp (17 digits)
        System.assertEquals(17, parts[1].length(), 'Timestamp should be exactly 17 characters');
        System.assert(parts[1].isNumeric(), 'Timestamp should be numeric');
        
        // Third part should be suffix (6 digits)
        System.assertEquals(6, parts[2].length(), 'Suffix should be exactly 6 characters');
    }
}
