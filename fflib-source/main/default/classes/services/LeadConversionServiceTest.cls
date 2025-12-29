@IsTest
private class LeadConversionServiceTest
{
    private class StubMappingProvider implements LeadConversionMappingRule.IMappingProvider
    {
        private final List<LeadConversionMappingRule> rules;

        StubMappingProvider(List<LeadConversionMappingRule> rules)
        {
            this.rules = rules;
        }

        public List<LeadConversionMappingRule> fetchActiveRules()
        {
            return rules;
        }
    }

    @IsTest
    static void testStandardMappingToAccountAndContact()
    {
        Account accountRecord = LeadConversionTestDataFactory.createAccount('Base Account');
        Contact contactRecord = LeadConversionTestDataFactory.createContact(accountRecord.Id, 'Existing', 'Contact');
        Lead sourceLead = LeadConversionTestDataFactory.createLead('Acme Corporation', 'standard@example.com');
        Lead oldLead = sourceLead.clone(false, true, false, false);
        oldLead.Id = sourceLead.Id;
        oldLead.IsConverted = false;
        Lead convertedLead = LeadConversionTestDataFactory.buildConvertedLead(sourceLead, accountRecord, contactRecord, null);
        convertedLead.Company = 'ACME INDUSTRIES';
        convertedLead.Email = 'new-email@example.com';

        List<LeadConversionMappingRule> rules = new List<LeadConversionMappingRule>
        {
            LeadConversionMappingRule.forTest('Company', 'Account', 'Description', null, 'NONE'),
            LeadConversionMappingRule.forTest('Email', 'Contact', 'Email', null, 'NONE')
        };
        LeadConversionService service = new LeadConversionService(
            new LeadConversionMapper(),
            new StubMappingProvider(rules),
            new AccountSelector(),
            new ContactSelector(),
            new OpportunitySelector(),
            new LeadConversionService.DefaultDmlExecutor()
        );

        Test.startTest();
        service.handleAfterUpdate(new List<Lead>{ convertedLead }, new Map<Id, Lead>{ convertedLead.Id => oldLead });
        Test.stopTest();

        Account updatedAccount = [SELECT Description FROM Account WHERE Id = :accountRecord.Id];
        Contact updatedContact = [SELECT Email FROM Contact WHERE Id = :contactRecord.Id];
        System.assertEquals('ACME INDUSTRIES', updatedAccount.Description, 'Account description should mirror lead company');
        System.assertEquals('new-email@example.com', updatedContact.Email, 'Contact email should mirror lead');
    }

    @IsTest
    static void testConditionalMappingAndTransformation()
    {
        Account accountRecord = LeadConversionTestDataFactory.createAccount('Conditional Account');
        Contact contactRecord = LeadConversionTestDataFactory.createContact(accountRecord.Id, 'Original', 'Name');
        Lead sourceLead = LeadConversionTestDataFactory.createLead('SDK Corp', 'conditional@example.com');
        sourceLead.LeadSource = 'Partner';
        sourceLead.Phone = '(415) 555-9911';
        sourceLead.FirstName = 'SDK';
        sourceLead.LastName = 'Builder';
        update sourceLead;
        Lead oldLead = sourceLead.clone(false, true, false, false);
        oldLead.Id = sourceLead.Id;
        oldLead.IsConverted = false;
        Lead convertedLead = LeadConversionTestDataFactory.buildConvertedLead(sourceLead, accountRecord, contactRecord, null);
        convertedLead.LeadSource = 'Partner';
        convertedLead.Phone = '(415) 555-9911';

        List<LeadConversionMappingRule> rules = new List<LeadConversionMappingRule>
        {
            LeadConversionMappingRule.forTest('Phone', 'Account', 'Phone', 'LeadSource=Partner;NotBlank=Phone', 'PHONE_NORMALIZE'),
            LeadConversionMappingRule.forTest('Name', 'Contact', 'FirstName', 'LeadSource=Partner', 'FIRST_NAME'),
            LeadConversionMappingRule.forTest('Name', 'Contact', 'LastName', 'LeadSource=Partner', 'LAST_NAME')
        };

        LeadConversionService service = new LeadConversionService(
            new LeadConversionMapper(),
            new StubMappingProvider(rules),
            new AccountSelector(),
            new ContactSelector(),
            new OpportunitySelector(),
            new LeadConversionService.DefaultDmlExecutor()
        );

        Test.startTest();
        service.handleAfterUpdate(new List<Lead>{ convertedLead }, new Map<Id, Lead>{ convertedLead.Id => oldLead });
        Test.stopTest();

        Account updatedAccount = [SELECT Phone FROM Account WHERE Id = :accountRecord.Id];
        Contact updatedContact = [SELECT FirstName, LastName FROM Contact WHERE Id = :contactRecord.Id];
        System.assertEquals('4155559911', updatedAccount.Phone, 'Normalized phone should strip punctuation');
        System.assertEquals('SDK', updatedContact.FirstName, 'FIRST_NAME transform should map first token');
        System.assertEquals('Builder', updatedContact.LastName, 'LAST_NAME transform should map last token');
    }

    @IsTest
    static void testCustomObjectCreationDuringConversion()
    {
        Account accountRecord = LeadConversionTestDataFactory.createAccount('Audit Account');
        Contact contactRecord = LeadConversionTestDataFactory.createContact(accountRecord.Id, 'Audit', 'Contact');
        Opportunity opportunityRecord = LeadConversionTestDataFactory.createOpportunity(accountRecord.Id, 'Audit Opportunity');
        Lead sourceLead = LeadConversionTestDataFactory.createLead('Audit LLC', 'audit@example.com');
        Lead oldLead = sourceLead.clone(false, true, false, false);
        oldLead.Id = sourceLead.Id;
        oldLead.IsConverted = false;
        Lead convertedLead = LeadConversionTestDataFactory.buildConvertedLead(sourceLead, accountRecord, contactRecord, opportunityRecord);
        convertedLead.Status = 'Qualified';

        List<LeadConversionMappingRule> rules = new List<LeadConversionMappingRule>
        {
            LeadConversionMappingRule.forTest('Status', 'Custom:Lead_Conversion_Audit__c', 'Details__c', null, 'NONE'),
            LeadConversionMappingRule.forTest('Id', 'Custom:Lead_Conversion_Audit__c', 'Lead__c', null, 'NONE')
        };

        LeadConversionService service = new LeadConversionService(
            new LeadConversionMapper(),
            new StubMappingProvider(rules),
            new AccountSelector(),
            new ContactSelector(),
            new OpportunitySelector(),
            new LeadConversionService.DefaultDmlExecutor()
        );

        Test.startTest();
        service.handleAfterUpdate(new List<Lead>{ convertedLead }, new Map<Id, Lead>{ convertedLead.Id => oldLead });
        Test.stopTest();

        Lead_Conversion_Audit__c auditRecord = [SELECT Lead__c, Details__c FROM Lead_Conversion_Audit__c WHERE Lead__c = :convertedLead.Id LIMIT 1];
        System.assertEquals(convertedLead.Id, auditRecord.Lead__c, 'Audit record should reference the converted lead');
        System.assertEquals('Qualified', auditRecord.Details__c, 'Audit record should capture mapped status');
    }
}
