trigger RallyProjectTrigger on RallyProject__c (
    before insert,
    before update
) {
    fflib_SObjectDomain.triggerHandler(RallyProjectDomain.class);
}
