# Orchestrator Use Cases and Workflows

*Last Updated: May 17, 2025*

## 📑 Table of Contents
- [Overview](#overview)
- [UML Use Case Diagrams](#uml-use-case-diagrams)
  - [Core Orchestrator Use Cases](#core-orchestrator-use-cases)
  - [Task Decomposition Use Cases](#task-decomposition-use-cases)
  - [Task Implementation Use Cases](#task-implementation-use-cases)
  - [Task Completion Use Cases](#task-completion-use-cases)
- [Primary Use Cases](#primary-use-cases)
  - [Task Intake from GitHub](#task-intake-from-github)
  - [Task Breakdown with Decomposition Pair](#task-breakdown-with-decomposition-pair)
  - [Task Assignment to Implementation Teams](#task-assignment-to-implementation-teams)
  - [Task Completion and Status Tracking](#task-completion-and-status-tracking)
- [Workflow Diagrams](#workflow-diagrams)
  - [Complete Task Lifecycle](#complete-task-lifecycle)
  - [Task Decomposition Flow](#task-decomposition-flow)
  - [Multi-Agent Orchestration](#multi-agent-orchestration)
- [Pull Request Policy](#pull-request-policy)
- [Edge Cases](#edge-cases)

## Overview

The Orchestrator is the central coordination component in the multi-agent system. It manages the task lifecycle by pulling tasks from GitHub and dispatching them to specialized agent pairs. Each agent pair follows the Reviewer-Implementer pattern but with different specializations (Decomposition, Code, Documentation, Testing, etc.). The Orchestrator monitors agent pair status and can resume stalled pairs when needed. All task tracking happens through GitHub, with agent pairs updating task statuses directly. This document outlines the use cases, actors, and workflows for the Orchestrator and the agent pairs it coordinates.

## UML Use Case Diagrams

### Core Orchestrator Use Cases

#### User Use Cases

```mermaid
graph TD
    user([User])
    
    UC1((Create GitHub Issue))
    UC2((Update Issue Details))
    UC3((View Task Progress in GitHub))
    
    %% User interactions
    user --> UC1
    user --> UC2
    user --> UC3
```


#### Orchestrator Use Cases

```mermaid
graph TD
    orchestrator([Orchestrator])
    
    UC1((Pull Tasks from GitHub))
    UC2((Dispatch Tasks to Agent Pairs))
    UC3((Monitor Agent Pair Status))
    UC4((Resume Stalled Agent Pairs))
    UC5((Update Task Status in GitHub))
    
    %% Orchestrator interactions
    orchestrator --> UC1
    orchestrator --> UC2
    orchestrator --> UC3
    orchestrator --> UC4
    orchestrator --> UC5
    
    %% <<include>> relationships
    UC3 -.-> |<<include>>| UC4
```

### Task Decomposition Use Cases

#### Agent Pair Pattern

All specialized agents follow the general Agent Pair pattern (Reviewer-Implementer) and work within the scope of gitflow branches (feature/, fix/, release/, etc.):

- **Reviewer**: 
  - Always starts by creating acceptance criteria (text or code tests) and documents them in the task
  - Creates the appropriate gitflow branch (feature/X, fix/Y, etc.) for the task
  - Builds/compiles code and runs tests, linters, etc. where applicable
  - Uses all available means to evaluate correctness against the acceptance criteria
  - Handles pull request creation and management

- **Implementer**: 
  - Always implements against the given criteria provided by the Reviewer
  - May build/compile and run tests during implementation
  - Works within the gitflow branch created by the Reviewer
  - Commits changes to the designated branch following gitflow conventions

#### Decomposition Pair Structure

The Decomposition Pair specializes this pattern for task analysis:
- **Decomposition-Reviewer**: Creates criteria for proper task analysis, evaluates tasks, determines complexity, decides on decomposition
- **Decomposition-Implementer**: Implements the technical aspects of task decomposition according to the criteria

#### Decomposition-Reviewer Use Cases

```mermaid
graph TD
    decompositionReviewer([Decomposition-Reviewer])
    
    UC1((Receive Task from Orchestrator))
    UC2((Create Decomposition Acceptance Criteria))
    UC3((Analyze Task Complexity))
    UC4((Apply Criteria to Task Assessment))
    UC5((Decide on Decomposition))
    UC6((Create Subtasks in GitHub))
    UC7((Tag Task as Analyzed))
    UC8((Update Task in GitHub))
    
    %% Decomposition-Reviewer interactions
    decompositionReviewer --> UC1
    decompositionReviewer --> UC2
    decompositionReviewer --> UC3
    decompositionReviewer --> UC4
    decompositionReviewer --> UC5
    decompositionReviewer --> UC6
    decompositionReviewer --> UC7
    decompositionReviewer --> UC8
    
    %% <<include>> relationships
    UC3 -.-> |<<include>>| UC4
    UC4 -.-> |<<include>>| UC5
    UC5 -.-> |<<include>>| UC6
    UC6 -.-> |<<include>>| UC7
    UC7 -.-> |<<include>>| UC8
```


### Task Implementation Use Cases

#### Orchestrator Implementation Use Cases

```mermaid
graph TD
    orchestrator([Orchestrator])
    
    UC1((Pull Implementation Task from GitHub))
    UC2((Dispatch Task to Reviewer-Implementer Pair))
    UC3((Monitor Implementation Pair Status))
    UC4((Resume Stalled Implementation Pair))
    UC5((Update Implementation Status in GitHub))
    
    %% Orchestrator interactions
    orchestrator --> UC1
    orchestrator --> UC2
    orchestrator --> UC3
    orchestrator --> UC4
    orchestrator --> UC5
```

#### Reviewer Agent Use Cases

```mermaid
graph TD
    reviewer([Reviewer Agent])
    
    UC1((Create Acceptance Criteria))
    UC2((Execute Criteria Tests))
    UC3((Review Implementation))
    UC4((Request Revisions))
    UC5((Approve Implementation))
    
    %% Reviewer interactions
    reviewer --> UC1
    reviewer --> UC2
    reviewer --> UC3
    reviewer --> UC4
    reviewer --> UC5
    
    %% <<include>> relationships
    UC3 -.-> |<<include>>| UC2
    UC3 -.-> |<<include>>| UC4
    UC3 -.-> |<<include>>| UC5
    UC5 -.-> |<<include>>| UC6((Update Task Status))
```

#### Implementer Agent Use Cases

```mermaid
graph TD
    implementer([Implementer Agent])
    
    UC1((Receive Acceptance Criteria))
    UC2((Implement Against Criteria))
    UC3((Verify Against Criteria))
    UC4((Submit Implementation))
    UC5((Revise Based on Feedback))
    
    %% Implementer interactions
    implementer --> UC1
    implementer --> UC2
    implementer --> UC3
    implementer --> UC4
    implementer --> UC5
    
    %% <<include>> relationships
    UC2 -.-> |<<include>>| UC3
    UC3 -.-> |<<include>>| UC4
```


### Task Completion Use Cases

#### Orchestrator Completion Use Cases

```mermaid
graph TD
    orchestrator([Orchestrator])
    
    UC1((Pull Completion Status from GitHub))
    UC2((Update Parent Task in GitHub))
    UC3((Monitor Remaining Subtasks))
    UC4((Mark Tasks as Complete in GitHub))
    
    %% Orchestrator interactions
    orchestrator --> UC1
    orchestrator --> UC2
    orchestrator --> UC3
    orchestrator --> UC4
```

#### User Completion Use Cases

```mermaid
graph TD
    user([User])
    
    UC6((Receive Completion Notification))
    
    %% User interactions
    user --> UC6
```


## Primary Use Cases

### Task Intake from GitHub

```mermaid
sequenceDiagram
    participant User
    participant GitHub
    participant Orchestrator
    
    User->>GitHub: Create issue with task details
    GitHub-->>Orchestrator: Issue notification
    Orchestrator->>GitHub: Pull task information
    Note over Orchestrator: Process task metadata
    Orchestrator->>GitHub: Update task with status tag
```

The Orchestrator's first responsibility is to pull tasks from GitHub:

1. User creates a GitHub issue with task details
2. GitHub notification triggers Orchestrator
3. Orchestrator pulls the task information from GitHub
4. Orchestrator processes the task metadata
5. Orchestrator updates the task with appropriate status tags

### Task Breakdown with Decomposition Pair

```mermaid
sequenceDiagram
    participant GitHub
    participant Orchestrator
    participant DecompReviewer as Decomposition-Reviewer
    participant DecompImplementer as Decomposition-Implementer
    
    GitHub-->>Orchestrator: New issue notification
    Orchestrator->>GitHub: Fetch issue details
    Orchestrator->>DecompReviewer: MCP: Task decomposition request
    
    Note over DecompReviewer: Create decomposition criteria<br>(complexity thresholds, subtask structure rules)
    DecompReviewer->>GitHub: Document criteria in task/issue
    DecompReviewer->>GitHub: Create gitflow branch<br>(decomp/task-id) if needed
    DecompReviewer->>DecompImplementer: MCP: Task with decomposition criteria and branch
    
    Note over DecompImplementer: Evaluate task against criteria
    
    alt Task Requires Decomposition
        DecompImplementer->>GitHub: Create subtask issues according to criteria
        DecompImplementer->>GitHub: Establish task dependencies
        DecompImplementer->>GitHub: Link subtasks to parent
        DecompImplementer->>GitHub: Tag tasks appropriately
        Note over DecompImplementer: Commit changes if creating artifacts
    end
    
    DecompImplementer->>DecompReviewer: MCP: Decomposition results for review
    Note over DecompReviewer: Verify decomposition against all criteria<br>Use all available tools to evaluate correctness
    
    alt If Code Artifacts Were Created
        DecompReviewer->>GitHub: Create pull request from decomp branch
    end
    DecompReviewer->>GitHub: Tag task as processed
    DecompReviewer->>Orchestrator: MCP: Decomposition completed
```

For new tasks, the Orchestrator delegates task breakdown to a specialized Decomposition Pair working within the gitflow workflow:

1. Orchestrator detects new GitHub issue requiring assessment
2. Orchestrator assigns the task to the Decomposition-Reviewer
3. Decomposition-Reviewer begins by creating decomposition criteria:
   - Defines thresholds for task complexity
   - Establishes rules for when and how to break down tasks
   - Sets requirements for proper subtask structure and relationships
4. Decomposition-Reviewer documents these criteria in the GitHub issue/task
5. Decomposition-Reviewer creates a gitflow branch (e.g., decomp/task-id)
6. Decomposition-Reviewer sends these criteria and branch info to the Decomposition-Implementer
6. Decomposition-Implementer evaluates the task against the criteria
7. If decomposition is needed, Decomposition-Implementer:
   - Creates subtask issues in GitHub according to criteria
   - Establishes dependencies between subtasks
   - Links subtasks to the parent issue
   - Tags tasks appropriately
   - Commits all changes to the decomposition branch
8. Decomposition-Implementer submits results to Decomposition-Reviewer
9. Decomposition-Reviewer verifies the decomposition meets all acceptance criteria
   - Uses all available tools and methods to evaluate correctness
   - Ensures all criteria are satisfied
10. Decomposition-Reviewer tags the original task as processed
11. Decomposition-Reviewer notifies Orchestrator that decomposition is complete

> **Note**: Pull Requests are only created when actual artifacts (such as code, documentation, or images) have been committed to the repository. For decomposition activities that only involve analyzing tasks and creating/linking GitHub issues, no PR is needed. See the [Pull Request Policy](#pull-request-policy) section for details.

### Task Assignment to Implementation Teams

```mermaid
sequenceDiagram
    participant GitHub
    participant Orchestrator
    participant Reviewer
    participant Implementer
    
    GitHub-->>Orchestrator: Issue tagged as ready for implementation
    Orchestrator->>GitHub: Pull issue details
    Note over Orchestrator: Select appropriate implementation pair
    Orchestrator->>Reviewer: MCP: Task assignment
    
    Note over Reviewer: Create & document acceptance criteria<br>(text or code tests) in GitHub
    Reviewer->>GitHub: Create gitflow branch<br>(feature/X, fix/Y, etc.)
    Reviewer->>Implementer: MCP: Criteria, branch, and implementation request
    
    Note over Implementer: Implement against criteria<br>Build/test as needed<br>Commit to gitflow branch<br>Verify against criteria<br>Document work
    
    Implementer->>Reviewer: MCP: Implementation for review
    Note over Reviewer: Build/compile if applicable<br>Run tests, linters, etc.<br>Evaluate against all acceptance criteria
    
    alt Implementation Needs Revision
        Reviewer->>Implementer: MCP: Feedback on criteria failures
        Note over Implementer: Revise implementation<br>Additional commits to branch
        Implementer->>Reviewer: MCP: Revised implementation
    else Implementation Approved
        Note over Reviewer: Decide on branch disposition after work is done
        alt Work Meets Requirements - Create PR
            Reviewer->>GitHub: Create pull request from gitflow branch
            Reviewer->>GitHub: Update issue with implementation link
            Reviewer->>GitHub: Tag as implemented
            Reviewer->>Orchestrator: MCP: Task completed with PR link
        else Work Does Not Meet Requirements - Delete Branch
            Reviewer->>GitHub: Delete gitflow branch (if not needed)
            Reviewer->>GitHub: Document decision in issue
            Reviewer->>GitHub: Tag as rejected/incomplete
            Reviewer->>Orchestrator: MCP: Task rejected or incomplete
        end
    end
```

Once a task is analyzed and ready for implementation:

1. Orchestrator selects the appropriate Reviewer-Implementer pair based on:
   - Task domain and requirements
   - Agent capabilities and availability
   - Current workload balancing
2. Orchestrator assigns the task to the selected Reviewer
3. The Reviewer-Implementer pair works on the task following gitflow conventions:
   - Reviewer starts by creating acceptance criteria (text or code tests)
   - Reviewer documents these criteria in the GitHub issue/task
   - Reviewer creates the appropriate gitflow branch (feature/X, fix/Y, etc.)
   - Reviewer sends criteria, branch info, and implementation request to Implementer
   - Implementer implements solution against the given criteria
   - Implementer may build/compile and run tests during implementation
   - Implementer commits changes to the gitflow branch
   - Implementer verifies against criteria before submitting
   - Reviewer builds/compiles the code if applicable
   - Reviewer runs tests, linters, and other available tools
   - Reviewer evaluates implementation against all acceptance criteria
   - Reviewer provides feedback on criteria failures if needed
   - Implementer makes additional commits to address feedback
4. After the Implementer's work is complete, the Reviewer evaluates and decides:
   - If the work meets requirements and produces valuable artifacts:
     - Reviewer creates a pull request from the gitflow branch
     - Reviewer updates the GitHub issue with implementation link
     - Reviewer tags the issue as implemented
     - Reviewer notifies Orchestrator that the task is completed with PR link
   - If the work does not meet requirements or is not valuable:
     - Reviewer may delete the gitflow branch if it's not needed
     - Reviewer documents the decision in the GitHub issue
     - Reviewer tags the issue appropriately (rejected, incomplete, etc.)
     - Reviewer notifies Orchestrator of the task status

> **Note**: Pull Requests are only created when the work produced valuable artifacts that should be merged. The Reviewer has the authority to decide whether to create a PR or delete the branch based on the quality and value of the completed work. See the [Pull Request Policy](#pull-request-policy) section for details.

### Task Completion and Status Tracking

```mermaid
sequenceDiagram
    participant GitHub
    participant Orchestrator
    participant User
    
    Note over Orchestrator: Monitor implementation task statuses
    Orchestrator->>GitHub: Check status of all subtasks
    
    alt All Subtasks Complete
        Orchestrator->>GitHub: Mark parent task as completed
        Orchestrator->>GitHub: Add summary of all subtask results
        Orchestrator->>User: Notify of complete task with summary
    else Subtasks Still In Progress
        Orchestrator->>GitHub: Update parent task with progress info
        Orchestrator->>User: Provide progress update if requested
    end
```

The Orchestrator manages task completion and status tracking:

1. Orchestrator monitors the status of all tasks and subtasks
2. For parent tasks with subtasks:
   - Orchestrator checks if all subtasks are complete
   - If complete, marks the parent task as completed
   - Adds a comprehensive summary of all subtask results
3. Orchestrator notifies users of task completion or progress as appropriate
4. Orchestrator maintains a complete task history and relationship map

## Workflow Diagrams

### Complete Task Lifecycle

```mermaid
graph TD
    A[User Creates GitHub Issue] --> B[Orchestrator Pulls Task]
    B --> C[Assign to Decomposition Pair]
    C --> D{Analysis Decision}
    D -->|Complex| E[Decomposition Pair Creates Subtasks]
    D -->|Simple| F[Tag as Ready for Implementation]
    
    E --> G[Link Subtasks to Parent]
    G --> H[Tag Subtasks as Ready]
    
    F --> I[Orchestrator Pulls Implementation Task]
    H --> I
    
    I --> J[Assign to Implementation Pair]
    J --> K[Reviewer-Implementer Work]
    K --> L[Task Completion in GitHub]
    
    L --> M{Parent Task?}
    M -->|Yes| N[Orchestrator Monitors Subtasks]
    N --> O{All Subtasks Done?}
    O -->|No| P[Continue Monitoring]
    O -->|Yes| Q[Mark Parent Complete in GitHub]
    M -->|No| R[Task Done]
    Q --> R
    
    style A fill:#d5e5f9,stroke:#333,stroke-width:2px
    style B fill:#d5e5f9,stroke:#333,stroke-width:2px
    style L fill:#d5f9e5,stroke:#333,stroke-width:2px
    style Q fill:#d5f9e5,stroke:#333,stroke-width:2px
    style R fill:#d5f9e5,stroke:#333,stroke-width:2px
```

### Task Decomposition Flow

```mermaid
graph TD
    A[Complex Task] --> B[Decomposition Pair Assessment]
    B --> C[Identification of Subtasks]
    C --> D[Create Relationship Map]
    D --> E[Determine Dependencies]
    E --> F[Create GitHub Issues]
    F --> G[Link to Parent Issue]
    
    G --> H{Subtasks Ready?}
    H -->|Yes| I[Assign to Teams]
    H -->|No| J[Resolve Blockers]
    J --> H
    
    I --> K[Track Completion]
    K --> L[Roll Up Results to Parent]
    
    style A fill:#f9d5e5,stroke:#333,stroke-width:2px
    style L fill:#d5f9e5,stroke:#333,stroke-width:2px
```

### Multi-Agent Orchestration

```mermaid
graph TD
    F[GitHub Repository] --> A[Orchestrator]
    A --> B[Decomposition Pair]
    A --> C[Implementation Pair 1]
    A --> D[Implementation Pair 2]
    A --> E[Implementation Pair N]
    
    %% Agent Pair Pattern
    subgraph "Agent Pair Pattern"
        GP1[Reviewer] --- GP2[Implementer]
    end
    
    %% Analysis Specialization
    B --> B1[Decomposition-Reviewer]
    
    %% Implementation Specializations
    C --> C1[Code-Reviewer]
    C --> C2[Code-Implementer]
    
    D --> D1[Doc-Reviewer]
    D --> D2[Doc-Implementer]
    
    E --> E1[Test-Reviewer]
    E --> E2[Test-Implementer]
    
    B1 --> B2[Decomposition-Implementer]
    B1 --> F
    B2 --> F
    C1 --> F
    D1 --> F
    E1 --> F
    
    style A fill:#d5e5f9,stroke:#333,stroke-width:3px
    style B fill:#f9d5e5,stroke:#333,stroke-width:2px
    style C fill:#e5d5f9,stroke:#333,stroke-width:2px
    style D fill:#e5d5f9,stroke:#333,stroke-width:2px
    style E fill:#e5d5f9,stroke:#333,stroke-width:2px
    style F fill:#f9f9d5,stroke:#333,stroke-width:2px
    style GP1 fill:#ffeedd,stroke:#333,stroke-width:1px
    style GP2 fill:#ffeedd,stroke:#333,stroke-width:1px
```

## Pull Request Policy

The system follows these guidelines for when to create Pull Requests:

1. **PRs ARE Required When**:
   - Actual artifacts (code, documentation, images, etc.) have been committed to the repository
   - Implementation tasks that produce valuable files stored in the repository
   - Any work that modifies or adds files tracked by git that should be kept

2. **PRs ARE NOT Required When**:
   - Tasks only involve creating or updating GitHub issues
   - Task decomposition that only results in issue creation/linking
   - Work that only modifies GitHub metadata (labels, assignments, etc.)
   - No files were committed to the repository
   - The Reviewer determines that the work does not meet quality standards or is not valuable

3. **Reviewer Authority**:
   - Reviewers have the final authority to decide whether work merits a PR
   - After work is completed, Reviewers evaluate the results and decide to:
     - Create a PR if the work should be merged into the codebase
     - Delete the branch if the work is not of sufficient quality/value
   - This decision must be documented in the GitHub issue

Examples:
- A Decomposition Pair that only creates subtasks in GitHub does NOT need a PR
- An Implementation Pair adding quality code files DOES need a PR
- An Implementation Pair whose work is deemed insufficient will have their branch deleted (NO PR)
- A Documentation Pair submitting well-formed diagrams or text files DOES need a PR
- Teams only updating issue status or adding comments do NOT need a PR

This policy ensures that PRs are used efficiently, only for changes that require formal review and integration into the codebase. It also gives Reviewers appropriate control over code quality by allowing them to reject work that doesn't meet standards.

## Edge Cases

The Orchestrator must handle various edge cases, including:

1. **Task Decomposition Refinement**: Sometimes the initial decomposition may need refinement
   - Orchestrator detects decomposition issues
   - Re-assigns to Decomposition Pair for refinement
   - Updates GitHub with refined decomposition

2. **Implementation Team Reassignment**: When a team cannot complete a task
   - Reviewer reports inability to complete
   - Orchestrator selects new team
   - Transfers context and updates GitHub

3. **Subtask Dependency Management**: When subtasks have dependencies
   - Orchestrator tracks dependency graph
   - Schedules subtasks according to dependencies
   - Handles blocked tasks appropriately

4. **Failure Recovery**: When a task implementation fails
   - Analyzes failure information
   - Determines recovery strategy
   - May create new issues for recovery work

---

🧭 **Navigation**
- [Architecture Diagrams Home](./README.md)
- [System Overview](../system-overview.md)
- [Consolidated MCP Workflow](./consolidated-mcp-workflow.md)
- [Orchestrator Component](../components/orchestrator.md)

*Last updated: May 17, 2025*