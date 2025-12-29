public with sharing class LeadConversionService implements LeadConversionService.ILeadConversionService
{
    public interface ILeadConversionService
    {
        void handleAfterUpdate(List<Lead> leads, Map<Id, Lead> oldLeadById);
    }

    public interface IDmlExecutor
    {
        void updateRecords(List<SObject> records);
        void insertRecords(List<SObject> records);
    }

    public class DefaultDmlExecutor implements IDmlExecutor
    {
        public void updateRecords(List<SObject> records)
        {
            if (records == null || records.isEmpty())
            {
                return;
            }
            save(Database.update(records, false));
        }

        public void insertRecords(List<SObject> records)
        {
            if (records == null || records.isEmpty())
            {
                return;
            }
            save(Database.insert(records, false));
        }

        private void save(List<Database.SaveResult> results)
        {
            List<String> errors = new List<String>();
            for (Database.SaveResult result : results)
            {
                if (!result.isSuccess())
                {
                    for (Database.Error error : result.getErrors())
                    {
                        errors.add(error.getStatusCode() + ': ' + error.getMessage());
                    }
                }
            }
            if (!errors.isEmpty())
            {
                throw new LeadConversionServiceException(String.join(errors, ' | '));
            }
        }
    }

    public class LeadConversionServiceException extends Exception {}

    private final LeadConversionMapper mapper;
    private final LeadConversionMappingRule.IMappingProvider mappingProvider;
    private final AccountSelector.IAccountSelector accountSelector;
    private final ContactSelector.IContactSelector contactSelector;
    private final OpportunitySelector.IOpportunitySelector opportunitySelector;
    private final IDmlExecutor dmlExecutor;

    public LeadConversionService()
    {
        this(
            new LeadConversionMapper(),
            new LeadConversionMappingRule.CmdtMappingProvider(),
            new AccountSelector(),
            new ContactSelector(),
            new OpportunitySelector(),
            new DefaultDmlExecutor()
        );
    }

    public LeadConversionService(
        LeadConversionMapper mapper,
        LeadConversionMappingRule.IMappingProvider mappingProvider,
        AccountSelector.IAccountSelector accountSelector,
        ContactSelector.IContactSelector contactSelector,
        OpportunitySelector.IOpportunitySelector opportunitySelector,
        IDmlExecutor dmlExecutor)
    {
        this.mapper = mapper;
        this.mappingProvider = mappingProvider;
        this.accountSelector = accountSelector;
        this.contactSelector = contactSelector;
        this.opportunitySelector = opportunitySelector;
        this.dmlExecutor = dmlExecutor;
    }

    public void handleAfterUpdate(List<Lead> leads, Map<Id, Lead> oldLeadById)
    {
        if (leads == null || leads.isEmpty())
        {
            return;
        }
        List<Lead> convertedLeads = collectConvertedLeads(leads, oldLeadById);
        if (convertedLeads.isEmpty())
        {
            return;
        }
        List<LeadConversionMappingRule> rules = mappingProvider.fetchActiveRules();
        if (rules.isEmpty())
        {
            return;
        }
        Map<Id, String> recordTypeNames = fetchRecordTypeDeveloperNames(convertedLeads);
        Map<SObjectType, Set<String>> targetFieldsByType = collectTargetFields(rules);
        Map<Id, Account> accountsById = accountSelector.selectForConversion(collectTargetIds(convertedLeads, 'account'), targetFieldsByType.get(Account.SObjectType));
        Map<Id, Contact> contactsById = contactSelector.selectForConversion(collectTargetIds(convertedLeads, 'contact'), targetFieldsByType.get(Contact.SObjectType));
        Map<Id, Opportunity> opportunitiesById = opportunitySelector.selectForConversion(collectTargetIds(convertedLeads, 'opportunity'), targetFieldsByType.get(Opportunity.SObjectType));
        accountsById = accountsById == null ? new Map<Id, Account>() : accountsById;
        contactsById = contactsById == null ? new Map<Id, Contact>() : contactsById;
        opportunitiesById = opportunitiesById == null ? new Map<Id, Opportunity>() : opportunitiesById;

        List<LeadConversionContext> contexts = buildContexts(
            convertedLeads,
            recordTypeNames,
            accountsById,
            contactsById,
            opportunitiesById
        );

        mapper.map(contexts, rules);
        persistChanges(contexts);
    }

    private List<Lead> collectConvertedLeads(List<Lead> leads, Map<Id, Lead> oldLeadById)
    {
        List<Lead> converted = new List<Lead>();
        for (Lead candidate : leads)
        {
            if (candidate == null || !candidate.IsConverted)
            {
                continue;
            }
            Lead previously = oldLeadById == null ? null : oldLeadById.get(candidate.Id);
            if (previously != null && previously.IsConverted)
            {
                continue;
            }
            if (candidate.ConvertedAccountId == null
                && candidate.ConvertedContactId == null
                && candidate.ConvertedOpportunityId == null)
            {
                continue;
            }
            converted.add(candidate);
        }
        return converted;
    }

    private Map<Id, String> fetchRecordTypeDeveloperNames(List<Lead> leads)
    {
        Set<Id> recordTypeIds = new Set<Id>();
        for (Lead leadRecord : leads)
        {
            if (leadRecord.RecordTypeId != null)
            {
                recordTypeIds.add(leadRecord.RecordTypeId);
            }
        }
        Map<Id, String> results = new Map<Id, String>();
        if (recordTypeIds.isEmpty())
        {
            return results;
        }
        for (RecordType rt : [SELECT Id, DeveloperName FROM RecordType WHERE Id IN :recordTypeIds])
        {
            results.put(rt.Id, rt.DeveloperName);
        }
        return results;
    }

    private Map<SObjectType, Set<String>> collectTargetFields(List<LeadConversionMappingRule> rules)
    {
        Map<SObjectType, Set<String>> fieldsByType = new Map<SObjectType, Set<String>>();
        for (LeadConversionMappingRule rule : rules)
        {
            if (rule == null)
            {
                continue;
            }
            if (rule.requiresTargetAccess())
            {
                registerTargetField(fieldsByType, rule.getTargetSObjectType(), rule.getTargetFieldApi());
            }
            registerConditionTargetFields(fieldsByType, rule);
        }
        return fieldsByType;
    }

    private void registerTargetField(Map<SObjectType, Set<String>> fieldsByType, Schema.SObjectType typeToken, String fieldApiName)
    {
        if (typeToken == null || String.isBlank(fieldApiName))
        {
            return;
        }
        if (!fieldsByType.containsKey(typeToken))
        {
            fieldsByType.put(typeToken, new Set<String>());
        }
        fieldsByType.get(typeToken).add(fieldApiName);
    }

    private void registerConditionTargetFields(Map<SObjectType, Set<String>> fieldsByType, LeadConversionMappingRule rule)
    {
        if (rule == null || String.isBlank(rule.getConditionExpression()))
        {
            return;
        }
        for (String token : rule.getConditionExpression().split(';'))
        {
            if (String.isBlank(token))
            {
                continue;
            }
            String trimmed = token.trim().toLowerCase();
            if (!(trimmed.startsWith('targetblank=') || trimmed.startsWith('targetnotblank=')))
            {
                continue;
            }
            String descriptor = token.substring(token.indexOf('=') + 1).trim();
            Schema.SObjectType typeToken = resolveTargetTypeFromDescriptor(descriptor);
            String fieldApi = extractTargetFieldFromDescriptor(descriptor);
            registerTargetField(fieldsByType, typeToken, fieldApi);
        }
    }

    private Schema.SObjectType resolveTargetTypeFromDescriptor(String descriptor)
    {
        if (String.isBlank(descriptor) || !descriptor.contains('.'))
        {
            return null;
        }
        String token = descriptor.substring(0, descriptor.indexOf('.')).trim().toLowerCase();
        if (token == 'account')
        {
            return Account.SObjectType;
        }
        if (token == 'contact')
        {
            return Contact.SObjectType;
        }
        if (token == 'opportunity')
        {
            return Opportunity.SObjectType;
        }
        return null;
    }

    private String extractTargetFieldFromDescriptor(String descriptor)
    {
        if (String.isBlank(descriptor) || !descriptor.contains('.'))
        {
            return null;
        }
        return descriptor.substring(descriptor.indexOf('.') + 1).trim();
    }

    private Set<Id> collectTargetIds(List<Lead> leads, String objectToken)
    {
        Set<Id> ids = new Set<Id>();
        for (Lead leadRecord : leads)
        {
            if (objectToken == 'account' && leadRecord.ConvertedAccountId != null)
            {
                ids.add(leadRecord.ConvertedAccountId);
            }
            if (objectToken == 'contact' && leadRecord.ConvertedContactId != null)
            {
                ids.add(leadRecord.ConvertedContactId);
            }
            if (objectToken == 'opportunity' && leadRecord.ConvertedOpportunityId != null)
            {
                ids.add(leadRecord.ConvertedOpportunityId);
            }
        }
        return ids;
    }

    private List<LeadConversionContext> buildContexts(
        List<Lead> convertedLeads,
        Map<Id, String> recordTypeNames,
        Map<Id, Account> accountsById,
        Map<Id, Contact> contactsById,
        Map<Id, Opportunity> opportunitiesById)
    {
        List<LeadConversionContext> contexts = new List<LeadConversionContext>();
        for (Lead leadRecord : convertedLeads)
        {
            Account accountRecord = leadRecord.ConvertedAccountId == null
                ? null
                : accountsById.get(leadRecord.ConvertedAccountId);
            if (accountRecord == null && leadRecord.ConvertedAccountId != null)
            {
                accountRecord = new Account(Id = leadRecord.ConvertedAccountId);
            }
            Contact contactRecord = leadRecord.ConvertedContactId == null
                ? null
                : contactsById.get(leadRecord.ConvertedContactId);
            if (contactRecord == null && leadRecord.ConvertedContactId != null)
            {
                contactRecord = new Contact(Id = leadRecord.ConvertedContactId);
            }
            Opportunity opportunityRecord = leadRecord.ConvertedOpportunityId == null
                ? null
                : opportunitiesById.get(leadRecord.ConvertedOpportunityId);
            if (opportunityRecord == null && leadRecord.ConvertedOpportunityId != null)
            {
                opportunityRecord = new Opportunity(Id = leadRecord.ConvertedOpportunityId);
            }
            contexts.add(
                new LeadConversionContext(
                    leadRecord,
                    leadRecord.RecordTypeId == null ? null : recordTypeNames.get(leadRecord.RecordTypeId),
                    accountRecord,
                    contactRecord,
                    opportunityRecord
                )
            );
        }
        return contexts;
    }

    private void persistChanges(List<LeadConversionContext> contexts)
    {
        if (contexts == null || contexts.isEmpty())
        {
            return;
        }
        List<Account> accountsToUpdate = new List<Account>();
        List<Contact> contactsToUpdate = new List<Contact>();
        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
        List<SObject> customRecordsToInsert = new List<SObject>();
        for (LeadConversionContext context : contexts)
        {
            if (context.requiresAccountUpdate())
            {
                accountsToUpdate.add(context.AccountRecord);
            }
            if (context.requiresContactUpdate())
            {
                contactsToUpdate.add(context.ContactRecord);
            }
            if (context.requiresOpportunityUpdate())
            {
                opportunitiesToUpdate.add(context.OpportunityRecord);
            }
            customRecordsToInsert.addAll(context.getPendingCustomRecords());
        }
        dmlExecutor.updateRecords(new List<SObject>(accountsToUpdate));
        dmlExecutor.updateRecords(new List<SObject>(contactsToUpdate));
        dmlExecutor.updateRecords(new List<SObject>(opportunitiesToUpdate));
        dmlExecutor.insertRecords(customRecordsToInsert);
    }
}
