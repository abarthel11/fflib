public with sharing class RallyIssueService {
    private final fflib_ISObjectUnitOfWork unitOfWork;
    private final RallyIssueSelector issueSelector;
    private final RallyProjectSelector projectSelector;
    private final RallySprintSelector sprintSelector;

    public RallyIssueService() {
        this(
            new fflib_SObjectUnitOfWork(
                new List<Schema.SObjectType>{
                    RallyProject__c.SObjectType,
                    RallySprint__c.SObjectType,
                    RallyIssue__c.SObjectType
                }
            ),
            RallyIssueSelector.newInstance(),
            RallyProjectSelector.newInstance(),
            RallySprintSelector.newInstance()
        );
    }

    @TestVisible
    RallyIssueService(
        fflib_ISObjectUnitOfWork unitOfWork,
        RallyIssueSelector issueSelector,
        RallyProjectSelector projectSelector,
        RallySprintSelector sprintSelector
    ) {
        this.unitOfWork = unitOfWork;
        this.issueSelector = issueSelector;
        this.projectSelector = projectSelector;
        this.sprintSelector = sprintSelector;
    }

    public List<RallyIssue__c> createIssues(List<IssueInput> issueInputs) {
        List<RallyIssue__c> issuesToInsert = new List<RallyIssue__c>();
        if (issueInputs == null || issueInputs.isEmpty()) {
            return issuesToInsert;
        }

        Map<Id, RallyProject__c> projectById = new Map<Id, RallyProject__c>();
        Map<Id, RallySprint__c> sprintById = new Map<Id, RallySprint__c>();
        Set<Id> projectIds = new Set<Id>();
        Set<Id> sprintIds = new Set<Id>();
        for (IssueInput inputRecord : issueInputs) {
            inputRecord.validate();
            projectIds.add(inputRecord.projectId);
            if (inputRecord.sprintId != null) {
                sprintIds.add(inputRecord.sprintId);
            }
        }
        if (!projectIds.isEmpty()) {
            projectById = projectSelector.selectByIdMap(projectIds);
            if (projectById.size() != projectIds.size()) {
                throw new fflib_SObjectDomain.DomainException('One or more projects could not be found.');
            }
        }
        if (!sprintIds.isEmpty()) {
            sprintById = sprintSelector.selectByIdMap(sprintIds);
        }

        for (IssueInput inputRecord : issueInputs) {
            RallyIssue__c issueRecord = new RallyIssue__c();
            issueRecord.Project__c = inputRecord.projectId;
            issueRecord.Sprint__c = inputRecord.sprintId;
            issueRecord.Summary__c = inputRecord.summary;
            issueRecord.Description__c = inputRecord.description;
            issueRecord.Issue_Type__c = inputRecord.issueType;
            issueRecord.Priority__c = inputRecord.priority;
            issueRecord.Story_Points__c = inputRecord.storyPoints;
            issueRecord.Due_Date__c = inputRecord.dueDate;
            issueRecord.Assignee__c = inputRecord.assigneeId;
            issueRecord.Reporter__c = inputRecord.reporterId;
            if (inputRecord.blocked != null) {
                issueRecord.Blocked__c = inputRecord.blocked;
            }
            issueRecord.BlockedReason__c = inputRecord.blockedReason;
            issueRecord.Status__c = inputRecord.status;

            if (!projectById.containsKey(issueRecord.Project__c)) {
                throw new fflib_SObjectDomain.DomainException('Referenced project was not found.');
            }
            if (issueRecord.Sprint__c != null) {
                RallySprint__c sprintRecord = sprintById.get(issueRecord.Sprint__c);
                if (sprintRecord == null || sprintRecord.Project__c != issueRecord.Project__c) {
                    throw new fflib_SObjectDomain.DomainException('Sprint does not belong to the supplied project.');
                }
            }

            issuesToInsert.add(issueRecord);
        }

        unitOfWork.registerNew(issuesToInsert);
        unitOfWork.commitWork();
        return issuesToInsert;
    }

    public List<RallyIssue__c> moveIssuesToStatus(Set<Id> issueIds, String status) {
        if (issueIds == null || issueIds.isEmpty()) {
            return new List<RallyIssue__c>();
        }
        if (String.isBlank(status)) {
            throw new fflib_SObjectDomain.DomainException('Status is required.');
        }
        List<RallyIssue__c> issues = issueSelector.selectByIds(issueIds);
        if (issues.isEmpty()) {
            return issues;
        }

        for (RallyIssue__c issueRecord : issues) {
            issueRecord.Status__c = status;
            unitOfWork.registerDirty(
                issueRecord,
                new List<Schema.SObjectField>{RallyIssue__c.Status__c}
            );
        }
        unitOfWork.commitWork();
        return issues;
    }

    public List<RallyIssue__c> getBacklog(Id projectId) {
        return issueSelector.selectBacklogByProject(projectId);
    }

    public List<RallyIssue__c> getSprintBoard(Id projectId, Id sprintId) {
        return issueSelector.selectSprintBoard(projectId, sprintId);
    }

    public List<RallyIssue__c> getProjectBoard(Id projectId) {
        return issueSelector.selectProjectBoard(projectId);
    }

    public class IssueInput {
        public Id projectId;
        public Id sprintId;
        public String issueType;
        public String summary;
        public String description;
        public String priority;
        public String status;
        public Decimal storyPoints;
        public Date dueDate;
        public Id assigneeId;
        public Id reporterId;
        public Boolean blocked;
        public String blockedReason;

        public IssueInput withProject(Id value) {
            projectId = value;
            return this;
        }

        public IssueInput withSummary(String value) {
            summary = value;
            return this;
        }

        public IssueInput withIssueType(String value) {
            issueType = value;
            return this;
        }

        public IssueInput withSprint(Id value) {
            sprintId = value;
            return this;
        }

        public IssueInput withDescription(String value) {
            description = value;
            return this;
        }

        public IssueInput withPriority(String value) {
            priority = value;
            return this;
        }

        public IssueInput withStatus(String value) {
            status = value;
            return this;
        }

        public IssueInput withStoryPoints(Decimal value) {
            storyPoints = value;
            return this;
        }

        public IssueInput withDueDate(Date value) {
            dueDate = value;
            return this;
        }

        public IssueInput withAssignee(Id value) {
            assigneeId = value;
            return this;
        }

        public IssueInput withReporter(Id value) {
            reporterId = value;
            return this;
        }

        public IssueInput withBlocked(Boolean value) {
            blocked = value;
            return this;
        }

        public IssueInput withBlockedReason(String value) {
            blockedReason = value;
            return this;
        }

        public void validate() {
            if (projectId == null) {
                throw new fflib_SObjectDomain.DomainException('Project is required.');
            }
            if (String.isBlank(summary)) {
                throw new fflib_SObjectDomain.DomainException('Summary is required.');
            }
            if (String.isBlank(issueType)) {
                throw new fflib_SObjectDomain.DomainException('Issue Type is required.');
            }
            if (blocked == true && String.isBlank(blockedReason)) {
                throw new fflib_SObjectDomain.DomainException('Blocked issues require a reason.');
            }
        }
    }
}
