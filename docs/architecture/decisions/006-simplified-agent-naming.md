# ADR-006: Simplified Agent Naming and Connection

**Date**: May 16, 2025  
**Status**: Accepted  
**Deciders**: Architecture Team  

## 📑 Table of Contents
- [Context](#context)
- [Decision](#decision)
- [Implementation](#implementation)
- [Rationale](#rationale)
- [Implications](#implications)

## 📋 Context

We need a simple way for Claude Code agents to connect to specific MCP servers based on their roles. For instance, a Reviewer agent needs to connect directly to its Implementer agent running as an MCP server.

## 🚩 Decision

We will adopt a simplified approach based on the following constraints:
1. Each agent has a unique, meaningful name
2. Only one instance of a specific agent runs on a machine at any time
3. All Claude Code instances use the same list of MCP servers
4. Agents directly address each other by name

## 💻 Implementation

### Agent Naming Convention

Agents will follow a clear naming convention:

```
[role]-[project]-[number]
```

For example:
- `reviewer-api-1`
- `implementer-api-1`
- `tester-api-1`

### Shared MCP Server Configuration

All Claude Code instances will be configured with the same list of MCP servers in a shared configuration:

```
reviewer-api-1=localhost:8001
implementer-api-1=localhost:8002
tester-api-1=localhost:8003
reviewer-ui-1=localhost:8004
implementer-ui-1=localhost:8005
```

### Agent Launch

Agents will be launched with their specific role and name:

```bash
# Launch Implementer (MCP Server)
claude-code --name="implementer-api-1" --mcp-server --port=8002 \
  --system-profile="implementer" --verbose --debug

# Launch Reviewer (MCP Client)
claude-code --name="reviewer-api-1" --mcp-client \
  --system-profile="reviewer" --verbose --debug
```

### Direct Connection

The Reviewer agent can directly invoke the Implementer by name:

```python
# Inside the Reviewer agent
def assign_implementation_task(task_details, acceptance_criteria):
    # Direct MCP call to the Implementer by name
    response = mcp.invoke("implementer-api-1", {
        "task": task_details,
        "acceptance_criteria": acceptance_criteria
    })
    return response
```

## 💡 Rationale

This simplified approach offers several advantages:

1. **Simplicity**: No need for complex configuration management
2. **Clarity**: Each agent has a clear, meaningful name
3. **Directness**: Agents can invoke each other directly by name
4. **Consistency**: All agents use the same server list
5. **Low Overhead**: Minimal setup and management required

## 🔄 Implications

### Positive
- Much simpler implementation than a full configuration layer
- Clear naming makes the system easier to understand and debug
- Direct addressing simplifies the communication pattern

### Constraints
- Only one instance of each agent can run on a machine
- All agents must be aware of all other agents
- Port conflicts must be managed manually
- No dynamic discovery of new agents

---

🧭 **Navigation**
- [Architecture Decisions Home](./README.md)
- [Architecture Home](../README.md)
- [Related: Direct Reviewer-Implementer MCP Workflow](../diagrams/direct-reviewer-implementer-mcp-workflow.md)