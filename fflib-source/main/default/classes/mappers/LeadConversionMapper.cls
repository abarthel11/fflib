public with sharing class LeadConversionMapper
{
    public interface IValueTransformer
    {
        Object transform(Object value, LeadConversionContext context, LeadConversionMappingRule rule);
    }

    private Map<String, IValueTransformer> transformers;

    public LeadConversionMapper()
    {
        this(buildDefaultTransformers());
    }

    public LeadConversionMapper(Map<String, IValueTransformer> transformers)
    {
        this.transformers = transformers == null ? buildDefaultTransformers() : transformers;
    }

    public void registerTransformer(String name, IValueTransformer transformer)
    {
        if (String.isBlank(name) || transformer == null)
        {
            return;
        }
        transformers.put(name.toUpperCase(), transformer);
    }

    public void map(List<LeadConversionContext> contexts, List<LeadConversionMappingRule> rules)
    {
        if (contexts == null || contexts.isEmpty() || rules == null || rules.isEmpty())
        {
            return;
        }
        for (LeadConversionMappingRule rule : rules)
        {
            if (rule == null || !rule.isActive())
            {
                continue;
            }
            for (LeadConversionContext context : contexts)
            {
                if (context == null)
                {
                    continue;
                }
                if (rule.appliesTo(context))
                {
                    applyRule(context, rule);
                }
            }
        }
    }

    private void applyRule(LeadConversionContext context, LeadConversionMappingRule rule)
    {
        Object sourceValue = context.getLeadValue(rule.getSourceFieldApi());
        Object transformedValue = applyTransform(rule.getTransformName(), sourceValue, context, rule);
        if (transformedValue == null || LeadConversionMappingRule.isBlank(transformedValue))
        {
            return;
        }
        switch on rule.getTargetKind()
        {
            when LeadConversionMappingRule.TargetObjectKind.ACCOUNT
            {
                Account accountRecord = context.ensureAccount();
                if (accountRecord == null)
                {
                    return;
                }
                accountRecord.put(rule.getTargetFieldApi(), transformedValue);
                context.markAccountDirty();
            }
            when LeadConversionMappingRule.TargetObjectKind.CONTACT
            {
                Contact contactRecord = context.ensureContact();
                if (contactRecord == null)
                {
                    return;
                }
                contactRecord.put(rule.getTargetFieldApi(), transformedValue);
                context.markContactDirty();
            }
            when LeadConversionMappingRule.TargetObjectKind.OPPORTUNITY
            {
                Opportunity opportunityRecord = context.ensureOpportunity();
                if (opportunityRecord == null)
                {
                    return;
                }
                opportunityRecord.put(rule.getTargetFieldApi(), transformedValue);
                context.markOpportunityDirty();
            }
            when LeadConversionMappingRule.TargetObjectKind.CUSTOM
            {
                Schema.SObjectType customType = rule.getTargetSObjectType();
                if (customType == null)
                {
                    return;
                }
                SObject customRecord = context.getOrCreateCustomRecord(customType);
                customRecord.put(rule.getTargetFieldApi(), transformedValue);
            }
        }
    }

    private Object applyTransform(String transformName, Object value, LeadConversionContext context, LeadConversionMappingRule rule)
    {
        String key = String.isBlank(transformName) ? 'NONE' : transformName.toUpperCase();
        IValueTransformer transformer = transformers.containsKey(key)
            ? transformers.get(key)
            : transformers.get('NONE');
        return transformer == null ? value : transformer.transform(value, context, rule);
    }

    private static Map<String, IValueTransformer> buildDefaultTransformers()
    {
        Map<String, IValueTransformer> defaults = new Map<String, IValueTransformer>();
        defaults.put('NONE', new IValueTransformer()
        {
            public Object transform(Object value, LeadConversionContext context, LeadConversionMappingRule rule)
            {
                return value;
            }
        });
        defaults.put('TRIM', new IValueTransformer()
        {
            public Object transform(Object value, LeadConversionContext context, LeadConversionMappingRule rule)
            {
                return value == null ? null : String.valueOf(value).trim();
            }
        });
        defaults.put('UPPER', new IValueTransformer()
        {
            public Object transform(Object value, LeadConversionContext context, LeadConversionMappingRule rule)
            {
                return value == null ? null : String.valueOf(value).toUpperCase();
            }
        });
        defaults.put('LOWER', new IValueTransformer()
        {
            public Object transform(Object value, LeadConversionContext context, LeadConversionMappingRule rule)
            {
                return value == null ? null : String.valueOf(value).toLowerCase();
            }
        });
        defaults.put('PHONE_NORMALIZE', new IValueTransformer()
        {
            public Object transform(Object value, LeadConversionContext context, LeadConversionMappingRule rule)
            {
                if (value == null)
                {
                    return null;
                }
                String digits = '';
                for (Integer i = 0; i < String.valueOf(value).length(); i++)
                {
                    String c = String.valueOf(value).substring(i, i + 1);
                    if (c >= '0' && c <= '9')
                    {
                        digits += c;
                    }
                }
                return digits;
            }
        });
        defaults.put('FIRST_NAME', new IValueTransformer()
        {
            public Object transform(Object value, LeadConversionContext context, LeadConversionMappingRule rule)
            {
                if (value == null)
                {
                    return null;
                }
                List<String> parts = String.valueOf(value).trim().split('\s+');
                return parts.isEmpty() ? null : parts[0];
            }
        });
        defaults.put('LAST_NAME', new IValueTransformer()
        {
            public Object transform(Object value, LeadConversionContext context, LeadConversionMappingRule rule)
            {
                if (value == null)
                {
                    return null;
                }
                List<String> parts = String.valueOf(value).trim().split('\s+');
                return parts.isEmpty() ? null : parts[parts.size() - 1];
            }
        });
        return defaults;
    }
}
