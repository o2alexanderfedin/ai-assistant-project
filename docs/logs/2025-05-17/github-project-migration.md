# GitHub Project Migration

Date: 2025-05-17

## 📋 Overview

This document provides a guide for migrating all epics and user stories to GitHub Projects for improved tracking and management.

## 🎯 Goals

- Create a structured GitHub Project for AI Assistant development
- Configure custom fields for tracking type, priority, story points, and components
- Establish relationships between epics and user stories
- Set up views for better visibility and management
- Implement automated workflows where possible

## 🤖 Automated Migration Scripts

The following scripts were created to automate the GitHub Project migration process:

### 1. Project Creation

```bash
# scripts/create-github-project.sh
# Creates a new GitHub Project
gh projects create --user '@me' --title "AI Assistant Development" --format json
```

### 2. Issue Migration

```bash
# scripts/migrate-issues.sh
# Add all epics and user stories to the project
for ISSUE_URL in $(gh issue list --json url --jq '.[] | .url'); do
  gh projects item-add $PROJECT_NUM --user '@me' --url "$ISSUE_URL"
done
```

### 3. Custom Field Creation

```bash
# scripts/update-project-fields.sh
# Create and set Type, Priority, and Story Points fields
gh projects field-create $PROJECT_NUM --user '@me' --name "Type" --data-type "SINGLE_SELECT" --single-select-options "Epic,User Story,Task"
gh projects field-create $PROJECT_NUM --user '@me' --name "Priority" --data-type "SINGLE_SELECT" --single-select-options "High,Medium,Low"
gh projects field-create $PROJECT_NUM --user '@me' --name "Story Points" --data-type "NUMBER"
```

### 4. Epic Field Creation

```bash
# scripts/create-epic-field.sh
# Create Epic field with all epic titles as options for user stories
gh projects field-create $PROJECT_NUM --user '@me' --name "Epic" --data-type "SINGLE_SELECT" --single-select-options "$EPIC_TITLES"
```

### 5. Component Field

```bash
# scripts/create-component-field.sh
# Create Component field with component categories
gh projects field-create $PROJECT_NUM --user '@me' --name "Component" --data-type "SINGLE_SELECT" --single-select-options "Core Agents,MCP,Workflow,Shared Components,External Integration,Testing"
```

### 6. Parent Issue Relationships

```bash
# scripts/set-parent-issue.sh
# Attempts to set parent-child relationships programmatically
# Falls back to generating a guide for manual entry if API approach fails
# Usage: ./set-parent-issue.sh <child_issue_number> <parent_issue_number>
```

### 7. Comment Migration

```bash
# scripts/migrate-all-comments.sh
# Extract comments from all issues with proper formatting
# Creates Markdown files for each issue's comments for manual addition to item notes
```

## 🛠️ Manual Migration Steps

Due to API limitations, some steps of the migration need to be done manually:

### Step 1: Create a new GitHub Project

1. Go to [https://github.com/users/o2alexanderfedin?tab=projects](https://github.com/users/o2alexanderfedin?tab=projects)
2. Click "New project"
3. Select "Team planning" as the template
4. Name it "AI Assistant Development"
5. Add description: "Project board for AI Assistant architecture and implementation"
6. Click "Create"

### Step 2: Set up custom fields

1. Click "+" icon next to the default fields to add new fields
2. Add the following custom fields:
   - **Type**: Single select field with options: Epic, User Story, Task
   - **Priority**: Single select field with options: High, Medium, Low
   - **Story Points**: Number field
   - **Component**: Single select field with options: Core Agents, MCP, Workflow, Shared Components, External Integration, Testing
   - **Epic Link**: Single select field (initially empty, we'll populate options later)

### Step 3: Add epics to the project

1. Click "+ Add item" at the bottom of the project board
2. Select "Add item from repository" 
3. For each epic (issues #1-7):
   - Add to the project board
   - Set the Type field to "Epic"
   - Set Priority based on labels (priority:high → High, etc.)
   - Set Component based on labels (see mapping below)
   - Add the epic title to the Epic Link field options

### Step 4: Add user stories to the project

1. Click "+ Add item" again
2. For each user story (issues with user-story label):
   - Add to the project board
   - Set the Type field to "User Story"
   - Set the Epic Link field to the parent epic (check the "Epic: #X" reference in the user story description)
   - Set Story Points field based on points:X label
   - Set Priority based on labels
   - Set Component based on labels

### Step 5: Set Parent issue field values

Due to API limitations, Parent issue field values must be set manually:

1. Run the `set-parent-manual.sh` script to generate a list of parent-child relationships
2. Go to the GitHub Project in the web UI
3. For each user story:
   - Click on the issue to open its side panel
   - Find the "Parent issue" field
   - Type "#" and select the appropriate parent epic from the dropdown
   - Save the change and proceed to the next issue

See the [Parent Issue Guide](/docs/logs/2025-05-17/parent-issue-guide.md) for detailed instructions and the technical challenges encountered.

### Step 6: Create useful views

1. Create an "Epics Overview" view
   - Add filter: Type = Epic
   - Group by: Component
   - Show fields: Title, Priority, Story Points

2. Create a "User Stories by Epic" view
   - Add filter: Type = User Story
   - Group by: Epic Link
   - Show fields: Title, Priority, Story Points, Component

3. Create a "Stories by Component" view
   - Add filter: Type = User Story
   - Group by: Component
   - Show fields: Title, Priority, Story Points, Epic Link

## 🔁 Component Mapping

The following categories are used to classify issues by component:

- **Core Agents**: Issues related to agent types (developer, implementer, reviewer, tester, documentation, devops)
- **MCP**: Issues about communication protocols, MCP implementation
- **Workflow**: Issues related to orchestration, task workflows, task lifecycle
- **External Integration**: GitHub, CI/CD, development environment, external systems
- **Shared Components**: Registry, state store, task queue, knowledge base, metrics
- **Testing**: Test-related issues, TDD workflows, testing frameworks

## 🔄 Parent-Child Field Issues

The GitHub Project has two different ways to track parent-child relationships:

### 1. Custom Epic Field

- Single-select field with epic titles as options
- Used for logical grouping of user stories under epics
- Displayed in views for filtering and grouping

### 2. Built-in Parent Issue Field

- Native GitHub Projects field
- Links issues directly in the GitHub UI
- Shows parent-child relationships in the issue view
- **Must be set manually in the GitHub UI**
- API limitations prevent programmatic setting

Our investigation revealed that:

1. The GitHub GraphQL API does not support setting the built-in Parent issue field
   - Error: "InputObject 'ProjectV2FieldValue' doesn't accept argument 'projectV2Item'"
2. Setting parent issue fields must be done manually through the GitHub UI
3. This limitation affects all script-based automation approaches

## 📊 Migration Data

Here's a summary of the data being migrated:

### Epics

| # | Title | Story Points | Priority | Component |
|---|-------|--------------|----------|-----------|
| 1 | Core Agent System Implementation | 60 | High | Core Agents |
| 2 | Model Context Protocol (MCP) Implementation | 43 | High | MCP |
| 3 | Specialized Agent Implementation | 42 | Medium | Core Agents |
| 4 | Agent Task Workflow Implementation | 39 | Medium | Workflow |
| 5 | Shared Component Implementation | 57 | Medium | Shared Components |
| 6 | External Integration Implementation | 49 | Medium | External Integration |
| 7 | System Testing and Quality Assurance | 36 | Low | Testing |

### User Stories

The project contains approximately 50 user stories spread across these epics, each with assigned story points, priorities, and components.

### Parent-Child Relationships

Here's a sample of the parent-child relationships identified from issue bodies:

```
• Issue #66: 'Secure Agent Creation' → Epic #1: '🔄 Core Agent System Implementation'
• Issue #65: 'Agent Template Management' → Epic #1: '🔄 Core Agent System Implementation'
• Issue #64: 'Agent Instance Creation' → Epic #1: '🔄 Core Agent System Implementation'
• Issue #58: 'Implement DevOps Agent' → Epic #3: '🧠 Specialized Agent Implementation'
• Issue #57: 'Implement Documentation Agent' → Epic #3: '🧠 Specialized Agent Implementation'
• Issue #53: 'Implement Shared Component Unit Tests' → Epic #7: '🔍 System Testing and Quality Assurance'
• Issue #52: 'Develop Core Agent Unit Tests' → Epic #7: '🔍 System Testing and Quality Assurance'
```

## 🧰 Token Requirements

Ensure your GitHub token has the right scopes:

```bash
# Refresh token with project scope
gh auth refresh -h github.com -s project

# Verify token has project scope
gh auth status
```

## 🔗 Related Documents

- [GitHub Project Setup Guide](/docs/logs/2025-05-17/github-project-setup-guide.md) - Detailed setup instructions
- [Parent Issue Guide](/docs/logs/2025-05-17/parent-issue-guide.md) - How to manually set parent relationships
- [System Architecture: Component Responsibilities](/docs/architecture/component-responsibilities.md) - Source for component categorization

## ⚠️ Limitations and Challenges

- GitHub API requires special token scope for Projects API access
- Token must be refreshed with: `gh auth refresh -h github.com -s project`
- Project ID and item IDs are non-deterministic, requiring dynamic handling
- Comment migration requires manual steps due to GraphQL API limitations
- **Parent issue field cannot be set through the GitHub GraphQL API** - manual setting is required

## ✅ Migration Status

- [x] Create GitHub Project
- [x] Add all issues to project
- [x] Create custom fields (Type, Priority, Story Points, Epic, Component)
- [x] Set Type field values for all items
- [x] Set Priority field values for all items
- [x] Set Story Points values for all items
- [x] Create Epic field and link user stories to parent epics
- [x] Create Component field and set values for all items
- [x] Generate guide for manually setting Parent issue field values
- [x] Extract issue comments for manual addition
- [x] Set up project views for better visibility
- [x] Investigate parent issue setting limitations and document findings
- [ ] Implement automation rules

## 🚀 Next Steps

1. Manually set Parent issue field values in the GitHub UI (following our Parent Issue Guide)
2. Add extracted comments to item notes through GitHub web interface
3. Investigate alternative API approaches for future automation
4. Consider implementing GitHub Actions for automated status updates
5. Evaluate options for lightweight automation without setting parent fields

---

🧭 **Navigation**: [Home](/README.md) | [Up](../README.md) | [Parent Issue Guide](/docs/logs/2025-05-17/parent-issue-guide.md)