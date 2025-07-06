trigger EventParticipationTrigger on Events_Participants__c (before insert, before update) {
    TriggerFactory.run('Events_Participants__c', Trigger.new, Trigger.old);
}