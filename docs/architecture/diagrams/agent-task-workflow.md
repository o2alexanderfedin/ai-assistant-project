# 🔄 Agent Task Workflow Diagram

This diagram illustrates the flow of tasks through the multi-agent system, from assignment to completion.

```mermaid
graph TD
    %% Define the task workflow process
    subgraph AgentTaskWorkflow["Agent Task Workflow"]
        %% Task stages
        TA["Task\nAssignment"] --> TAN["Task\nAnalysis"]
        TAN --> TD["Task\nDecomposition"]
        TD --> CTC["Child Task\nCreation"]
        CTC --> TE["Task\nExecution"]
        TE --> TC["Task\nCompletion"]
        TC --> TDOC["Task\nDocumentation"]
        
        %% Add Question Handling path
        TAN --> TQ["Task\nQuestion Creation"]
        TQ --> TBL["Task\nBlocked"]
        TBL -.-> TA
    end

    %% Styling
    classDef workflow fill:#f5f5f5,stroke:#333,stroke-width:2px
    classDef task fill:#d1e7dd,stroke:#333,stroke-width:1px
    classDef document fill:#cfe2ff,stroke:#333,stroke-width:1px
    classDef blocked fill:#f8d7da,stroke:#333,stroke-width:1px

    class AgentTaskWorkflow workflow
    class TA,TAN,TD,CTC,TE,TC task
    class TDOC document
    class TQ,TBL blocked
```

## Process Stages

1. **Task Assignment**:
   - Tasks are assigned to agents by the Orchestrator Agent
   - Assignment is based on agent capabilities and availability
   - Assignment includes all necessary context and requirements

2. **Task Analysis**:
   - Agent analyzes the task requirements and constraints
   - Determines approach and required resources
   - Identifies dependencies and prerequisites

3. **Task Question Creation** (Optional):
   - If the agent has questions about the task, it creates a question subtask
   - Questions are documented and linked to the original task
   - Original task is marked as blocked until questions are answered
   - Control is yielded back to the Orchestrator Agent

4. **Task Decomposition**:
   - Complex tasks are broken down into smaller, manageable subtasks
   - Decomposition follows the principle of single responsibility
   - Each subtask has clear acceptance criteria

5. **Child Task Creation**:
   - Subtasks are created in the task management system
   - Child tasks maintain relationships to parent tasks
   - Child tasks may be assigned to different specialized agents

6. **Task Execution**:
   - Tasks are executed according to defined approach
   - Implementation follows test-driven development
   - Regular progress updates are provided

7. **Task Completion**:
   - Final deliverables are submitted
   - Quality assurance checks are performed
   - Task is marked as completed

8. **Task Documentation**:
   - Process and decisions are documented
   - Knowledge gained is captured for future use
   - Documentation is updated in the knowledge base

## Role Responsibilities

| Stage | Primary Responsible Agent | Supporting Agents |
|-------|---------------------------|-------------------|
| Task Assignment | Orchestrator Agent | Agent Registry |
| Task Analysis | Assigned Agent | Analyzer Agent (for complex tasks) |
| Task Question Creation | Assigned Agent | Orchestrator Agent (for routing) |
| Task Decomposition | Analyzer Agent or Assigned Agent | Orchestrator Agent |
| Child Task Creation | Analyzer Agent or Assigned Agent | Orchestrator Agent |
| Task Execution | Assigned Agent (Developer, Tester, etc.) | Various supporting agents |
| Task Completion | Assigned Agent | Reviewer Agent |
| Task Documentation | Documentation Agent | Assigned Agent |

---

<!-- 🧭 NAVIGATION -->
**Navigation**: [Home](../README.md) | [Architecture](../README.md) | [Diagrams](./README.md) | [Agent Task Workflow](../components/agent-task-workflow.md) | [Component Responsibilities](../component-responsibilities.md)

*Last updated: 2025-05-17*