# Parent Issue Configuration Guide

## 📋 Overview

This guide outlines the process for creating and managing parent-child relationships between issues in the AI Assistant project using GitHub Projects.

## 🚫 API Limitations

Due to limitations in the GitHub Projects GraphQL API, the Parent issue field cannot be set programmatically. All parent-child relationships need to be set manually through the GitHub UI.

## 🛠️ Provided Scripts

We've created two scripts to assist with managing parent-child relationships:

1. **add-sub-issue.sh** - Creates a child issue linked to a parent
   ```bash
   ./scripts/add-sub-issue.sh <parent_issue_number> "Child Title" "Description" "label1,label2"
   # Example:
   ./scripts/add-sub-issue.sh 1 "Implement feature X" "This task implements X" "user-story"
   ```

2. **set-parent-issue.sh** - Attempts to set parent field (falls back to manual instructions)
   ```bash
   ./scripts/set-parent-issue.sh <child_issue_number> <parent_issue_number>
   # Example:
   ./scripts/set-parent-issue.sh 42 1
   ```

Both scripts will add the issues to the project, but due to API limitations, you'll still need to manually set the parent-child relationship in the GitHub UI.

## 🔄 Manual Configuration Instructions

1. Go to: https://github.com/users/o2alexanderfedin/projects/2
2. For each user story, set its Parent issue field to the corresponding epic:

### Core Agent System (Epic #1: '🔄 Core Agent System Implementation')
• Issue #66: 'Secure Agent Creation'
• Issue #65: 'Agent Template Management'
• Issue #64: 'Agent Instance Creation'
• Issue #63: 'Task Classification and Prioritization'
• Issue #62: 'Task Analysis and Agent Matching'
• Issue #61: 'Orchestrator MCP Communication'
• Issue #60: 'Agent Lifecycle Management'
• Issue #59: 'GitHub Task Monitoring'

### Specialized Agent Implementation (Epic #3: '🧠 Specialized Agent Implementation')
• Issue #58: 'Implement DevOps Agent'
• Issue #57: 'Implement Documentation Agent'
• Issue #56: 'Implement Tester Agent'
• Issue #55: 'Implement Reviewer Agent'
• Issue #54: 'Implement Developer Agent'

### System Testing and Quality Assurance (Epic #7: '🔍 System Testing and Quality Assurance')
• Issue #53: 'Implement Shared Component Unit Tests'
• Issue #52: 'Develop Core Agent Unit Tests'
• Issue #51: 'Implement Test Coverage Tracking and Reporting'
• Issue #50: 'Set Up GitHub Actions Testing Pipeline'
• Issue #49: 'Create MCP Protocol Test Suite'
• Issue #48: 'Implement BATS Testing Framework'

## 📋 Steps to Set Parent Issues

1. Click on an issue in the project board
2. In the side panel, find the 'Parent issue' field
3. Type '#' and select the appropriate parent epic from the dropdown
4. Save the change and proceed to the next issue

## 🧪 Technical Investigation Results

Our technical investigation revealed:

1. The GitHub GraphQL API does not support setting the built-in Parent issue field
   - Error: "InputObject 'ProjectV2FieldValue' doesn't accept argument 'projectV2Item'"
2. Although the GitHub UI clearly shows Parent issue as a field, the GraphQL API doesn't expose this functionality correctly
3. We also tried the REST API for sub-issues and the GraphQL issue relationships endpoint, but these don't properly set the Parent field in GitHub Projects
4. The best approach is to use our scripts to create issues and add them to projects, then manually set parent relationships in the UI

See our detailed investigation in [Parent Issue Field Configuration Guide](/docs/logs/2025-05-17/parent-issue-guide.md).

## 📊 Future Improvements

GitHub continues to improve their API. As of our last check:
- The REST API for sub-issues still returns 404 errors when attempted
- The GraphQL mutation to add issue relations is not implemented
- The Projects "Parent issue" field remains only manually configurable

We'll continue to monitor GitHub's API updates and improve our scripts as new capabilities are released.

---

🧭 **Navigation**: [Home](/README.md) | [Architecture Documentation](/docs/architecture/README.md)