# 🎮 Orchestrator Agent

<!-- 📑 TABLE OF CONTENTS -->
- [🎮 Orchestrator Agent](#-orchestrator-agent)
  - [📋 Overview](#-overview)
  - [🔑 Responsibilities](#-responsibilities)
  - [🧩 Component Architecture](#-component-architecture)
  - [🔄 Core Workflows](#-core-workflows)
  - [🔌 Interfaces](#-interfaces)
  - [⚙️ Configuration](#️-configuration)
  - [📊 Performance Considerations](#-performance-considerations)

---

## 📋 Overview

The Orchestrator Agent is the central coordination component in the multi-agent system. It manages task distribution, agent communication, and oversees the overall workflow. It acts as an MCP server, serving as the primary entry point for tasks and the coordinator for the Reviewer and Implementer agents in the Orchestrator → Reviewer → Implementer chain.

## 🔑 Responsibilities

The Orchestrator Agent is responsible for:

1. **Task Intake**: Monitoring GitHub for new issues and changes to existing issues
2. **Task Analysis Coordination**: Delegating task analysis to the Analyzer Agent
3. **Agent Assignment**: Assigning tasks to appropriate agents based on analysis results
4. **Workflow Management**: Ensuring tasks progress through the TDD workflow correctly
5. **Agent Creation**: Initiating the creation of new specialized agents when needed
6. **System Monitoring**: Tracking the status and workload of all agents
7. **Communication Routing**: Facilitating communication with Reviewer agents via MCP
8. **Task Completion Verification**: Ensuring tasks meet completion criteria before closing

## 🧩 Component Architecture

The Orchestrator Agent consists of several subcomponents:

1. **GitHub Monitor**: Watches for new issues and updates
2. **Task Queue**: Manages prioritization of pending tasks
3. **Agent Registry**: Maintains information about all active agents and their capabilities
4. **Workflow Engine**: Tracks task progress through development stages
5. **Communication Hub**: Routes messages between agents
6. **Agent Factory Controller**: Interfaces with the Agent Factory to create new agents

## 🔄 Core Workflows

### Task Intake and Assignment
1. Monitor GitHub for new issues
2. Extract issue metadata and content
3. Request analysis from Analyzer Agent
4. Select appropriate agent based on analysis
5. Assign task to selected agent
6. Update GitHub issue with assignment information

### Agent Creation
1. Receive recommendation for new agent type from Analyzer
2. Generate agent specification (role, persona, capabilities)
3. Request new agent creation from Agent Factory
4. Register new agent in Agent Registry
5. Assign pending task to the new agent

### Task Status Management
1. Monitor agent progress on assigned tasks
2. Update GitHub issues with status information
3. Facilitate transitions between workflow stages
4. Coordinate code reviews and testing
5. Verify task completion criteria
6. Close tasks when successfully completed

## 🔌 Interfaces

### Input Interfaces
1. **GitHub Webhook**: Receives notifications about issue events
2. **MCP Server Interface**: Receives messages from users and acts as the MCP server for Reviewer agents
3. **Admin API**: Receives administrative commands

### Output Interfaces
1. **MCP Server Interface**: Sends messages to Reviewer agents via MCP
2. **GitHub API Client**: Updates issues and pull requests
3. **Agent Factory API**: Requests creation of new agents
4. **Logging Interface**: Records system activities

## ⚙️ Configuration

The Orchestrator Agent requires the following configuration:

```bash
# Orchestrator Agent Launch Script
#!/bin/bash

# Get directory where script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Create workspace directory
WORKSPACE_DIR="${SCRIPT_DIR}/workspace/orchestrator"
mkdir -p "$WORKSPACE_DIR"

# Path to system prompt file
SYSTEM_PROMPT_FILE="${SCRIPT_DIR}/orchestrator-prompt.md"

# Read system prompt from file
SYSTEM_PROMPT=$(cat "$SYSTEM_PROMPT_FILE")

# Change to workspace directory
cd "$WORKSPACE_DIR"

# Launch Orchestrator in interactive mode with debug flags
printf "Starting Orchestrator MCP server in interactive mode...\n"
printf "Workspace: $WORKSPACE_DIR\n"
printf "System prompt: $SYSTEM_PROMPT_FILE\n"

# Start Claude MCP server with system prompt
# The Orchestrator interacts with the user directly and communicates with other agents via STDIO
claude mcp serve --system-prompt "$SYSTEM_PROMPT" --interactive --print --debug --verbose --mcp-debug
```

### STDIO-Based MCP Communication

The Orchestrator communicates with Reviewer agents through standard STDIO streams:

```bash
# Example of how the Orchestrator launches and communicates with a Reviewer agent
#!/bin/bash

# Launch the Reviewer agent and capture its STDIO streams
reviewer_process=$(claude mcp serve --system-prompt "$(cat reviewer-prompt.md)" --print --debug --verbose)

# Send MCP message to the Reviewer through STDIO
echo '@mcp_call
{
  "recipient": "reviewer",
  "action": "assign_task",
  "task": { ... }
}
@end_mcp_call' | $reviewer_process

# Receive response from Reviewer's STDOUT
response=$($reviewer_process)
echo "Received from Reviewer: $response"
```

### Example Orchestrator MCP Message to Reviewer

```
@mcp_call
{
  "recipient": "reviewer",
  "action": "assign_task",
  "task": {
    "id": "TASK-123",
    "title": "Implement feature X",
    "description": "Create a component that...",
    "requirements": [
      "Must handle edge cases",
      "Should integrate with existing systems",
      "Performance criteria..."
    ],
    "priority": "high",
    "deadline": "2025-05-20"
  }
}
@end_mcp_call
```

## 📊 Performance Considerations

To ensure optimal performance, the Orchestrator Agent:

1. Processes GitHub events asynchronously
2. Maintains a priority queue for pending tasks
3. Implements load balancing across available agents
4. Uses efficient message routing to minimize communication overhead
5. Caches agent capability information for faster assignment decisions

---

<!-- 🧭 NAVIGATION -->
**Navigation**: [Home](../README.md) | [Component Index](./README.md) | [Analyzer Agent](./analyzer.md)

*Last updated: 2025-05-16*