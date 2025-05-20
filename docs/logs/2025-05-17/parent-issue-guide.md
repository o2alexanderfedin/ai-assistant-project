# Parent Issue Field Configuration Guide

Date: 2025-05-17

## 📋 Overview

This guide provides instructions for setting the Parent issue field values in GitHub Projects, which must be done manually due to GitHub API limitations.

## 🔄 Parent-Child Relationships

The following parent-child relationships have been identified based on "Epic: #X" references in issue descriptions:

### Core Agent System (Epic #1)

| Issue # | Title |
|---------|-------|
| #66 | Secure Agent Creation |
| #65 | Agent Template Management |
| #64 | Agent Instance Creation |
| #63 | Task Classification and Prioritization |
| #62 | Task Analysis and Agent Matching |
| #61 | Orchestrator MCP Communication |
| #60 | Agent Lifecycle Management |
| #59 | GitHub Task Monitoring |

### Specialized Agent Implementation (Epic #3)

| Issue # | Title |
|---------|-------|
| #58 | Implement DevOps Agent |
| #57 | Implement Documentation Agent |
| #56 | Implement Tester Agent |
| #55 | Implement Reviewer Agent |
| #54 | Implement Developer Agent |

### System Testing and Quality Assurance (Epic #7)

| Issue # | Title |
|---------|-------|
| #53 | Implement Shared Component Unit Tests |
| #52 | Develop Core Agent Unit Tests |
| #51 | Implement Test Coverage Tracking and Reporting |
| #50 | Set Up GitHub Actions Testing Pipeline |
| #49 | Create MCP Protocol Test Suite |
| #48 | Implement BATS Testing Framework |

## 🛠️ Manual Configuration Process

Due to limitations in the GitHub Projects GraphQL API, the Parent issue field cannot be set programmatically. Follow these steps to manually configure parent-child relationships:

1. Go to the [AI Assistant Development](https://github.com/users/o2alexanderfedin/projects/2) project in GitHub
2. For each user story, set its Parent issue field to the corresponding epic:
   1. Click on the issue in the project board to open its details panel
   2. Find the "Parent issue" field in the side panel
   3. Type "#" and select the appropriate parent epic from the dropdown
   4. Save the change and proceed to the next issue

## ⚙️ Technical Notes

- The GitHub script `scripts/set-parent-issue.sh` was used to:
  - Attempt to set the relationships programmatically through multiple approaches
  - Generate this manual guide when API approaches failed
- The GitHub GraphQL API does not support setting the built-in Parent issue field
  - Error: "InputObject 'ProjectV2FieldValue' doesn't accept argument 'projectV2Item'"
- Although the GitHub UI clearly shows Parent issue as a field, the GraphQL API doesn't expose this functionality correctly
- All parent-child relationships need to be set manually

## 📜 API Approaches Attempted

We attempted several approaches to set parent issues programmatically:

1. Using the GitHub GraphQL API for project fields:
   ```graphql
   mutation {
     updateProjectV2ItemFieldValue(
       input: {
         projectId: "PROJECT_ID"
         itemId: "ITEM_ID"
         fieldId: "PARENT_FIELD_ID"
         value: {
           projectV2Item: "PARENT_ITEM_ID"
         }
       }
     ) {
       projectV2Item {
         id
       }
     }
   }
   ```
   Error: "InputObject 'ProjectV2FieldValue' doesn't accept argument 'projectV2Item'"
   
2. Examining the ProjectV2FieldValue structure:
   ```json
   {
     "text": "String",
     "number": "Float",
     "date": "Date",
     "singleSelectOptionId": "String",
     "iterationId": "String"
   }
   ```
   The structure reveals no way to set parent-child relationships.
   
3. Using the REST API for sub-issues:
   ```bash
   curl -L -X POST \
     -H "Accept: application/vnd.github+json" \
     -H "Authorization: Bearer $TOKEN" \
     -H "X-GitHub-Api-Version: 2022-11-28" \
     https://api.github.com/repos/OWNER/REPO/issues/ISSUE_NUMBER/sub_issues \
     -d '{"sub_issue_id": SUB_ISSUE_ID}'
   ```
   Error: "The provided sub-issue does not exist" (404)
   
4. Trying the GraphQL API for issue relationships:
   ```graphql
   mutation($parent: ID!, $child: ID!) {
     addIssueRelation(input: {
       sourceId: $parent,
       targetId: $child,
       relationshipType: TRACKS
     }) {
       clientMutationId
     }
   }
   ```
   Error: "Field 'addIssueRelation' doesn't exist on type 'Mutation'"

All approaches resulted in API errors, indicating that programmatically setting parent-child relationships is not currently supported by GitHub's API.

## 🔄 Related Documents

- [GitHub Project Migration](/docs/logs/2025-05-17/github-project-migration.md)
- [Architecture Component Responsibilities](/docs/architecture/component-responsibilities.md)

---

🧭 **Navigation**: [Home](/README.md) | [Up](../README.md) | [GitHub Migration](/docs/logs/2025-05-17/github-project-migration.md)