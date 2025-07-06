// TriggerFactory.cls
public class TriggerFactory {
    public static void run(String objectName, List<SObject> newList, List<SObject> oldList) {
        try {
            // Step 1: Load Custom Metadata to find the handler
            Trigger_Handler_Config__mdt config = getHandlerConfig(objectName);
            if (config == null || !config.Is_Active__c) {
                System.debug('No active handler found for object: ' + objectName);
                return;
            }

            String className = config.Handler_Class__c;
            Type handlerType = Type.forName(className);

            if (handlerType == null) {
                throw new TriggerFactoryException('Handler class not found: ' + className);
            }

            // Step 2: Instantiate and set context
            TriggerHandler handler = (TriggerHandler) handlerType.newInstance();
            handler.setContext(newList, oldList);

            // Step 3: Run the relevant lifecycle method
            executeContext(handler);
        } catch (Exception ex) {
            System.debug('TriggerFactory error: ' + ex.getMessage());
            throw new TriggerFactoryException('Failed to execute trigger handler: ' + ex.getMessage());
        }
    }

    // Gets handler config for the object
    private static Trigger_Handler_Config__mdt getHandlerConfig(String objectName) {
        List<Trigger_Handler_Config__mdt> configs = [
            SELECT Object_Name__c, Handler_Class__c, Is_Active__c
            FROM Trigger_Handler_Config__mdt
            WHERE Object_Name__c = :objectName
            LIMIT 1
        ];
        return configs.isEmpty() ? null : configs[0];
    }

    // Executes the correct trigger context
    private static void executeContext(TriggerHandler handler) {
        if (Trigger.isBefore) {
            if (Trigger.isInsert) handler.beforeInsert();
            else if (Trigger.isUpdate) handler.beforeUpdate();
            else if (Trigger.isDelete) handler.beforeDelete();
        }

        if (Trigger.isAfter) {
            if (Trigger.isInsert) handler.afterInsert();
            else if (Trigger.isUpdate) handler.afterUpdate();
            else if (Trigger.isDelete) handler.afterDelete();
        }

        if (Trigger.isAfter && Trigger.isUndelete) {
            handler.afterUndelete();
        }
    }

    public class TriggerFactoryException extends Exception {}
}