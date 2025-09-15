/**
 * @description Integration Framework - Version 8
 * @author Jhosua R. Arda
 * @version 8.0
 * @purpose This framework is being used in Accenture projects and freelancing work.
 *          DO NOT MODIFY this class as it is part of the framework.
 *          Modifying this class will destroy the framework functionality.
 * 
 * Interface for operations that can be retried with exponential backoff
 */
public interface RetryableOperation {
    
    /**
     * @description Executes the operation that may need to be retried
     * @return Object result of the operation
     */
    Object execute();
}
