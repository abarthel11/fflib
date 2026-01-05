public with sharing class RallySprintSelector extends fflib_SObjectSelector {
    public static RallySprintSelector newInstance() {
        return new RallySprintSelector();
    }

    public Schema.SObjectType getSObjectType() {
        return RallySprint__c.SObjectType;
    }

    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            RallySprint__c.Id,
            RallySprint__c.Name,
            RallySprint__c.State__c,
            RallySprint__c.Start_Date__c,
            RallySprint__c.End_Date__c,
            RallySprint__c.Project__c,
            RallySprint__c.Goal__c,
            RallySprint__c.Capacity__c,
            RallySprint__c.Velocity_Target__c
        };
    }

    public Map<Id, RallySprint__c> selectByIdMap(Set<Id> sprintIds) {
        Map<Id, RallySprint__c> result = new Map<Id, RallySprint__c>();
        if (sprintIds == null || sprintIds.isEmpty()) {
            return result;
        }
        fflib_QueryFactory queryFactory = newQueryFactory();
        queryFactory.setCondition('Id IN :sprintIds');
        for (RallySprint__c sprintRecord : (List<RallySprint__c>) Database.query(queryFactory.toSOQL())) {
            result.put(sprintRecord.Id, sprintRecord);
        }
        return result;
    }

    public List<RallySprint__c> selectActiveByProject(Id projectId) {
        if (projectId == null) {
            return new List<RallySprint__c>();
        }
        fflib_QueryFactory queryFactory = newQueryFactory();
        queryFactory.setCondition('Project__c = :projectId AND State__c != \'Closed\'');
        queryFactory.addOrdering('Start_Date__c', fflib_QueryFactory.SortOrder.ASCENDING);
        return (List<RallySprint__c>) Database.query(queryFactory.toSOQL());
    }
}
