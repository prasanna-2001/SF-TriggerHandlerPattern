public class EventParticipationTriggerHandler extends TriggerHandler{
    private List<Events_Participants__c> newList;
    private List<Events_Participants__c> oldList;
    public override void setContext(List<SObject> newList, List<SObject> oldList) {
        this.newList = (List<Events_Participants__c>) newList;
        this.oldList = (List<Events_Participants__c>) oldList;
    }
	public override void beforeInsert() {
        attatchContactAndAccount(this.newList,this.oldList);
    }
    
    public static void attatchContactAndAccount(List<Events_Participants__c> newEpList, List<Events_Participants__c> oldEpList){
        System.debug('Hi');
            Set<String> compositeKeys = new Set<String>();
    Set<String> accountNames = new Set<String>();

    // Step 1: Build composite keys for email+phone and gather account names
    for (Events_Participants__c ep : newEpList) {
        if (String.isNotBlank(ep.Participant_Email__c) && String.isNotBlank(ep.Participant_Phone_Number__c)) {
            String compositeKey = ep.Participant_Email__c.trim().toLowerCase() + '|' + ep.Participant_Phone_Number__c.trim();
            compositeKeys.add(compositeKey);
        }

        if (String.isNotBlank(ep.Iskon_Location__c)) {
            accountNames.add(ep.Iskon_Location__c.trim());
        }
    }

    // Step 2: Query Contacts matching BOTH email AND phone
    Map<String, Contact> contactMap = new Map<String, Contact>();
    if (!compositeKeys.isEmpty()) {
        for (Contact c : [
            SELECT Id, Email, Phone 
            FROM Contact 
            WHERE Email != null AND Phone != null
        ]) {
            String key = c.Email.trim().toLowerCase() + '|' + c.Phone.trim();
            if (compositeKeys.contains(key)) {
                contactMap.put(key, c);
            }
        }
    }

    // Step 3: Query Accounts
    Map<String, Account> accountMap = new Map<String, Account>();
    if (!accountNames.isEmpty()) {
        for (Account acc : [
            SELECT Id, Name FROM Account WHERE Name IN :accountNames
        ]) {
            accountMap.put(acc.Name.trim(), acc);
        }
    }

    // Step 4: Match or create Contact and Account
    for (Events_Participants__c ep : newEpList) {
        String email = ep.Participant_Email__c != null ? ep.Participant_Email__c.trim().toLowerCase() : null;
        String phone = ep.Participant_Phone_Number__c != null ? ep.Participant_Phone_Number__c.trim() : null;
        String key = email != null && phone != null ? email + '|' + phone : null;

        if (key != null && contactMap.containsKey(key)) {
            // Existing contact found with matching email + phone
            ep.Contact__c = contactMap.get(key).Id;
        } else {
            // Account lookup or creation
            String location = ep.Iskon_Location__c != null ? ep.Iskon_Location__c.trim() : null;
            Account relatedAccount;

            if (location != null) {
                relatedAccount = accountMap.get(location);
                if (relatedAccount == null) {
                    relatedAccount = new Account(Name = location);
                    insert relatedAccount;
                    accountMap.put(location, relatedAccount);
                }
            }

            // Create new Contact
            Contact newContact = new Contact(
                LastName = ep.Participant_Name__c,
                
                Email = ep.Participant_Email__c,
                Phone = ep.Participant_Phone_Number__c,
                AccountId = relatedAccount != null ? relatedAccount.Id : null
            );
            insert newContact;

            ep.Contact__c = newContact.Id;

            // Add new contact to cache for future records in same batch
            if (key != null) {
                contactMap.put(key, newContact);
            }
        }
    }
}
}