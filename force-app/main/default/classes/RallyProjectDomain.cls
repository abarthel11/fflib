public with sharing class RallyProjectDomain extends fflib_SObjectDomain {
    public RallyProjectDomain(List<RallyProject__c> records) {
        super(records);
    }

    public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> sObjectList) {
            return new RallyProjectDomain((List<RallyProject__c>) sObjectList);
        }
    }

    public override void onApplyDefaults() {
        for (RallyProject__c projectRecord : projectRecords()) {
            if (String.isBlank(projectRecord.Status__c)) {
                projectRecord.Status__c = 'Active';
            }
            projectRecord.Key__c = generateKey(projectRecord);
        }
    }

    public override void onBeforeInsert() {
        validateProjects();
    }

    public override void onBeforeUpdate(Map<Id, SObject> existingRecords) {
        validateProjects();
    }

    private List<RallyProject__c> projectRecords() {
        return (List<RallyProject__c>) Records;
    }

    private void validateProjects() {
        for (RallyProject__c projectRecord : projectRecords()) {
            if (projectRecord.Start_Date__c != null
                && projectRecord.End_Date__c != null
                && projectRecord.Start_Date__c > projectRecord.End_Date__c) {
                projectRecord.End_Date__c.addError('End Date must be after Start Date.');
            }

            if (String.isBlank(projectRecord.Key__c)) {
                projectRecord.Key__c.addError('Project Key is required.');
            }
        }
    }

    private static String generateKey(RallyProject__c projectRecord) {
        String baseKey = !String.isBlank(projectRecord.Key__c)
            ? projectRecord.Key__c
            : projectRecord.Name;
        if (String.isBlank(baseKey)) {
            baseKey = 'RALLY';
        }
        baseKey = baseKey.replaceAll('[^A-Za-z0-9]', '').toUpperCase();
        if (String.isBlank(baseKey)) {
            baseKey = 'RALLY';
        }
        if (baseKey.length() > 12) {
            baseKey = baseKey.substring(0, 12);
        }
        return baseKey;
    }
}
