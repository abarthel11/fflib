public with sharing class RallyBoardController {
    @AuraEnabled(cacheable=true)
    public static List<RallyProject__c> getActiveProjects() {
        return RallyProjectSelector.newInstance().selectActiveProjects();
    }

    @AuraEnabled(cacheable=true)
    public static List<RallySprint__c> getActiveSprints(Id projectId) {
        return RallySprintSelector.newInstance().selectActiveByProject(projectId);
    }

    @AuraEnabled(cacheable=true)
    public static List<RallyIssue__c> getBacklog(Id projectId) {
        return new RallyIssueService().getBacklog(projectId);
    }

    @AuraEnabled(cacheable=true)
    public static List<RallyIssue__c> getSprintBoard(Id projectId, Id sprintId) {
        return new RallyIssueService().getSprintBoard(projectId, sprintId);
    }

    @AuraEnabled(cacheable=true)
    public static List<RallyIssue__c> getProjectBoard(Id projectId) {
        return new RallyIssueService().getProjectBoard(projectId);
    }

    @AuraEnabled
    public static List<RallyIssue__c> moveIssuesToStatus(List<Id> issueIds, String status) {
        if (issueIds == null || issueIds.isEmpty()) {
            return new List<RallyIssue__c>();
        }
        return new RallyIssueService().moveIssuesToStatus(new Set<Id>(issueIds), status);
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getIssueStatuses() {
        List<String> statuses = new List<String>();
        Schema.DescribeFieldResult describeResult = RallyIssue__c.Status__c.getDescribe();
        for (Schema.PicklistEntry entry : describeResult.getPicklistValues()) {
            statuses.add(entry.getValue());
        }
        return statuses;
    }
}
