trigger RallyIssueTrigger on RallyIssue__c (
    before insert,
    before update
) {
    fflib_SObjectDomain.triggerHandler(RallyIssueDomain.class);
}
