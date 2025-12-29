public with sharing class Application {
    public Application() {

    }
}

You are a senior Salesforce/Apex architect. Generate production-grade Apex code using fflib-apex-common best practices (Enterprise Patterns). The goal: provide a robust, testable framework to map data during Lead conversion from Lead -> Account/Contact/Opportunity (and custom objects) using a configurable mapping approach.

REQUIREMENTS
1) Use fflib patterns:
   - thin triggers (if any), domain/selector/service layers, and an Application class to wire dependencies
   - avoid static state where possible; enable dependency injection for tests
   - one trigger per object max; all logic outside the trigger
2) Implement a Lead Conversion mapping system that supports:
   - mapping Lead standard fields to Account/Contact/Opportunity standard fields
   - mapping Lead custom fields to standard fields and custom fields on Account/Contact/Opportunity
   - mapping Lead fields to custom objects created at conversion time (e.g., Lead_Conversion_Audit__c or related setup objects)
   - conditional mapping rules (e.g., only map when Lead.RecordType.DeveloperName = 'SDK', or only if field is not blank)
   - transformation hooks (e.g., normalize phone, split full name, derive industry, etc.)
3) The solution must work with BOTH:
   - standard Lead conversion UI flow (user converts lead)
   - programmatic conversion using Database.convertLead()
4) Implementation must be bulk-safe, platform-limit aware, and have strong unit tests.
5) Include clear extension points for future mappings (new objects, new rules).
6) Include a test data factory and meaningful assertions (not just "Assert.isTrue(true)").

ARCHITECTURE
- Provide these classes (or a clearly justified variant):
  A) LeadTrigger (or no trigger if you use a platform event / invocable pattern, but explain)
  B) LeadConversionService (orchestrates conversion handling)
  C) LeadConversionMapper (applies mapping rules to target sObjects)
  D) Mapping rule model (e.g., Apex config class OR Custom Metadata Types)
  E) LeadConversionContext (holds Lead + converted Account/Contact/Opp + flags)
  F) Selectors for Lead/Account/Contact/Opp if you query anything
  G) Application class (fflib_Application) wiring for service/selector/domain

CONFIGURATION
- Prefer Custom Metadata Types for mapping configuration.
- Define a CMDT model like:
  Lead_Field_Mapping__mdt with fields:
    - Source_Field_API__c (Lead field API)
    - Target_Object__c (Account|Contact|Opportunity|Custom:<APIName>)
    - Target_Field_API__c
    - Condition_Expression__c (simple supported DSL you define, e.g., "LeadSource=Partner;NotBlank=Source_Field")
    - Transform__c (enum string like NONE, TRIM, UPPER, PHONE_NORMALIZE, etc.)
    - Active__c (checkbox)
- If CMDT is too heavy, implement an Apex in-memory registry but still make it easy to replace with CMDT.

EVENT TIMING / DATA AVAILABILITY
- Lead conversion happens with special behavior. Ensure the solution correctly handles:
  - when Lead is converted (IsConverted = true)
  - access to ConvertedAccountId / ConvertedContactId / ConvertedOpportunityId
  - recursion control and idempotency (conversion updates the Lead more than once)
- Ensure code never attempts to update read-only conversion fields incorrectly.

DELIVERABLES
1) Full Apex code files with names and contents, organized in folders:
   - classes/application
   - classes/services
   - classes/mappers
   - classes/selectors
   - classes/domain
   - triggers
2) A complete test suite:
   - at least 3 test methods covering:
     i) standard mapping to Account & Contact
     ii) conditional mapping + transformation
     iii) mapping to a custom object created on conversion
   - use @testSetup, test factory methods, and fflib_ApexMocks if appropriate
3) Explain how to deploy and how to add a new mapping rule.
4) Include notes about any Salesforce caveats for Lead conversion triggers and the order of execution.

OUTPUT FORMAT
- Use markdown headings.
- For each file: show "File: path/Name.cls" and then the full code in a code block.
- Do not omit code. Provide compilable Apex.
