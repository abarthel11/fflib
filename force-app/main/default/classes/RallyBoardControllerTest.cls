@IsTest
private class RallyBoardControllerTest {
    @IsTest
    static void getActiveProjectsAndBacklog() {
        RallyProject__c projectRecord = RallyTestDataFactory.createProject();
        RallySprint__c sprintRecord = RallyTestDataFactory.createSprint(projectRecord.Id);
        RallyIssue__c backlogIssue = RallyTestDataFactory.createIssue(projectRecord.Id, null);
        backlogIssue.Status__c = 'Backlog';
        backlogIssue.Sprint__c = null;
        update backlogIssue;
        RallyIssue__c sprintIssue = RallyTestDataFactory.createIssue(projectRecord.Id, sprintRecord.Id);
        sprintIssue.Status__c = 'In Progress';
        update sprintIssue;

        Test.startTest();
        List<RallyProject__c> projects = RallyBoardController.getActiveProjects();
        List<RallySprint__c> sprints = RallyBoardController.getActiveSprints(projectRecord.Id);
        List<RallyIssue__c> backlog = RallyBoardController.getBacklog(projectRecord.Id);
        List<RallyIssue__c> sprintBoard = RallyBoardController.getSprintBoard(projectRecord.Id, sprintRecord.Id);
        List<RallyIssue__c> projectBoard = RallyBoardController.getProjectBoard(projectRecord.Id);
        Test.stopTest();

        System.assert(!projects.isEmpty(), 'Expected at least one active project.');
        System.assertEquals(1, sprints.size(), 'Only one sprint expected.');
        System.assertEquals(1, backlog.size(), 'Only backlog issue should appear.');
        System.assertEquals(1, sprintBoard.size(), 'Sprint board should include sprint issue.');
        System.assertEquals(2, projectBoard.size(), 'Project board includes both issues.');
    }

    @IsTest
    static void moveIssuesToStatusUpdatesFromBoardController() {
        RallyProject__c projectRecord = RallyTestDataFactory.createProject();
        RallyIssue__c issueRecord = RallyTestDataFactory.createIssue(projectRecord.Id, null);

        Test.startTest();
        List<RallyIssue__c> updated = RallyBoardController.moveIssuesToStatus(
            new List<Id>{issueRecord.Id},
            'In Progress'
        );
        Test.stopTest();

        System.assertEquals(1, updated.size(), 'One record should move.');
        System.assertEquals('In Progress', updated[0].Status__c);
    }

    @IsTest
    static void getIssueStatusesDescribesPicklist() {
        Test.startTest();
        List<String> statuses = RallyBoardController.getIssueStatuses();
        Test.stopTest();
        System.assert(statuses.contains('Backlog'), 'Expected Backlog option.');
    }
}
