trigger LeadTrigger on Lead (before insert, before update, after insert, after update, before delete, after delete, after undelete)
{
    fflib_SObjectDomain.triggerHandler(LeadDomain.class);
}
