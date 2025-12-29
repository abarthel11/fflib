public with sharing class LeadDomain extends fflib_SObjectDomain
{
    public LeadDomain(List<Lead> records)
    {
        super(records);
    }

    public override void onAfterUpdate()
    {
        LeadConversionApplication.leadConversionService().handleAfterUpdate(
            (List<Lead>) Records,
            getExistingLeadRecords()
        );
    }

    private Map<Id, Lead> getExistingLeadRecords()
    {
        Map<Id, SObject> rawExisting = ExistingRecords;
        Map<Id, Lead> leads = new Map<Id, Lead>();
        if (rawExisting == null)
        {
            return leads;
        }
        for (Id recordId : rawExisting.keySet())
        {
            leads.put(recordId, (Lead) rawExisting.get(recordId));
        }
        return leads;
    }
}
