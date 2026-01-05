public with sharing class RallyIssueSelector extends fflib_SObjectSelector {
    public static RallyIssueSelector newInstance() {
        return new RallyIssueSelector();
    }

    public Schema.SObjectType getSObjectType() {
        return RallyIssue__c.SObjectType;
    }

    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            RallyIssue__c.Id,
            RallyIssue__c.Name,
            RallyIssue__c.Issue_Key__c,
            RallyIssue__c.Sequence__c,
            RallyIssue__c.Project__c,
            RallyIssue__c.Sprint__c,
            RallyIssue__c.Summary__c,
            RallyIssue__c.Description__c,
            RallyIssue__c.Issue_Type__c,
            RallyIssue__c.Priority__c,
            RallyIssue__c.Status__c,
            RallyIssue__c.Story_Points__c,
            RallyIssue__c.Assignee__c,
            RallyIssue__c.Reporter__c,
            RallyIssue__c.Due_Date__c,
            RallyIssue__c.Blocked__c,
            RallyIssue__c.BlockedReason__c
        };
    }

    public List<RallyIssue__c> selectBacklogByProject(Id projectId) {
        if (projectId == null) {
            return new List<RallyIssue__c>();
        }
        fflib_QueryFactory queryFactory = newQueryFactory();
        queryFactory.setCondition('Project__c = :projectId AND Status__c = \'Backlog\'');
        queryFactory.addOrdering('Sequence__c', fflib_QueryFactory.SortOrder.ASCENDING);
        selectBoardFields(queryFactory);
        return (List<RallyIssue__c>) Database.query(queryFactory.toSOQL());
    }

    public List<RallyIssue__c> selectSprintBoard(Id projectId, Id sprintId) {
        if (projectId == null || sprintId == null) {
            return new List<RallyIssue__c>();
        }
        fflib_QueryFactory queryFactory = newQueryFactory();
        queryFactory.setCondition('Project__c = :projectId AND Sprint__c = :sprintId');
        queryFactory.addOrdering('Status__c', fflib_QueryFactory.SortOrder.ASCENDING);
        queryFactory.addOrdering('Sequence__c', fflib_QueryFactory.SortOrder.ASCENDING);
        selectBoardFields(queryFactory);
        return (List<RallyIssue__c>) Database.query(queryFactory.toSOQL());
    }

    public List<RallyIssue__c> selectProjectBoard(Id projectId) {
        if (projectId == null) {
            return new List<RallyIssue__c>();
        }
        fflib_QueryFactory queryFactory = newQueryFactory();
        queryFactory.setCondition('Project__c = :projectId');
        queryFactory.addOrdering('Status__c', fflib_QueryFactory.SortOrder.ASCENDING);
        queryFactory.addOrdering('Sequence__c', fflib_QueryFactory.SortOrder.ASCENDING);
        selectBoardFields(queryFactory);
        return (List<RallyIssue__c>) Database.query(queryFactory.toSOQL());
    }

    public List<RallyIssue__c> selectByIds(Set<Id> issueIds) {
        if (issueIds == null || issueIds.isEmpty()) {
            return new List<RallyIssue__c>();
        }
        List<RallyIssue__c> results = new List<RallyIssue__c>();
        for (SObject record : selectSObjectsById(issueIds)) {
            results.add((RallyIssue__c) record);
        }
        return results;
    }

    public Map<Id, Integer> selectMaxSequenceByProject(Set<Id> projectIds) {
        Map<Id, Integer> result = new Map<Id, Integer>();
        if (projectIds == null || projectIds.isEmpty()) {
            return result;
        }
        for (AggregateResult aggregateResult : [
            SELECT Project__c projectId, MAX(Sequence__c) maxSequence
            FROM RallyIssue__c
            WHERE Project__c IN :projectIds
            GROUP BY Project__c
        ]) {
            Decimal maxValue = (Decimal) aggregateResult.get('maxSequence');
            result.put(
                (Id) aggregateResult.get('projectId'),
                maxValue == null ? 0 : maxValue.intValue()
            );
        }
        return result;
    }

    private void selectBoardFields(fflib_QueryFactory queryFactory) {
        queryFactory.selectField('Assignee__r.Name');
        queryFactory.selectField('Reporter__r.Name');
        queryFactory.selectField('Sprint__r.Name');
        queryFactory.selectField('Project__r.Name');
        queryFactory.selectField('Project__r.Theme_Color__c');
    }
}
