public with sharing class RallyProjectSelector extends fflib_SObjectSelector {
    public static RallyProjectSelector newInstance() {
        return new RallyProjectSelector();
    }

    public Schema.SObjectType getSObjectType() {
        return RallyProject__c.SObjectType;
    }

    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            RallyProject__c.Id,
            RallyProject__c.Name,
            RallyProject__c.Key__c,
            RallyProject__c.Status__c,
            RallyProject__c.Start_Date__c,
            RallyProject__c.End_Date__c,
            RallyProject__c.Description__c,
            RallyProject__c.Theme_Color__c
        };
    }

    public List<RallyProject__c> selectActiveProjects() {
        fflib_QueryFactory queryFactory = newQueryFactory();
        queryFactory.setCondition('Status__c = \'Active\'');
        queryFactory.addOrdering('Key__c', fflib_QueryFactory.SortOrder.ASCENDING);
        return (List<RallyProject__c>) Database.query(queryFactory.toSOQL());
    }

    public Map<Id, RallyProject__c> selectByIdMap(Set<Id> projectIds) {
        Map<Id, RallyProject__c> results = new Map<Id, RallyProject__c>();
        if (projectIds == null || projectIds.isEmpty()) {
            return results;
        }
        fflib_QueryFactory queryFactory = newQueryFactory();
        queryFactory.setCondition('Id IN :projectIds');
        for (RallyProject__c projectRecord : (List<RallyProject__c>) Database.query(queryFactory.toSOQL())) {
            results.put(projectRecord.Id, projectRecord);
        }
        return results;
    }
}
