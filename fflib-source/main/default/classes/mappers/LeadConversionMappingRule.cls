public with sharing class LeadConversionMappingRule
{
    public enum TargetObjectKind
    {
        ACCOUNT,
        CONTACT,
        OPPORTUNITY,
        CUSTOM
    }

    public interface IMappingProvider
    {
        List<LeadConversionMappingRule> fetchActiveRules();
    }

    public class CmdtMappingProvider implements IMappingProvider
    {
        public List<LeadConversionMappingRule> fetchActiveRules()
        {
            List<LeadConversionMappingRule> rules = new List<LeadConversionMappingRule>();
            for (Lead_Field_Mapping__mdt mapping : [
                SELECT DeveloperName,
                    Active__c,
                    Condition_Expression__c,
                    Source_Field_API__c,
                    Target_Field_API__c,
                    Target_Object__c,
                    Transform__c
                FROM Lead_Field_Mapping__mdt
                WHERE Active__c = true
                ORDER BY DeveloperName
            ])
            {
                rules.add(new LeadConversionMappingRule(mapping));
            }
            return rules;
        }
    }

    private final String sourceFieldApi;
    private final String targetObjectDescriptor;
    private final String targetFieldApi;
    private final String conditionExpression;
    private final String transformName;
    private final Boolean active;
    private TargetObjectKind targetKind;
    private Schema.SObjectType cachedCustomType;

    public LeadConversionMappingRule(Lead_Field_Mapping__mdt record)
    {
        this(
            record.Source_Field_API__c,
            record.Target_Object__c,
            record.Target_Field_API__c,
            record.Condition_Expression__c,
            record.Transform__c,
            record.Active__c
        );
    }

    private LeadConversionMappingRule(
        String sourceFieldApi,
        String targetObjectDescriptor,
        String targetFieldApi,
        String conditionExpression,
        String transformName,
        Boolean active)
    {
        this.sourceFieldApi = sourceFieldApi;
        this.targetObjectDescriptor = targetObjectDescriptor;
        this.targetFieldApi = targetFieldApi;
        this.conditionExpression = conditionExpression;
        this.transformName = String.isBlank(transformName) ? 'NONE' : transformName.trim();
        this.active = active == null ? true : active;
        this.targetKind = resolveTargetKind(targetObjectDescriptor);
    }

    @TestVisible
    public static LeadConversionMappingRule forTest(
        String sourceField,
        String targetObjectToken,
        String targetField,
        String conditionExpression,
        String transformName)
    {
        return new LeadConversionMappingRule(sourceField, targetObjectToken, targetField, conditionExpression, transformName, true);
    }

    public Boolean isActive()
    {
        return active;
    }

    public String getSourceFieldApi()
    {
        return sourceFieldApi;
    }

    public String getTargetFieldApi()
    {
        return targetFieldApi;
    }

    public String getTransformName()
    {
        return transformName;
    }

    public String getConditionExpression()
    {
        return conditionExpression;
    }

    public TargetObjectKind getTargetKind()
    {
        return targetKind;
    }

    public Schema.SObjectType getTargetSObjectType()
    {
        if (targetKind == TargetObjectKind.ACCOUNT)
        {
            return Account.SObjectType;
        }
        if (targetKind == TargetObjectKind.CONTACT)
        {
            return Contact.SObjectType;
        }
        if (targetKind == TargetObjectKind.OPPORTUNITY)
        {
            return Opportunity.SObjectType;
        }
        if (targetKind == TargetObjectKind.CUSTOM)
        {
            return resolveCustomSObjectType();
        }
        return null;
    }

    public Boolean appliesTo(LeadConversionContext context)
    {
        if (!active)
        {
            return false;
        }
        if (context == null)
        {
            return false;
        }
        return evaluateConditions(context);
    }

    public Boolean requiresTargetAccess()
    {
        return targetKind != TargetObjectKind.CUSTOM;
    }

    public String getTargetDescriptor()
    {
        return targetObjectDescriptor;
    }

    private Boolean evaluateConditions(LeadConversionContext context)
    {
        if (String.isBlank(conditionExpression))
        {
            return true;
        }
        for (String token : conditionExpression.split(';'))
        {
            if (String.isBlank(token))
            {
                continue;
            }
            if (!evaluateConditionToken(token.trim(), context))
            {
                return false;
            }
        }
        return true;
    }

    private Boolean evaluateConditionToken(String token, LeadConversionContext context)
    {
        if (token.toLowerCase().startsWith('notblank='))
        {
            Object value = context.getLeadValue(token.substring('notblank='.length()));
            return !isBlank(value);
        }
        if (token.toLowerCase().startsWith('blank='))
        {
            Object value = context.getLeadValue(token.substring('blank='.length()));
            return isBlank(value);
        }
        if (token.toLowerCase().startsWith('targetblank='))
        {
            Object value = context.getTargetValue(token.substring('targetblank='.length()));
            return isBlank(value);
        }
        if (token.toLowerCase().startsWith('targetnotblank='))
        {
            Object value = context.getTargetValue(token.substring('targetnotblank='.length()));
            return !isBlank(value);
        }
        if (token.toLowerCase().startsWith('recordtype='))
        {
            String expectedName = token.substring('recordtype='.length()).trim();
            return String.isBlank(expectedName)
                ? true
                : expectedName.equalsIgnoreCase(context.LeadRecordTypeDeveloperName);
        }

        Integer operatorIndex = token.indexOf('!=');
        String operator = '!=';
        if (operatorIndex == -1)
        {
            operatorIndex = token.indexOf('=');
            operator = '=';
        }
        if (operatorIndex == -1)
        {
            return true;
        }
        String left = token.substring(0, operatorIndex).trim();
        String right = token.substring(operatorIndex + operator.length()).trim();
        Object leadValue = context.getLeadValue(left);
        if ('!='.equals(operator))
        {
            return !equalsIgnoreCase(leadValue, right);
        }
        return equalsIgnoreCase(leadValue, right);
    }

    private static Boolean equalsIgnoreCase(Object value, String expected)
    {
        if (value == null && String.isBlank(expected))
        {
            return true;
        }
        if (value == null)
        {
            return false;
        }
        return String.valueOf(value).equalsIgnoreCase(expected);
    }

    public static Boolean isBlank(Object value)
    {
        if (value == null)
        {
            return true;
        }
        if (value instanceof String)
        {
            return String.isBlank((String) value);
        }
        return false;
    }

    private Schema.SObjectType resolveCustomSObjectType()
    {
        if (cachedCustomType != null)
        {
            return cachedCustomType;
        }
        Map<String, Schema.SObjectType> describe = Schema.getGlobalDescribe();
        String apiName = extractCustomObjectApiName();
        cachedCustomType = describe.containsKey(apiName) ? describe.get(apiName) : null;
        return cachedCustomType;
    }

    private String extractCustomObjectApiName()
    {
        if (String.isBlank(targetObjectDescriptor))
        {
            return null;
        }
        if (targetObjectDescriptor.contains(':'))
        {
            return targetObjectDescriptor.substring(targetObjectDescriptor.indexOf(':') + 1).trim();
        }
        return targetObjectDescriptor.trim();
    }

    private TargetObjectKind resolveTargetKind(String descriptor)
    {
        if (String.isBlank(descriptor))
        {
            return TargetObjectKind.ACCOUNT;
        }
        String token = descriptor.trim().toLowerCase();
        if (token.startsWith('account'))
        {
            return TargetObjectKind.ACCOUNT;
        }
        if (token.startsWith('contact'))
        {
            return TargetObjectKind.CONTACT;
        }
        if (token.startsWith('opportunity'))
        {
            return TargetObjectKind.OPPORTUNITY;
        }
        if (token.startsWith('custom'))
        {
            return TargetObjectKind.CUSTOM;
        }
        return TargetObjectKind.CUSTOM;
    }
}
