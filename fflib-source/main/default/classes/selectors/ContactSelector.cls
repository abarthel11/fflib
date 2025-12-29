public with sharing class ContactSelector extends fflib_SObjectSelector implements ContactSelector.IContactSelector
{
    public interface IContactSelector extends fflib_ISObjectSelector
    {
        Map<Id, Contact> selectForConversion(Set<Id> contactIds, Set<String> requestedFields);
    }

    public override Schema.SObjectType getSObjectType()
    {
        return Contact.SObjectType;
    }

    public override List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField>{ Contact.Id };
    }

    public Map<Id, Contact> selectForConversion(Set<Id> contactIds, Set<String> requestedFields)
    {
        if (contactIds == null || contactIds.isEmpty())
        {
            return new Map<Id, Contact>();
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
        queryFactory.setCondition(buildIdCondition(contactIds));
        return new Map<Id, Contact>((List<Contact>) Database.query(queryFactory.toSOQL()));
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
