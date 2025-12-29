public with sharing class LeadSelector extends fflib_SObjectSelector
{
    public override Schema.SObjectType getSObjectType()
    {
        return Lead.SObjectType;
    }

    public override List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField>
        {
            Lead.Id,
            Lead.FirstName,
            Lead.LastName,
            Lead.Email,
            Lead.Company
        };
    }
}
