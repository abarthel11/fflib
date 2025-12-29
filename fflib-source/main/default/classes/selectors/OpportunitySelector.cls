public with sharing class OpportunitySelector extends fflib_SObjectSelector implements OpportunitySelector.IOpportunitySelector
{
    public interface IOpportunitySelector extends fflib_ISObjectSelector
    {
        Map<Id, Opportunity> selectForConversion(Set<Id> opportunityIds, Set<String> requestedFields);
    }

    public override Schema.SObjectType getSObjectType()
    {
        return Opportunity.SObjectType;
    }

    public override List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField>{ Opportunity.Id };
    }

    public Map<Id, Opportunity> selectForConversion(Set<Id> opportunityIds, Set<String> requestedFields)
    {
        if (opportunityIds == null || opportunityIds.isEmpty())
        {
            return new Map<Id, Opportunity>();
        }
        fflib_QueryFactory queryFactory = newQueryFactory(false);
        queryFactory.selectField('Id');
        if (requestedFields != null)
        {
            for (String fieldName : requestedFields)
            {
                if (!String.isBlank(fieldName) && !fieldName.equalsIgnoreCase('id'))
                {
                    queryFactory.selectField(fieldName);
                }
            }
        }
        queryFactory.setCondition(buildIdCondition(opportunityIds));
        return new Map<Id, Opportunity>((List<Opportunity>) Database.query(queryFactory.toSOQL()));
    }

    private String buildIdCondition(Set<Id> ids)
    {
        List<String> tokens = new List<String>();
        for (Id recordId : ids)
        {
            tokens.add('\'' + String.valueOf(recordId) + '\'');
        }
        return 'Id IN (' + String.join(tokens, ',') + ')';
    }
}
