import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getActiveProjects from '@salesforce/apex/RallyBoardController.getActiveProjects';
import getActiveSprints from '@salesforce/apex/RallyBoardController.getActiveSprints';
import getIssueStatuses from '@salesforce/apex/RallyBoardController.getIssueStatuses';
import getSprintBoard from '@salesforce/apex/RallyBoardController.getSprintBoard';
import moveIssuesToStatus from '@salesforce/apex/RallyBoardController.moveIssuesToStatus';

export default class RallySprintBoard extends LightningElement {
    projectOptions = [];
    sprintOptions = [];
    statuses = [];
    selectedProjectId;
    selectedSprintId;
    boardWireResult;
    sprintWireResult;
    @track board = {};
    sprintById = {};
    issueStatus = {};
    errorMessage;
    showSpinner = false;

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

    @wire(getActiveSprints, { projectId: '$selectedProjectId' })
    wiredSprints(value) {
        this.sprintWireResult = value;
        if (value.data) {
            this.sprintOptions = value.data.map((sprint) => ({
                label: `${sprint.Name} (${sprint.State__c})`,
                value: sprint.Id
            }));
            this.sprintById = value.data.reduce((acc, sprint) => {
                acc[sprint.Id] = sprint;
                return acc;
            }, {});
            if (!value.data.find((s) => s.Id === this.selectedSprintId)) {
                this.selectedSprintId = undefined;
            }
            this.errorMessage = undefined;
        } else if (value.error) {
            this.sprintOptions = [];
            this.selectedSprintId = undefined;
            this.errorMessage = this.reduceError(value.error);
        } else {
            this.sprintOptions = [];
            this.sprintById = {};
        }
    }

    @wire(getSprintBoard, { projectId: '$selectedProjectId', sprintId: '$selectedSprintId' })
    wiredBoard(value) {
        this.boardWireResult = value;
        if (value.data) {
            this.buildBoard(value.data);
            this.errorMessage = undefined;
        } else if (value.error) {
            this.board = {};
            this.issueStatus = {};
            this.errorMessage = this.reduceError(value.error);
        } else {
            this.board = {};
            this.issueStatus = {};
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

    get currentSprint() {
        return this.sprintById?.[this.selectedSprintId];
    }

    get currentSprintLabel() {
        return this.currentSprint ? this.currentSprint.Name : '';
    }

    get showBoard() {
        return this.selectedProjectId && this.selectedSprintId && this.statuses.length > 0;
    }

    get showSelectionHint() {
        return !(this.selectedProjectId && this.selectedSprintId);
    }

    get disableSprintPicklist() {
        return !this.selectedProjectId || this.sprintOptions.length === 0;
    }

    get isRefreshDisabled() {
        return !this.selectedProjectId || !this.selectedSprintId;
    }

    get showSprintDetails() {
        return !!this.currentSprint;
    }

    handleProjectChange(event) {
        this.selectedProjectId = event.detail.value;
        this.selectedSprintId = undefined;
        this.board = {};
        this.issueStatus = {};
    }

    handleSprintChange(event) {
        this.selectedSprintId = event.detail.value;
        this.issueStatus = {};
    }

    handleRefresh() {
        if (this.boardWireResult) {
            refreshApex(this.boardWireResult);
        }
        if (this.sprintWireResult) {
            refreshApex(this.sprintWireResult);
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
        const status = event.currentTarget.dataset.status;
        const issueId = event.dataTransfer.getData('text/plain');
        if (!status || !issueId) {
            return;
        }
        if (this.issueStatus[issueId] === status) {
            return;
        }
        this.showSpinner = true;
        moveIssuesToStatus({ issueIds: [issueId], status })
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
        return 'Unexpected error while loading sprint data.';
    }
}