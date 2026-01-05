public with sharing class RallyIssueDomain extends fflib_SObjectDomain {
    private static final Map<String, Set<String>> STATUS_TRANSITIONS = buildStatusTransitions();

    public RallyIssueDomain(List<RallyIssue__c> records) {
        super(records);
    }

    public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> sObjectList) {
            return new RallyIssueDomain((List<RallyIssue__c>) sObjectList);
        }
    }

    public override void onApplyDefaults() {
        for (RallyIssue__c issueRecord : issueRecords()) {
            if (String.isBlank(issueRecord.Status__c)) {
                issueRecord.Status__c = 'Backlog';
            }
            if (String.isBlank(issueRecord.Priority__c)) {
                issueRecord.Priority__c = 'High';
            }
            if (issueRecord.Blocked__c == null) {
                issueRecord.Blocked__c = false;
            }
            if (issueRecord.Reporter__c == null) {
                issueRecord.Reporter__c = UserInfo.getUserId();
            }
        }
    }

    public override void onBeforeInsert() {
        validateIssues();
        assignSequenceValues();
    }

    public override void onBeforeUpdate(Map<Id, SObject> existingRecords) {
        validateIssues();
        for (RallyIssue__c issueRecord : issueRecords()) {
            RallyIssue__c prior = (RallyIssue__c) existingRecords.get(issueRecord.Id);
            if (prior == null) {
                continue;
            }
            if (String.isBlank(issueRecord.Status__c)) {
                issueRecord.Status__c = prior.Status__c;
            }
            if (issueRecord.Status__c != prior.Status__c
                && !isValidTransition(prior.Status__c, issueRecord.Status__c)) {
                issueRecord.Status__c.addError(
                    'Transition from ' + prior.Status__c + ' to ' + issueRecord.Status__c + ' is not allowed.'
                );
            }
        }

        assignSequenceValues();
    }

    private List<RallyIssue__c> issueRecords() {
        return (List<RallyIssue__c>) Records;
    }

    private void assignSequenceValues() {
        Map<Id, List<RallyIssue__c>> issuesByProject = new Map<Id, List<RallyIssue__c>>();
        for (RallyIssue__c issueRecord : issueRecords()) {
            if (issueRecord.Project__c == null) {
                continue;
            }
            if (issueRecord.Sequence__c != null) {
                continue;
            }
            if (!issuesByProject.containsKey(issueRecord.Project__c)) {
                issuesByProject.put(issueRecord.Project__c, new List<RallyIssue__c>());
            }
            issuesByProject.get(issueRecord.Project__c).add(issueRecord);
        }
        if (issuesByProject.isEmpty()) {
            return;
        }

        Map<Id, Integer> maxSequenceByProject = RallyIssueSelector.newInstance()
            .selectMaxSequenceByProject(issuesByProject.keySet());
        Map<Id, RallyProject__c> projectsById = RallyProjectSelector.newInstance().selectByIdMap(issuesByProject.keySet());

        for (Id projectId : issuesByProject.keySet()) {
            Integer nextSequence = maxSequenceByProject.containsKey(projectId)
                ? maxSequenceByProject.get(projectId)
                : 0;
            for (RallyIssue__c issueRecord : issuesByProject.get(projectId)) {
                nextSequence++;
                issueRecord.Sequence__c = nextSequence;
                issueRecord.Issue_Key__c = buildIssueKey(projectsById.get(projectId), nextSequence);
            }
        }
    }

    private static Boolean isValidTransition(String currentStatus, String targetStatus) {
        if (String.isBlank(currentStatus) || String.isBlank(targetStatus) || currentStatus == targetStatus) {
            return true;
        }
        if (!STATUS_TRANSITIONS.containsKey(currentStatus)) {
            return false;
        }
        return STATUS_TRANSITIONS.get(currentStatus).contains(targetStatus);
    }

    private static String buildIssueKey(RallyProject__c projectRecord, Integer sequence) {
        String keyPrefix = (projectRecord != null && !String.isBlank(projectRecord.Key__c))
            ? projectRecord.Key__c
            : 'RALLY';
        String sequenceString = String.valueOf(sequence);
        if (sequenceString.length() < 4) {
            sequenceString = sequenceString.leftPad(4, '0');
        }
        return keyPrefix + '-' + sequenceString;
    }

    private static Map<String, Set<String>> buildStatusTransitions() {
        Map<String, Set<String>> transitions = new Map<String, Set<String>>();
        transitions.put('Backlog', new Set<String>{'In Progress', 'Done'});
        transitions.put('In Progress', new Set<String>{'In Review', 'Done', 'Backlog'});
        transitions.put('In Review', new Set<String>{'In Progress', 'Done'});
        transitions.put('Done', new Set<String>{'In Progress'});
        return transitions;
    }

    private void validateIssues() {
        for (RallyIssue__c issueRecord : issueRecords()) {
            if (issueRecord.Project__c == null) {
                issueRecord.Project__c.addError('A project is required.');
            }
            if (String.isBlank(issueRecord.Summary__c)) {
                issueRecord.Summary__c.addError('Summary is required.');
            }
            if (String.isBlank(issueRecord.Issue_Type__c)) {
                issueRecord.Issue_Type__c.addError('Issue Type is required.');
            }
            if (issueRecord.Blocked__c == true && String.isBlank(issueRecord.BlockedReason__c)) {
                issueRecord.BlockedReason__c.addError('Blocked issues require a reason.');
            }
        }
    }
}
