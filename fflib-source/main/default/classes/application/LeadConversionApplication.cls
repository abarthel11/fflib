public with sharing class LeadConversionApplication extends fflib_Application
{
    private static fflib_IServiceFactory serviceFactory =
        new fflib_Application.ServiceFactory(new Map<Type, Type>
        {
            LeadConversionService.ILeadConversionService.class => LeadConversionService.class
        });

    public static LeadConversionService.ILeadConversionService leadConversionService()
    {
        return (LeadConversionService.ILeadConversionService) serviceFactory.newInstance(LeadConversionService.ILeadConversionService.class);
    }

    @TestVisible
    static void setServiceFactory(fflib_IServiceFactory factory)
    {
        serviceFactory = factory;
    }
}
