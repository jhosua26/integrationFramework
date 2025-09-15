/**
 * @description Integration Framework - Version 8
 * @author Jhosua R. Arda
 * @version 8.0
 * @purpose This framework is being used in Accenture projects and freelancing work.
 *          DO NOT MODIFY this class as it is part of the framework.
 *          Modifying this class will destroy the framework functionality.
 * 
 * Manages framework configuration settings including:
 * - Environment type detection
 * - Queueable retry enablement
 * - Framework behavior configuration
 * 
 * Follows principles: SOLID, dependency injection, guard clauses
 */
public class FrameworkConfigManager {
    
    private static FrameworkConfigManager instance;
    private Integration_Framework_Config__c config;
    
    /**
     * Private constructor for singleton pattern
     * 
     * Loads configuration from the custom object on initialization.
     * Use getInstance() method to get the shared instance.
     */
    private FrameworkConfigManager() {
        loadConfiguration();
    }
    
    /**
     * Gets the singleton instance
     * 
     * Returns a shared instance for consistent configuration management.
     * Use this method to get the config manager instance instead of creating new ones.
     */
    public static FrameworkConfigManager getInstance() {
        if (instance == null) {
            instance = new FrameworkConfigManager();
        }
        return instance;
    }
    
    /**
     * Resets singleton instance for testing
     * 
     * Clears the singleton instance to allow fresh initialization.
     * Only use this method in test classes for proper test isolation.
     */
    @TestVisible
    public static void resetInstance() {
        instance = null;
    }
    
    /**
     * Loads configuration from custom object
     * 
     * Reads configuration settings from Integration_Framework_Config__c custom object.
     * Creates default configuration if no custom object exists.
     */
    private void loadConfiguration() {
        try {
            List<Integration_Framework_Config__c> configs = [
                SELECT Id, Name, Enable_Queueable_Retry__c, Environment_Type__c
                FROM Integration_Framework_Config__c 
                LIMIT 1
            ];
            
            if (!configs.isEmpty()) {
                this.config = configs[0];
            } else {
                // Create default configuration if none exists
                this.config = createDefaultConfiguration();
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to load framework configuration: ' + e.getMessage());
            // Use default configuration on error
            this.config = createDefaultConfiguration();
        }
    }
    
    /**
     * @description Creates default configuration
     * @return Default Integration_Framework_Config__c record
     */
    private Integration_Framework_Config__c createDefaultConfiguration() {
        // Return default configuration without persisting to avoid DML before callouts
        Integration_Framework_Config__c defaultConfig = new Integration_Framework_Config__c(
            Enable_Queueable_Retry__c = false,
            Environment_Type__c = 'Development'
        );
        
        System.debug('Using default framework configuration (not persisted)');
        return defaultConfig;
    }
    
    /**
     * @description Determines if Queueable retry is enabled
     * @return Boolean indicating if Queueable retry is enabled
     */
    public Boolean isQueueableRetryEnabled() {
        if (config == null) {
            return false;
        }
        return config.Enable_Queueable_Retry__c == true;
    }
    
    /**
     * @description Determines if we're in a production environment
     * @return Boolean indicating if production environment
     */
    public Boolean isProductionEnvironment() {
        if (config == null) {
            return false;
        }
        return config.Environment_Type__c == 'Production';
    }
    
    /**
     * @description Gets the current environment type
     * @return String environment type
     */
    public String getEnvironmentType() {
        if (config == null) {
            return 'Development';
        }
        return config.Environment_Type__c;
    }
    
    /**
     * @description Updates the configuration
     * @param enableQueueableRetry Whether to enable Queueable retry
     * @param environmentType Environment type
     */
    public void updateConfiguration(Boolean enableQueueableRetry, String environmentType) {
        if (config == null) {
            throw new IllegalArgumentException('Configuration not loaded');
        }
        
        // Only update fields if values are provided (not null)
        if (enableQueueableRetry != null) {
            config.Enable_Queueable_Retry__c = enableQueueableRetry;
        }
        if (environmentType != null) {
            config.Environment_Type__c = environmentType;
        }
        
        try {
            update config;
            System.debug('Updated framework configuration');
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to update configuration: ' + e.getMessage());
            throw new FrameworkException('Failed to update configuration: ' + e.getMessage());
        }
    }
    
    
    /**
     * @description Gets the current configuration
     * @return Integration_Framework_Config__c configuration
     */
    public Integration_Framework_Config__c getConfiguration() {
        return config;
    }
    
    /**
     * @description Custom exception for framework configuration errors
     */
    public class FrameworkException extends Exception {}
}
