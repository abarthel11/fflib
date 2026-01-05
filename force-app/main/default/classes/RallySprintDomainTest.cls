@IsTest
private class RallySprintDomainTest {
    @IsTest
    static void sprintDefaultsStateDuringInsert() {
        RallyProject__c projectRecord = RallyTestDataFactory.createProject();
        RallySprint__c sprintRecord = new RallySprint__c(
            Name = 'Sprint Defaults',
            Project__c = projectRecord.Id,
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addDays(7)
        );

        insert sprintRecord;

        RallySprint__c insertedSprint = [
            SELECT State__c
            FROM RallySprint__c
            WHERE Id = :sprintRecord.Id
        ];

        System.assertEquals('Planned', insertedSprint.State__c);
    }

    @IsTest
    static void sprintRequiresValidDateRange() {
        RallyProject__c projectRecord = RallyTestDataFactory.createProject();
        RallySprint__c sprintRecord = new RallySprint__c(
            Name = 'Broken Sprint',
            Project__c = projectRecord.Id,
            Start_Date__c = Date.today().addDays(14),
            End_Date__c = Date.today()
        );

        try {
            insert sprintRecord;
            System.assert(false, 'Expected validation failure.');
        } catch (DmlException caught) {
            System.assert(
                caught.getMessage().contains('End Date must be after Start Date'),
                caught.getMessage()
            );
        }
    }
}
