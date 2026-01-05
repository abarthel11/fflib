public with sharing class RallyTestDataFactory {
    public static RallyProject__c createProject() {
        String suffix = String.valueOf(System.now().getTime());
        if (suffix.length() > 6) {
            suffix = suffix.substring(suffix.length() - 6);
        }
        RallyProject__c projectRecord = new RallyProject__c(
            Name = 'Rally Project ' + System.now().getTime(),
            Key__c = 'RP' + suffix
        );
        insert projectRecord;
        return projectRecord;
    }

    public static RallySprint__c createSprint(Id projectId) {
        RallySprint__c sprintRecord = new RallySprint__c(
            Name = 'Sprint ' + System.now().getTime(),
            Project__c = projectId,
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addDays(14),
            State__c = 'Planned'
        );
        insert sprintRecord;
        return sprintRecord;
    }

    public static RallyIssue__c createIssue(Id projectId, Id sprintId) {
        RallyIssue__c issueRecord = new RallyIssue__c(
            Name = 'Issue ' + System.now().getTime(),
            Project__c = projectId,
            Sprint__c = sprintId,
            Summary__c = 'Test Issue ' + System.now().getTime(),
            Issue_Type__c = 'Story',
            Priority__c = 'High',
            Status__c = 'Backlog'
        );
        insert issueRecord;
        return issueRecord;
    }
}
