public with sharing class LeadConversionContext
{
    public Lead LeadRecord { get; private set; }
    public String LeadRecordTypeDeveloperName { get; private set; }
    public Account AccountRecord { get; private set; }
    public Contact ContactRecord { get; private set; }
    public Opportunity OpportunityRecord { get; private set; }

    private Boolean accountDirty;
    private Boolean contactDirty;
    private Boolean opportunityDirty;
    private Map<SObjectType, SObject> customRecordByType = new Map<SObjectType, SObject>();

    public LeadConversionContext(
        Lead leadRecord,
        String recordTypeDeveloperName,
        Account accountRecord,
        Contact contactRecord,
        Opportunity opportunityRecord)
    {
        LeadRecord = leadRecord;
        LeadRecordTypeDeveloperName = recordTypeDeveloperName;
        AccountRecord = accountRecord;
        ContactRecord = contactRecord;
        OpportunityRecord = opportunityRecord;
    }

    public Account ensureAccount()
    {
        if (AccountRecord == null && LeadRecord.ConvertedAccountId != null)
        {
            AccountRecord = new Account(Id = LeadRecord.ConvertedAccountId);
        }
        return AccountRecord;
    }

    public Contact ensureContact()
    {
        if (ContactRecord == null && LeadRecord.ConvertedContactId != null)
        {
            ContactRecord = new Contact(Id = LeadRecord.ConvertedContactId);
        }
        return ContactRecord;
    }

    public Opportunity ensureOpportunity()
    {
        if (OpportunityRecord == null && LeadRecord.ConvertedOpportunityId != null)
        {
            OpportunityRecord = new Opportunity(Id = LeadRecord.ConvertedOpportunityId);
        }
        return OpportunityRecord;
    }

    public void markAccountDirty()
    {
        accountDirty = true;
    }

    public void markContactDirty()
    {
        contactDirty = true;
    }

    public void markOpportunityDirty()
    {
        opportunityDirty = true;
    }

    public Boolean requiresAccountUpdate()
    {
        return accountDirty && AccountRecord != null;
    }

    public Boolean requiresContactUpdate()
    {
        return contactDirty && ContactRecord != null;
    }

    public Boolean requiresOpportunityUpdate()
    {
        return opportunityDirty && OpportunityRecord != null;
    }

    public Boolean hasAccountTarget()
    {
        return LeadRecord.ConvertedAccountId != null;
    }

    public Boolean hasContactTarget()
    {
        return LeadRecord.ConvertedContactId != null;
    }

    public Boolean hasOpportunityTarget()
    {
        return LeadRecord.ConvertedOpportunityId != null;
    }

    public Object getLeadValue(String fieldApiName)
    {
        if (String.isBlank(fieldApiName))
        {
            return null;
        }
        if (fieldApiName.equalsIgnoreCase('RecordType.DeveloperName'))
        {
            return LeadRecordTypeDeveloperName;
        }
        return LeadRecord.get(fieldApiName);
    }

    public Object getTargetValue(String descriptor)
    {
        if (String.isBlank(descriptor) || !descriptor.contains('.'))
        {
            return null;
        }
        List<String> pieces = descriptor.split('\\.');
        if (pieces.size() != 2)
        {
            return null;
        }
        SObject target = resolveTargetRecord(pieces[0]);
        return target == null ? null : target.get(pieces[1]);
    }

    public SObject getOrCreateCustomRecord(Schema.SObjectType typeToken)
    {
        if (typeToken == null)
        {
            return null;
        }
        if (!customRecordByType.containsKey(typeToken))
        {
            customRecordByType.put(typeToken, typeToken.newSObject(null, true));
        }
        return customRecordByType.get(typeToken);
    }

    public List<SObject> getPendingCustomRecords()
    {
        return new List<SObject>(customRecordByType.values());
    }

    private SObject resolveTargetRecord(String token)
    {
        if (String.isBlank(token))
        {
            return null;
        }
        if (token.equalsIgnoreCase('Account'))
        {
            return AccountRecord;
        }
        if (token.equalsIgnoreCase('Contact'))
        {
            return ContactRecord;
        }
        if (token.equalsIgnoreCase('Opportunity'))
        {
            return OpportunityRecord;
        }
        return null;
    }
}
