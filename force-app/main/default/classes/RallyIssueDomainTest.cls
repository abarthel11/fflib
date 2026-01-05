@IsTest
private class RallyIssueDomainTest {
    @IsTest
    static void sequenceAndKeyAssignedPerProject() {
        RallyProject__c projectRecord = new RallyProject__c(
            Name = 'Sequence Project',
            Key__c = 'SEQ',
            Status__c = 'Active'
        );
        insert projectRecord;

        List<RallyIssue__c> issueRecords = new List<RallyIssue__c>{
            new RallyIssue__c(
                Name = 'Issue A',
                Project__c = projectRecord.Id,
                Summary__c = 'Issue A',
                Issue_Type__c = 'Story',
                Priority__c = 'High',
                Status__c = 'Backlog'
            ),
            new RallyIssue__c(
                Name = 'Issue B',
                Project__c = projectRecord.Id,
                Summary__c = 'Issue B',
                Issue_Type__c = 'Story',
                Priority__c = 'High',
                Status__c = 'Backlog'
            )
        };

        insert issueRecords;

        List<RallyIssue__c> insertedIssues = [
            SELECT Issue_Key__c, Sequence__c
            FROM RallyIssue__c
            WHERE Id IN :new Map<Id, RallyIssue__c>(issueRecords).keySet()
            ORDER BY Sequence__c
        ];

        System.assertEquals(2, insertedIssues.size());
        System.assertEquals(1, insertedIssues[0].Sequence__c);
        System.assertEquals('SEQ-0001', insertedIssues[0].Issue_Key__c);
        System.assertEquals(2, insertedIssues[1].Sequence__c);
        System.assertEquals('SEQ-0002', insertedIssues[1].Issue_Key__c);
    }

    @IsTest
    static void blockedIssuesRequireReason() {
        RallyProject__c projectRecord = RallyTestDataFactory.createProject();
        RallyIssue__c issueRecord = new RallyIssue__c(
            Name = 'Blocked Issue',
            Project__c = projectRecord.Id,
            Summary__c = 'Blocked issue',
            Issue_Type__c = 'Story',
            Priority__c = 'High',
            Status__c = 'Backlog',
            Blocked__c = true
        );

        try {
            insert issueRecord;
            System.assert(false, 'Expected validation error.');
        } catch (DmlException caught) {
            System.assert(
                caught.getMessage().contains('Blocked issues require a reason'),
                caught.getMessage()
            );
        }
    }

    @IsTest
    static void invalidStatusTransitionsArePrevented() {
        RallyProject__c projectRecord = RallyTestDataFactory.createProject();
        RallyIssue__c issueRecord = new RallyIssue__c(
            Name = 'Transitioned Issue',
            Project__c = projectRecord.Id,
            Summary__c = 'Transitioned issue',
            Issue_Type__c = 'Story',
            Priority__c = 'High',
            Status__c = 'Done'
        );
        insert issueRecord;

        issueRecord.Status__c = 'Backlog';
        try {
            update issueRecord;
            System.assert(false, 'Transition should not be allowed.');
        } catch (DmlException caught) {
            System.assert(
                caught.getMessage().contains('Transition from Done to Backlog is not allowed'),
                caught.getMessage()
            );
        }
    }
}
