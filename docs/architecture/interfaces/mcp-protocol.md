# 🔄 Model Context Protocol (MCP) Interface

<!-- 📑 TABLE OF CONTENTS -->
- [🔄 Model Context Protocol (MCP) Interface](#-model-context-protocol-mcp-interface)
  - [📋 Overview](#-overview)
  - [🔌 Client-Server Architecture](#-client-server-architecture)
  - [📨 Message Format](#-message-format)
  - [🔄 Message Types](#-message-types)
  - [📊 MCP Debug Mode](#-mcp-debug-mode)
  - [🔑 Implementation Requirements](#-implementation-requirements)
  - [🧪 Testing Considerations](#-testing-considerations)
  - [📚 Launch Scripts](#-launch-scripts)

---

## 📋 Overview

The Model Context Protocol (MCP) is the primary communication mechanism between agents in the system. Each agent is a Claude instance running with `claude mcp serve` command and communicating with other agents via MCP calls. This document defines how the Claude MCP protocol is implemented in our multi-agent system.

## 🔌 STDIO-Based MCP Architecture

In our implementation, each Claude instance operates using the `claude mcp serve` command and communicates through standard input and output (STDIO):

1. **MCP Servers**: Each agent runs as an MCP server that:
   - Operates in its own workspace directory
   - Is launched with a specific system prompt file
   - Processes requests via STDIO
   - Maintains its context for conversations

2. **MCP Communication**: Agents communicate by:
   - Using the `@mcp_call` and `@mcp_response` syntax via STDIO
   - Specifying the recipient agent by name
   - Sending JSON-formatted payloads
   - Operating in a hierarchical arrangement (Orchestrator → Reviewer → Implementer)

## 📨 Message Format

Claude MCP messages use a specific syntax format:

For MCP calls:
```
@mcp_call
{
  "recipient": "agent-name",
  "action": "action-type",
  "task": {
    // Task-specific payload
  }
}
@end_mcp_call
```

For MCP responses:
```
@mcp_response
{
  "status": "completed|in_progress|failed",
  "task_id": "task-identifier",
  "result": {
    // Result payload
  }
}
@end_mcp_response
```

## 🔄 Message Types

The system uses the following MCP message types:

1. **Task Assignment**: From Orchestrator to Reviewer
   - Task details, requirements, and constraints
   - Expected deliverables and priorities
   - Task identification information
   
   Example:
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
         "Should integrate with existing systems"
       ],
       "priority": "high"
     }
   }
   @end_mcp_call
   ```

2. **Implementation Request**: From Reviewer to Implementer
   - Task details with acceptance criteria
   - Context and constraints
   - Technical requirements

   Example:
   ```
   @mcp_call
   {
     "recipient": "implementer",
     "action": "implement_solution",
     "task_id": "TASK-123",
     "acceptance_criteria": [
       "Must follow coding standards",
       "All tests must pass"
     ],
     "context": {
       "existing_components": ["ComponentA", "ComponentB"],
       "technical_constraints": ["Use TypeScript"]
     }
   }
   @end_mcp_call
   ```

3. **Implementation Response**: From Implementer to Reviewer
   - Implementation details and code
   - Test results
   - Documentation
   
   Example:
   ```
   @mcp_response
   {
     "status": "completed",
     "task_id": "TASK-123",
     "implementation": {
       "code": "// Implementation code here...",
       "documentation": "# Documentation\n...",
       "test_results": {
         "passed": 15,
         "failed": 0,
         "coverage": "92%"
       }
     },
     "notes": "I followed all specified requirements..."
   }
   @end_mcp_response
   ```

4. **Task Completion**: From Reviewer to Orchestrator
   - Final implementation details
   - Review results
   - Status information

## 📊 MCP Debug Mode

All agents run with MCP debug mode enabled (`--mcp-debug`), which provides:

1. **Verbose Logging**: Detailed logs of all MCP traffic
2. **Message Inspection**: Complete message contents for debugging
3. **Timing Information**: Performance metrics for message processing
4. **Connection Diagnostics**: Network and connection status details
5. **Context Tracking**: Information about context usage and management

Debug logs are stored in a structured format for analysis and troubleshooting.

## 🔑 Implementation Requirements

Agent implementations must adhere to these requirements:

1. **Server Configuration**:
   - Dedicated port for MCP server
   - Proper error handling and reporting
   - Connection limit management

2. **Client Configuration**:
   - Dynamic endpoint management
   - Connection pooling
   - Timeout and retry handling

3. **Message Processing**:
   - Validation of incoming messages
   - Proper message routing
   - Concurrency management
   - Error handling and recovery

## 🧪 Testing Considerations

Testing the MCP implementation requires:

1. **Agent Isolation Testing**: Verify each agent can function independently
2. **Communication Testing**: Validate message exchange between agents
3. **Error Handling Testing**: Confirm proper handling of network issues
4. **Performance Testing**: Assess message throughput and latency
5. **Integration Testing**: Test the complete agent network

## 📚 Launch Scripts

Launch scripts for the three agents in our Orchestrator → Reviewer → Implementer chain:

```bash
#!/bin/bash
# launch-agent-team.sh

# Get directory where script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Create workspace and log directories
WORKSPACE_DIR="${SCRIPT_DIR}/workspace"
LOG_DIR="${SCRIPT_DIR}/logs"
mkdir -p "$WORKSPACE_DIR/orchestrator" "$WORKSPACE_DIR/reviewer" "$WORKSPACE_DIR/implementer"
mkdir -p "$LOG_DIR"

# System prompt files
ORCHESTRATOR_PROMPT="${SCRIPT_DIR}/orchestrator-prompt.md"
REVIEWER_PROMPT="${SCRIPT_DIR}/reviewer-prompt.md"
IMPLEMENTER_PROMPT="${SCRIPT_DIR}/implementer-prompt.md"

# Check if system prompt files exist
for PROMPT_FILE in "$ORCHESTRATOR_PROMPT" "$REVIEWER_PROMPT" "$IMPLEMENTER_PROMPT"; do
  if [ ! -f "$PROMPT_FILE" ]; then
    echo "System prompt file not found: $PROMPT_FILE"
    exit 1
  fi
done

# Launch Implementer MCP Server
echo "Starting Implementer MCP server..."
cd "$WORKSPACE_DIR/implementer"
nohup claude mcp serve --system-prompt "$(cat "$IMPLEMENTER_PROMPT")" \
  --print --debug --verbose --mcp-debug > "$LOG_DIR/implementer.log" 2>&1 &
IMPLEMENTER_PID=$!
echo "Implementer started with PID: $IMPLEMENTER_PID"

# Launch Reviewer MCP Server
echo "Starting Reviewer MCP server..."
cd "$WORKSPACE_DIR/reviewer"
nohup claude mcp serve --system-prompt "$(cat "$REVIEWER_PROMPT")" \
  --print --debug --verbose --mcp-debug > "$LOG_DIR/reviewer.log" 2>&1 &
REVIEWER_PID=$!
echo "Reviewer started with PID: $REVIEWER_PID"

# Wait for agents to initialize
sleep 5

# Launch Orchestrator in interactive terminal
echo "Starting Orchestrator in interactive mode..."
cd "$WORKSPACE_DIR/orchestrator"
osascript -e "tell application \"Terminal\" to do script \"cd '$WORKSPACE_DIR/orchestrator' && claude mcp serve --system-prompt '$(cat "$ORCHESTRATOR_PROMPT")' --interactive --print --debug --verbose\""

echo "Agent team launched successfully!"
echo "Orchestrator: Interactive terminal"
echo "Reviewer: PID $REVIEWER_PID, log: $LOG_DIR/reviewer.log"
echo "Implementer: PID $IMPLEMENTER_PID, log: $LOG_DIR/implementer.log"
echo ""
echo "To stop background agents, run: kill $REVIEWER_PID $IMPLEMENTER_PID"
```

---

<!-- 🧭 NAVIGATION -->
**Navigation**: [Home](../README.md) | [Interface Index](./README.md) | [GitHub Interface](./github-interface.md)

*Last updated: 2024-05-16*