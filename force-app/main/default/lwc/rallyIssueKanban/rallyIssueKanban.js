import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getActiveProjects from '@salesforce/apex/RallyBoardController.getActiveProjects';
import getIssueStatuses from '@salesforce/apex/RallyBoardController.getIssueStatuses';
import getProjectBoard from '@salesforce/apex/RallyBoardController.getProjectBoard';
import moveIssuesToStatus from '@salesforce/apex/RallyBoardController.moveIssuesToStatus';

export default class RallyIssueKanban extends LightningElement {
    projectOptions = [];
    statuses = [];
    selectedProjectId;
    @track board = {};
    errorMessage;
    boardWireResult;
    showSpinner = false;
    issueStatus = {};

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

    @wire(getIssueStatuses)
    wiredStatuses({ data, error }) {
        if (data) {
            this.statuses = data;
            this.errorMessage = undefined;
        } else if (error) {
            this.errorMessage = this.reduceError(error);
        }
    }

    @wire(getProjectBoard, { projectId: '$selectedProjectId' })
    wiredBoard(value) {
        this.boardWireResult = value;
        if (value.data) {
            this.buildBoard(value.data);
            this.errorMessage = undefined;
        } else if (value.error) {
            this.board = {};
            this.issueStatus = {};
            this.errorMessage = this.reduceError(value.error);
        }
    }

    get columns() {
        return this.statuses.map((status) => {
            const issues = this.board[status] || [];
            return {
                status,
                issues,
                count: issues.length,
                hasIssues: issues.length > 0
            };
        });
    }

    get showBoard() {
        return this.selectedProjectId && this.statuses.length > 0;
    }

    get showSelectionHint() {
        return !this.selectedProjectId;
    }

    get isRefreshDisabled() {
        return !this.selectedProjectId;
    }

    handleProjectChange(event) {
        this.selectedProjectId = event.detail.value;
        this.board = {};
        this.issueStatus = {};
    }

    handleRefresh() {
        if (this.boardWireResult) {
            refreshApex(this.boardWireResult);
        }
    }

    handleDragStart(event) {
        event.dataTransfer.dropEffect = 'move';
        event.dataTransfer.setData('text/plain', event.currentTarget.dataset.issueId);
    }

    handleColumnDragOver(event) {
        event.preventDefault();
        event.dataTransfer.dropEffect = 'move';
    }

    handleDrop(event) {
        event.preventDefault();
        const targetStatus = event.currentTarget.dataset.status;
        const issueId = event.dataTransfer.getData('text/plain');
        if (!issueId || !targetStatus) {
            return;
        }
        if (this.issueStatus[issueId] === targetStatus) {
            return;
        }
        this.showSpinner = true;
        moveIssuesToStatus({ issueIds: [issueId], status: targetStatus })
            .then(() => {
                this.handleRefresh();
            })
            .catch((error) => {
                this.errorMessage = this.reduceError(error);
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }

    buildBoard(issues) {
        const grouped = {};
        const statusMap = {};
        issues.forEach((issue) => {
            const key = issue.Status__c || 'Unassigned';
            if (!grouped[key]) {
                grouped[key] = [];
            }
            grouped[key].push(issue);
            statusMap[issue.Id] = key;
        });
        this.board = grouped;
        this.issueStatus = statusMap;
    }

    reduceError(error) {
        if (Array.isArray(error?.body)) {
            return error.body.map((e) => e.message).join(', ');
        }
        if (typeof error?.body?.message === 'string') {
            return error.body.message;
        }
        return 'Unexpected error while loading data.';
    }
}