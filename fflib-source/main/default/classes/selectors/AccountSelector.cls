public with sharing class AccountSelector extends fflib_SObjectSelector implements AccountSelector.IAccountSelector
{
    public interface IAccountSelector extends fflib_ISObjectSelector
    {
        Map<Id, Account> selectForConversion(Set<Id> accountIds, Set<String> requestedFields);
    }

    public override Schema.SObjectType getSObjectType()
    {
        return Account.SObjectType;
    }

    public override List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField>{ Account.Id };
    }

    public Map<Id, Account> selectForConversion(Set<Id> accountIds, Set<String> requestedFields)
    {
        if (accountIds == null || accountIds.isEmpty())
        {
            return new Map<Id, Account>();
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
        queryFactory.setCondition(buildIdCondition(accountIds));
        return new Map<Id, Account>((List<Account>) Database.query(queryFactory.toSOQL()));
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
