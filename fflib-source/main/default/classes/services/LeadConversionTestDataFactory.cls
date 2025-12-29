@isTest
public with sharing class LeadConversionTestDataFactory
{
    public static Account createAccount(String name)
    {
        Account accountRecord = new Account(Name = name);
        insert accountRecord;
        return accountRecord;
    }

    public static Contact createContact(Id accountId, String firstName, String lastName)
    {
        Contact contactRecord = new Contact(
            AccountId = accountId,
            FirstName = firstName,
            LastName = lastName,
            Email = firstName.toLowerCase() + '@example.com'
        );
        insert contactRecord;
        return contactRecord;
    }

    public static Opportunity createOpportunity(Id accountId, String name)
    {
        Opportunity opportunityRecord = new Opportunity(
            AccountId = accountId,
            Name = name,
            StageName = 'Prospecting',
            CloseDate = System.today().addDays(30)
        );
        insert opportunityRecord;
        return opportunityRecord;
    }

    public static Lead buildConvertedLead(Lead baseLead, Account accountRecord, Contact contactRecord, Opportunity opportunityRecord)
    {
        Lead converted = baseLead.clone(false, true, false, false);
        converted.Id = baseLead.Id;
        converted.IsConverted = true;
        converted.ConvertedAccountId = accountRecord == null ? null : accountRecord.Id;
        converted.ConvertedContactId = contactRecord == null ? null : contactRecord.Id;
        converted.ConvertedOpportunityId = opportunityRecord == null ? null : opportunityRecord.Id;
        return converted;
    }

    public static Lead createLead(String company, String email)
    {
        Lead leadRecord = new Lead(
            LastName = 'Test Lead',
            Company = company,
            Status = 'Open - Not Contacted',
            Email = email,
            Phone = '415-555-0123'
        );
        insert leadRecord;
        return leadRecord;
    }
}
