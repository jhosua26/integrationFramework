/**
 * @description EASY DATA CLEANUP for Integration Framework
 * 
 * This class automatically deletes old integration logs and errors to keep your org clean.
 * 
 * HOW TO USE (3 simple steps):
 * 1. Deploy this class to your org
 * 2. Run: IntegrationDataCleanupBatch.scheduleMonthlyCleanup();
 * 3. That's it! Your data will be cleaned up automatically every month
 * 
 * WHAT IT DOES:
 * - Deletes integration logs older than 90 days
 * - Deletes error logs older than 180 days
 * - Runs automatically on the 1st of every month at 2 AM
 * 
 * CUSTOMIZE (optional):
 * - Change retention days by editing the numbers in the constructor
 * - Run immediately: IntegrationDataCleanupBatch.runCleanupNow();
 * - Test first: IntegrationDataCleanupBatch.runDryRun();
 * 
 * @author Integration Framework
 * @version 1.0
 */
global class IntegrationDataCleanupBatch implements Database.Batchable<SObject>, Schedulable {
    
    // CHANGE THESE NUMBERS IF YOU WANT DIFFERENT RETENTION PERIODS
    private Integer logRetentionDays = 90;    // Keep integration logs for 90 days
    private Integer errorRetentionDays = 180; // Keep error logs for 180 days
    private Boolean dryRun = false;           // Set to true to test without deleting
    
    // Default constructor - uses 90/180 day retention (most users)
    public IntegrationDataCleanupBatch() {
        // Uses the default values above - no changes needed for most users
    }
    
    // Advanced constructor for custom retention periods
    public IntegrationDataCleanupBatch(Integer logDays, Integer errorDays, Boolean testMode) {
        this.logRetentionDays = logDays != null ? logDays : 90;
        this.errorRetentionDays = errorDays != null ? errorDays : 180;
        this.dryRun = testMode != null ? testMode : false;
    }
    
    // Finds old integration logs to delete
    global Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('Starting Integration Data Cleanup Batch');
        System.debug('Log Retention Days: ' + logRetentionDays);
        System.debug('Error Retention Days: ' + errorRetentionDays);
        System.debug('Dry Run: ' + dryRun);
        
        Date logCutoffDate = Date.today().addDays(-logRetentionDays);
        return Database.getQueryLocator([
            SELECT Id, Name, Correlation_ID__c, CreatedDate, System__c
            FROM Integration_Log__c 
            WHERE CreatedDate < :logCutoffDate
            ORDER BY CreatedDate ASC
        ]);
    }
    
    // Deletes the batch of logs (or just logs what would be deleted in dry run)
    global void execute(Database.BatchableContext bc, List<Integration_Log__c> logs) {
        System.debug('Processing batch of ' + logs.size() + ' integration logs');
        
        if (dryRun) {
            // Dry run - just log what would be deleted
            for (Integration_Log__c log : logs) {
                System.debug('Would delete log: ' + log.Name + ' (Created: ' + log.CreatedDate + ')');
            }
            return;
        }
        
        try {
            delete logs;
            System.debug('Successfully deleted ' + logs.size() + ' integration logs');
            cleanupErrorLogs();
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error deleting integration logs: ' + e.getMessage());
            throw e;
        }
    }
    
    // Reports the final results of the batch job
    global void finish(Database.BatchableContext bc) {
        System.debug('Integration Data Cleanup Batch completed');
        
        AsyncApexJob job = [
            SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems
            FROM AsyncApexJob 
            WHERE Id = :bc.getJobId()
        ];
        
        System.debug('Batch Job Status: ' + job.Status);
        System.debug('Items Processed: ' + job.JobItemsProcessed + '/' + job.TotalJobItems);
        System.debug('Errors: ' + job.NumberOfErrors);
        
        if (job.NumberOfErrors > 0) {
            System.debug(LoggingLevel.ERROR, 'Batch job completed with errors');
        }
    }
    
    // Called when scheduled - starts the batch process
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new IntegrationDataCleanupBatch(logRetentionDays, errorRetentionDays, dryRun), 200);
    }
    
    // Deletes old error logs based on retention period
    private void cleanupErrorLogs() {
        Date errorCutoffDate = Date.today().addDays(-errorRetentionDays);
        
        List<Integration_Error__c> oldErrors = [
            SELECT Id FROM Integration_Error__c 
            WHERE CreatedDate < :errorCutoffDate
        ];
        
        if (!oldErrors.isEmpty()) {
            delete oldErrors;
            System.debug('Successfully deleted ' + oldErrors.size() + ' error logs');
        }
    }
    
    // ========================================
    // EASY METHODS - JUST COPY AND RUN THESE!
    // ========================================
    
    // Sets up monthly cleanup (runs 1st of every month at 2 AM)
    public static void scheduleMonthlyCleanup() {
        String jobName = 'Integration Data Cleanup - Monthly';
        String cronExpression = '0 0 2 1 * ?'; // 2 AM on the 1st of every month
        
        List<CronTrigger> existingJobs = [
            SELECT Id FROM CronTrigger 
            WHERE CronJobDetail.Name = :jobName
        ];
        
        if (!existingJobs.isEmpty()) {
            System.abortJob(existingJobs[0].Id);
        }
        
        System.schedule(jobName, cronExpression, new IntegrationDataCleanupBatch());
        System.debug('✅ SUCCESS: Monthly data cleanup scheduled! It will run on the 1st of every month at 2 AM.');
    }
    
    // Deletes old data immediately
    public static void runCleanupNow() {
        Database.executeBatch(new IntegrationDataCleanupBatch(), 200);
        System.debug('✅ SUCCESS: Data cleanup started! Check the debug logs for progress.');
    }
    
    // Shows what would be deleted without actually deleting (safe to run)
    public static void runDryRun() {
        Database.executeBatch(new IntegrationDataCleanupBatch(90, 180, true), 200);
        System.debug('✅ SUCCESS: Test cleanup started! Check the debug logs to see what would be deleted.');
    }
    
    // Sets up weekly cleanup (runs every Sunday at 2 AM)
    public static void scheduleWeeklyCleanup() {
        String jobName = 'Integration Data Cleanup - Weekly';
        String cronExpression = '0 0 2 ? * SUN'; // 2 AM every Sunday
        
        List<CronTrigger> existingJobs = [
            SELECT Id FROM CronTrigger 
            WHERE CronJobDetail.Name = :jobName
        ];
        
        if (!existingJobs.isEmpty()) {
            System.abortJob(existingJobs[0].Id);
        }
        
        System.schedule(jobName, cronExpression, new IntegrationDataCleanupBatch());
        System.debug('Scheduled weekly integration data cleanup');
    }
    
    // Sets up quarterly cleanup (runs 1st of Jan, Apr, Jul, Oct at 2 AM)
    public static void scheduleQuarterlyCleanup() {
        String jobName = 'Integration Data Cleanup - Quarterly';
        String cronExpression = '0 0 2 1 1,4,7,10 ?'; // 2 AM on the 1st of Jan, Apr, Jul, Oct
        
        List<CronTrigger> existingJobs = [
            SELECT Id FROM CronTrigger 
            WHERE CronJobDetail.Name = :jobName
        ];
        
        if (!existingJobs.isEmpty()) {
            System.abortJob(existingJobs[0].Id);
        }
        
        System.schedule(jobName, cronExpression, new IntegrationDataCleanupBatch());
        System.debug('Scheduled quarterly integration data cleanup');
    }
    
    // Shows how much data you have and what would be deleted
    public static void checkDataVolume() {
        List<AggregateResult> logResults = [
            SELECT COUNT(Id) totalLogs, MIN(CreatedDate) oldestLog, MAX(CreatedDate) newestLog
            FROM Integration_Log__c
        ];
        
        List<AggregateResult> errorResults = [
            SELECT COUNT(Id) totalErrors, MIN(CreatedDate) oldestError, MAX(CreatedDate) newestError
            FROM Integration_Error__c
        ];
        
        System.debug('=== Data Volume Report ===');
        System.debug('Integration Logs: ' + logResults[0].get('totalLogs'));
        System.debug('Oldest Log: ' + logResults[0].get('oldestLog'));
        System.debug('Newest Log: ' + logResults[0].get('newestLog'));
        System.debug('Error Logs: ' + errorResults[0].get('totalErrors'));
        System.debug('Oldest Error: ' + errorResults[0].get('oldestError'));
        System.debug('Newest Error: ' + errorResults[0].get('newestError'));
        
        Date logCutoffDate = Date.today().addDays(-90);
        Date errorCutoffDate = Date.today().addDays(-180);
        
        Integer logsToDelete = [
            SELECT COUNT() FROM Integration_Log__c 
            WHERE CreatedDate < :logCutoffDate
        ];
        
        Integer errorsToDelete = [
            SELECT COUNT() FROM Integration_Error__c 
            WHERE CreatedDate < :errorCutoffDate
        ];
        
        System.debug('=== Cleanup Preview (90/180 day retention) ===');
        System.debug('Integration Logs to Delete: ' + logsToDelete);
        System.debug('Error Logs to Delete: ' + errorsToDelete);
    }
}





