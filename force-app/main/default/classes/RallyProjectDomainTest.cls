@IsTest
private class RallyProjectDomainTest {
    @IsTest
    static void keyIsGeneratedFromProjectName() {
        RallyProject__c projectRecord = new RallyProject__c(
            Name = 'Alpha Launch',
            Status__c = 'Active'
        );

        insert projectRecord;

        RallyProject__c insertedProject = [
            SELECT Key__c, Status__c
            FROM RallyProject__c
            WHERE Id = :projectRecord.Id
        ];

        System.assertEquals('ALPHALAUNCH', insertedProject.Key__c, 'Key should be derived from name.');
        System.assertEquals('Active', insertedProject.Status__c);
    }

    @IsTest
    static void endDateMustFollowStartDate() {
        RallyProject__c projectRecord = new RallyProject__c(
            Name = 'Validation Project',
            Status__c = 'Active',
            Key__c = 'VAL',
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addDays(-1)
        );

        try {
            insert projectRecord;
            System.assert(false, 'Insert should fail validation.');
        } catch (DmlException caught) {
            System.assert(
                caught.getMessage().contains('End Date must be after Start Date'),
                caught.getMessage()
            );
        }
    }
}
