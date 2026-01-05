trigger RallySprintTrigger on RallySprint__c (
    before insert,
    before update
) {
    fflib_SObjectDomain.triggerHandler(RallySprintDomain.class);
}
