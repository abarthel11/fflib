@IsTest
private class RallyIssueServiceTest {
    @IsTest
    static void createIssuesPersistsRecordsAndDefaults() {
        RallyProject__c projectRecord = RallyTestDataFactory.createProject();
        RallySprint__c sprintRecord = RallyTestDataFactory.createSprint(projectRecord.Id);

        RallyIssueService.IssueInput firstInput = new RallyIssueService.IssueInput()
            .withProject(projectRecord.Id)
            .withSummary('First story')
            .withIssueType('Story')
            .withPriority('Medium')
            .withStoryPoints(5);

        RallyIssueService.IssueInput secondInput = new RallyIssueService.IssueInput()
            .withProject(projectRecord.Id)
            .withSprint(sprintRecord.Id)
            .withSummary('Second story')
            .withIssueType('Bug')
            .withPriority('High')
            .withStatus('In Progress');

        Test.startTest();
        List<RallyIssue__c> newIssues = new RallyIssueService().createIssues(
            new List<RallyIssueService.IssueInput>{firstInput, secondInput}
        );
        Test.stopTest();

        System.assertEquals(2, newIssues.size(), 'Two issues should have been returned.');

        List<RallyIssue__c> persistedIssues = [
            SELECT Status__c, Sprint__c, Issue_Type__c, Priority__c
            FROM RallyIssue__c
            WHERE Id IN :new Map<Id, RallyIssue__c>(newIssues).keySet()
        ];

        System.assertEquals(2, persistedIssues.size());
        Boolean sprintLinked = false;
        for (RallyIssue__c issueRecord : persistedIssues) {
            if (issueRecord.Sprint__c == sprintRecord.Id) {
                sprintLinked = true;
            }
        }
        System.assert(sprintLinked, 'Expected one issue to be tied to the sprint.');
    }

    @IsTest
    static void moveIssuesToStatusUpdatesRecords() {
        RallyProject__c projectRecord = RallyTestDataFactory.createProject();
        RallyIssue__c issueRecord = RallyTestDataFactory.createIssue(projectRecord.Id, null);

        Test.startTest();
        new RallyIssueService().moveIssuesToStatus(new Set<Id>{issueRecord.Id}, 'In Progress');
        Test.stopTest();

        RallyIssue__c updatedIssue = [
            SELECT Status__c
            FROM RallyIssue__c
            WHERE Id = :issueRecord.Id
        ];

        System.assertEquals('In Progress', updatedIssue.Status__c);
    }

    @IsTest
    static void createIssuesValidatesSprintOwnership() {
        RallyProject__c firstProject = RallyTestDataFactory.createProject();
        RallyProject__c secondProject = RallyTestDataFactory.createProject();
        RallySprint__c sprintRecord = RallyTestDataFactory.createSprint(firstProject.Id);

        RallyIssueService.IssueInput invalidInput = new RallyIssueService.IssueInput()
            .withProject(secondProject.Id)
            .withSprint(sprintRecord.Id)
            .withSummary('Bad sprint selection')
            .withIssueType('Bug');

        Boolean threwException = false;
        try {
            new RallyIssueService().createIssues(new List<RallyIssueService.IssueInput>{invalidInput});
        } catch (fflib_SObjectDomain.DomainException caught) {
            threwException = true;
            System.assert(
                caught.getMessage().contains('Sprint does not belong'),
                caught.getMessage()
            );
        }
        System.assert(threwException, 'Expected domain exception when sprint belongs to another project.');
    }
}
