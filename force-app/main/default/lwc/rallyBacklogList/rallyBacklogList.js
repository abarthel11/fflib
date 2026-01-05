import { LightningElement, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getActiveProjects from '@salesforce/apex/RallyBoardController.getActiveProjects';
import getBacklog from '@salesforce/apex/RallyBoardController.getBacklog';

const COLUMNS = [
    { label: 'Issue Key', fieldName: 'Issue_Key__c', type: 'text' },
    { label: 'Summary', fieldName: 'Summary__c', type: 'text', wrapText: true },
    { label: 'Type', fieldName: 'Issue_Type__c', type: 'text' },
    { label: 'Priority', fieldName: 'Priority__c', type: 'text' },
    { label: 'Status', fieldName: 'Status__c', type: 'text' },
    { label: 'Story Points', fieldName: 'Story_Points__c', type: 'number' },
    { label: 'Due Date', fieldName: 'Due_Date__c', type: 'date' },
    { label: 'Sprint', fieldName: 'sprintName', type: 'text' },
    { label: 'Assignee', fieldName: 'assigneeName', type: 'text' }
];

export default class RallyBacklogList extends LightningElement {
    columns = COLUMNS;
    projectOptions = [];
    selectedProjectId;
    backlog = [];
    errorMessage;
    backlogWireResult;

    @wire(getActiveProjects)
    wiredProjects({ data, error }) {
        if (data) {
            this.projectOptions = data.map((project) => ({
                label: `${project.Name} (${project.Key__c})`,
                value: project.Id
            }));
            this.errorMessage = undefined;
        } else if (error) {
            this.errorMessage = this.reduceError(error);
        }
    }

    @wire(getBacklog, { projectId: '$selectedProjectId' })
    wiredBacklog(value) {
        this.backlogWireResult = value;
        if (value.data) {
            this.backlog = value.data.map((issue) => ({
                ...issue,
                sprintName: issue?.Sprint__r?.Name,
                assigneeName: issue?.Assignee__r?.Name
            }));
            this.errorMessage = undefined;
        } else if (value.error) {
            this.backlog = [];
            this.errorMessage = this.reduceError(value.error);
        }
    }

    get showSelectionHint() {
        return !this.selectedProjectId;
    }

    get showTable() {
        return this.selectedProjectId && this.backlog && this.backlog.length > 0;
    }

    get showEmptyState() {
        return this.selectedProjectId && (!this.backlog || this.backlog.length === 0) && !this.errorMessage;
    }

    get isRefreshDisabled() {
        return !this.selectedProjectId;
    }

    handleProjectChange(event) {
        this.selectedProjectId = event.detail.value;
    }

    handleRefresh() {
        if (this.backlogWireResult) {
            refreshApex(this.backlogWireResult);
        }
    }

    reduceError(error) {
        if (Array.isArray(error?.body)) {
            return error.body.map((e) => e.message).join(', ');
        }
        if (typeof error?.body?.message === 'string') {
            return error.body.message;
        }
        return 'Unexpected error loading backlog data.';
    }
}