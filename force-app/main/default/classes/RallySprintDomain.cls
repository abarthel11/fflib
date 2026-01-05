public with sharing class RallySprintDomain extends fflib_SObjectDomain {
    public RallySprintDomain(List<RallySprint__c> records) {
        super(records);
    }

    public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> sObjectList) {
            return new RallySprintDomain((List<RallySprint__c>) sObjectList);
        }
    }

    public override void onApplyDefaults() {
        for (RallySprint__c sprintRecord : sprintRecords()) {
            if (String.isBlank(sprintRecord.State__c)) {
                sprintRecord.State__c = 'Planned';
            }
        }
    }

    public override void onBeforeInsert() {
        validateSprints();
    }

    public override void onBeforeUpdate(Map<Id, SObject> existingRecords) {
        validateSprints();
    }

    private List<RallySprint__c> sprintRecords() {
        return (List<RallySprint__c>) Records;
    }

    private void validateSprints() {
        for (RallySprint__c sprintRecord : sprintRecords()) {
            if (sprintRecord.Start_Date__c != null
                && sprintRecord.End_Date__c != null
                && sprintRecord.Start_Date__c > sprintRecord.End_Date__c) {
                sprintRecord.End_Date__c.addError('End Date must be after Start Date.');
            }
            if (sprintRecord.Project__c == null) {
                sprintRecord.Project__c.addError('A sprint must belong to a project.');
            }
        }
    }
}
