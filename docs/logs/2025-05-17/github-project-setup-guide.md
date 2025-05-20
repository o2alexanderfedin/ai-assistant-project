# GitHub Project Setup Guide

Date: 2025-05-17

## 📋 Overview

This document provides a comprehensive guide for setting up the GitHub Project for the AI Assistant Development project.

## 🏗️ Project Creation

1. Create a new GitHub Project:
   - Go to: https://github.com/users/o2alexanderfedin?tab=projects
   - Click "New project"
   - Select "Team planning" as the template
   - Name it "AI Assistant Development"
   - Add description: "Project board for AI Assistant architecture and implementation"

2. Add custom fields:
   - **Type**: Single select field with options: Epic, User Story, Task
   - **Priority**: Single select field with options: High, Medium, Low
   - **Story Points**: Number field
   - **Component**: Single select field with options: Core Agents, MCP, Workflow, Shared Components, External Integration, Testing
   - **Epic**: Single select field with the following options:
     - 🔍 System Testing and Quality Assurance
     - 🔗 External Integration Implementation
     - 🗄️ Shared Component Implementation
     - ⚙️ Agent Task Workflow Implementation
     - 🧠 Specialized Agent Implementation
     - 📡 Model Context Protocol (MCP) Implementation
     - 🔄 Core Agent System Implementation

## 🏷️ Epic Configuration

The following epics should be added to the project and configured with these fields:

| Epic # | Title | Type | Priority | Component |
|--------|-------|------|----------|-----------|
| #7 | 🔍 System Testing and Quality Assurance | Epic | Low | Testing |
| #6 | 🔗 External Integration Implementation | Epic | Medium | External Integration |
| #5 | 🗄️ Shared Component Implementation | Epic | Medium | Shared Components |
| #4 | ⚙️ Agent Task Workflow Implementation | Epic | High | Workflow |
| #3 | 🧠 Specialized Agent Implementation | Epic | High | Core Agents |
| #2 | 📡 Model Context Protocol (MCP) Implementation | Epic | High | MCP |
| #1 | 🔄 Core Agent System Implementation | Epic | High | Core Agents |

## 📝 User Story Configuration

The following user stories should be added to the project and configured with these fields:

| User Story # | Title | Type | Priority | Story Points | Epic | Component |
|--------------|-------|------|----------|--------------|------|-----------|
| #66 | Secure Agent Creation | User Story | High | 5 | 🔄 Core Agent System Implementation | Core Agents |
| #65 | Agent Template Management | User Story | High | 5 | 🔄 Core Agent System Implementation | Core Agents |
| #64 | Agent Instance Creation | User Story | High | 8 | 🔄 Core Agent System Implementation | Core Agents |
| #63 | Task Classification and Prioritization | User Story | High | 8 | 🔄 Core Agent System Implementation | Core Agents |
| #62 | Task Analysis and Agent Matching | User Story | High | 13 | 🔄 Core Agent System Implementation | Core Agents |
| #61 | Orchestrator MCP Communication | User Story | High | 8 | 🔄 Core Agent System Implementation | Core Agents |
| #60 | Agent Lifecycle Management | User Story | High | 8 | 🔄 Core Agent System Implementation | Core Agents |
| #59 | GitHub Task Monitoring | User Story | High | 5 | 🔄 Core Agent System Implementation | Core Agents |
| #58 | Implement DevOps Agent | User Story | Medium | 8 | 🧠 Specialized Agent Implementation | Core Agents |
| #57 | Implement Documentation Agent | User Story | Medium | 5 | 🧠 Specialized Agent Implementation | Shared Components |
| #56 | Implement Tester Agent | User Story | Medium | 8 | 🧠 Specialized Agent Implementation | Core Agents |
| #55 | Implement Reviewer Agent | User Story | High | 8 | 🧠 Specialized Agent Implementation | Core Agents |
| #54 | Implement Developer Agent | User Story | High | 13 | 🧠 Specialized Agent Implementation | Core Agents |
| #53 | Implement Shared Component Unit Tests | User Story | Medium | 5 | 🔍 System Testing and Quality Assurance | Testing |
| #52 | Develop Core Agent Unit Tests | User Story | High | 8 | 🔍 System Testing and Quality Assurance | Core Agents |
| #51 | Implement Test Coverage Tracking and Reporting | User Story | Medium | 5 | 🔍 System Testing and Quality Assurance | Testing |
| #50 | Set Up GitHub Actions Testing Pipeline | User Story | High | 5 | 🔍 System Testing and Quality Assurance | Testing |
| #49 | Create MCP Protocol Test Suite | User Story | High | 8 | 🔍 System Testing and Quality Assurance | MCP |
| #48 | Implement BATS Testing Framework | User Story | High | 5 | 🔍 System Testing and Quality Assurance | Testing |

## 📜 Comment Migration

The following issues have comments that should be added to the Notes field in the project:

| Issue # | Title | Type | Comments |
|---------|-------|------|----------|
| #1 | 🔄 Core Agent System Implementation | Epic | 3 |
| #2 | 📡 Model Context Protocol (MCP) Implementation | Epic | 4 |
| #3 | 🧠 Specialized Agent Implementation | Epic | 3 |
| #4 | ⚙️ Agent Task Workflow Implementation | Epic | 3 |
| #5 | 🗄️ Shared Component Implementation | Epic | 3 |
| #6 | 🔗 External Integration Implementation | Epic | 4 |
| #7 | 🔍 System Testing and Quality Assurance | Epic | 6 |

## 👓 Project Views

Create the following views for better organization:

1. **Epics Overview**
   - Filter: Type = Epic
   - Group by: Component
   - Show fields: Title, Priority, Status

2. **Stories by Epic**
   - Filter: Type = User Story
   - Group by: Epic
   - Show fields: Title, Priority, Story Points, Status

3. **Stories by Component**
   - Filter: Type = User Story
   - Group by: Component
   - Show fields: Title, Priority, Story Points, Epic, Status

4. **By Priority**
   - No filter
   - Group by: Priority
   - Show fields: Title, Type, Story Points, Epic, Component, Status

## 🔀 Parent-Child Relationships

After setting up all the issues in the project, you'll need to establish parent-child relationships manually due to API limitations:

1. For each user story, set its Parent issue field to the corresponding epic
2. This must be done manually through the GitHub UI
3. Follow the detailed instructions in the [Parent Issue Guide](/docs/logs/2025-05-17/parent-issue-guide.md)

## 🏁 Final Steps

1. Review all items to ensure they have the correct Type, Priority, and other field values
2. Add the Notes from comment files to each issue with comments
3. Arrange items in each view according to priority
4. Verify all parent-child relationships are correctly established

## 🔄 Related Documents

- [Parent Issue Guide](/docs/logs/2025-05-17/parent-issue-guide.md)
- [GitHub Project Migration](/docs/logs/2025-05-17/github-project-migration.md)

---

🧭 **Navigation**: [Home](/README.md) | [Up](../README.md) | [Parent Issue Guide](/docs/logs/2025-05-17/parent-issue-guide.md)