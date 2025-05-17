# ADR-006: Agent-Specific MCP Configuration

**Date**: May 16, 2025  
**Status**: Proposal  
**Deciders**: Architecture Team  
**Contributors**: Developer Agent, DevOps Agent  

## 📑 Table of Contents
- [Context](#context)
- [Decision](#decision)
- [Implementation Options](#implementation-options)
- [Rationale](#rationale)
- [Implications](#implications)
- [Related Decisions](#related-decisions)
- [Notes](#notes)

## 📋 Context

Our multi-agent architecture requires Claude Code instances to connect to specific MCP servers based on their roles. For example, a Reviewer agent needs to connect directly to its Implementer agent, which runs as an MCP server. However, the current Claude Code CLI doesn't provide built-in support for agent-specific MCP server configurations.

We need a mechanism to:
1. Launch Claude Code instances with different MCP server configurations
2. Maintain private connections between agent pairs
3. Support dynamic discovery and connection management
4. Enable secure communication between agents
5. Scale to support multiple agent relationships

## 🚩 Decision

We will implement a configuration layer above Claude Code that manages agent-specific MCP connections. This layer will:

1. Maintain configuration files for each agent role
2. Launch Claude Code instances with appropriate MCP client/server settings
3. Manage connection details securely
4. Provide a consistent interface for agent interactions

The implementation will use shell scripts to abstract the configuration complexity and ensure consistent agent launches.

## 💻 Implementation Options

We've identified several options for implementing this functionality:

### Option 1: Configuration Files and Launch Scripts

```
/config/
  /agents/
    reviewer-1.conf
    implementer-1.conf
    reviewer-2.conf
    implementer-2.conf
  /connections/
    reviewer-1-connections.conf
    reviewer-2-connections.conf
/scripts/
  launch-agent.sh
  manage-connections.sh
```

With this approach:
- Each agent has its own configuration file
- Connections are defined in separate files for security
- Launch scripts read configurations and start Claude Code with appropriate parameters

**Example launch script:**

```bash
#!/bin/bash
# launch-agent.sh

AGENT_ID=$1
CONFIG_DIR="/config/agents"
CONN_DIR="/config/connections"

if [[ ! -f "$CONFIG_DIR/$AGENT_ID.conf" ]]; then
  echo "Error: Agent configuration not found: $AGENT_ID"
  exit 1
fi

# Load agent configuration
source "$CONFIG_DIR/$AGENT_ID.conf"

# Determine if this is a client or server
if [[ "$AGENT_ROLE" == "reviewer" ]]; then
  # Load connection configuration
  if [[ ! -f "$CONN_DIR/$AGENT_ID-connections.conf" ]]; then
    echo "Error: Connection configuration not found for $AGENT_ID"
    exit 1
  fi
  
  source "$CONN_DIR/$AGENT_ID-connections.conf"
  
  # Launch as MCP client
  claude-code --mcp-client --remote=$IMPLEMENTER_ENDPOINT \
    --verbose --debug --system-profile="$AGENT_PROFILE" \
    --personality="$AGENT_PERSONALITY" $ADDITIONAL_ARGS
    
elif [[ "$AGENT_ROLE" == "implementer" ]]; then
  # Launch as MCP server
  claude-code --mcp-server --port=$SERVER_PORT \
    --verbose --debug --system-profile="$AGENT_PROFILE" \
    --personality="$AGENT_PERSONALITY" $ADDITIONAL_ARGS
else
  echo "Error: Unknown agent role: $AGENT_ROLE"
  exit 1
fi
```

### Option 2: Agent Registry Service

Implement a lightweight service that:
- Maintains a registry of all available agents
- Manages connection details
- Provides discovery mechanisms
- Handles authentication and authorization
- Launches agents with appropriate configurations

```bash
#!/bin/bash
# agent-registry.sh

# Start registry service
start_registry() {
  echo "Starting agent registry service on port 8080..."
  # Implementation details...
}

# Register an agent
register_agent() {
  local agent_id=$1
  local agent_role=$2
  local agent_profile=$3
  
  echo "Registering agent: $agent_id (role: $agent_role)"
  # Implementation details...
}

# Connect agents
connect_agents() {
  local client_id=$1
  local server_id=$2
  
  echo "Connecting $client_id to $server_id..."
  # Implementation details...
}

# Launch agent
launch_agent() {
  local agent_id=$1
  
  echo "Launching agent: $agent_id"
  # Get agent configuration from registry
  # Launch Claude Code with appropriate parameters
}

# Main command processing
case "$1" in
  start)
    start_registry
    ;;
  register)
    register_agent "$2" "$3" "$4"
    ;;
  connect)
    connect_agents "$2" "$3"
    ;;
  launch)
    launch_agent "$2"
    ;;
  *)
    echo "Usage: $0 {start|register|connect|launch}"
    exit 1
    ;;
esac
```

### Option 3: Docker Compose-Based Orchestration

Use Docker Compose to define and manage agent relationships:

```yaml
# docker-compose.yml
version: '3'

services:
  implementer-1:
    image: claude-code
    environment:
      - ROLE=implementer
      - PROFILE=developer
      - PERSONALITY=detail-oriented-developer
    command: --mcp-server --port 8000 --verbose --debug
    ports:
      - "8000:8000"
    volumes:
      - ./workspace:/workspace
      
  reviewer-1:
    image: claude-code
    environment:
      - ROLE=reviewer
      - PROFILE=code-reviewer
      - PERSONALITY=thorough-reviewer
      - IMPLEMENTER_ENDPOINT=implementer-1:8000
    command: --mcp-client --remote=${IMPLEMENTER_ENDPOINT} --verbose --debug
    depends_on:
      - implementer-1
    volumes:
      - ./workspace:/workspace
```

## 💡 Rationale

After evaluating the options, we recommend **Option 1: Configuration Files and Launch Scripts** for the following reasons:

1. **Simplicity**: Uses shell scripts and config files without additional services
2. **Security**: Connection details can be managed with appropriate file permissions
3. **Flexibility**: Easy to adapt to different agent configurations
4. **Minimal Dependencies**: No additional infrastructure required
5. **Transparency**: Clear configuration that's easy to inspect and modify
6. **Compatibility**: Works with the existing Claude Code CLI

This approach provides a clean abstraction over the Claude Code CLI that enables agent-specific MCP configurations while maintaining security and flexibility.

## 🔄 Implications

### Positive
- Enables direct Reviewer-to-Implementer connections as designed
- Maintains privacy of connection relationships
- Scales to support multiple agent pairs
- Simplifies agent launch with consistent configuration
- Improves security by abstracting connection details

### Negative
- Additional layer of scripts to maintain
- Requires consistent file structure and permissions
- Manual configuration updates needed for changes
- No built-in monitoring of connections

### Neutral
- Configuration must be maintained outside of Claude Code
- Scripts need to be executed with appropriate permissions
- Configuration changes require agent restarts

## 🔗 Related Decisions

- [ADR-001: Agent Communication Protocol](./001-agent-communication-protocol.md)
- [ADR-003: Agent Task Workflow Standardization](./003-agent-task-workflow.md)
- [ADR-005: Git Hooks for Process Enforcement](./005-git-hooks-process-enforcement.md)

## 📝 Notes

### Security Considerations

1. **Connection File Permissions**: Connection configuration files should have restricted permissions (e.g., 0600)
2. **Environment Variables**: Sensitive connection details can be passed via environment variables instead of config files
3. **Rotation**: Consider rotating connection details periodically
4. **Logging**: Be careful not to log sensitive connection details
5. **Authentication**: Add authentication mechanisms if operating in shared environments

### Production Deployment

For production deployment, consider enhancing the configuration management:

1. **Configuration Encryption**: Encrypt sensitive connection details
2. **Secret Management**: Use a secrets manager for production environments
3. **Health Checks**: Add health check scripts to verify connections
4. **Monitoring**: Add monitoring of agent connections and restarts
5. **High Availability**: Configure fallback connections for critical agents

### Configuration Examples

**Example reviewer-1.conf:**
```
AGENT_ROLE="reviewer"
AGENT_PROFILE="code-reviewer"
AGENT_PERSONALITY="Thorough code reviewer with expertise in software architecture. Analyzes requirements carefully and creates clear acceptance criteria. Provides constructive feedback and ensures implementations meet quality standards."
ADDITIONAL_ARGS="--memory-file=/data/reviewer-1-memory.json"
```

**Example implementer-1.conf:**
```
AGENT_ROLE="implementer"
AGENT_PROFILE="developer"
AGENT_PERSONALITY="Detail-oriented developer focused on implementation excellence. Follows TDD best practices and writes clean, documented code. Responds well to feedback and makes requested revisions thoroughly."
SERVER_PORT=8000
ADDITIONAL_ARGS="--memory-file=/data/implementer-1-memory.json"
```

**Example reviewer-1-connections.conf:**
```
IMPLEMENTER_ENDPOINT="localhost:8000"
IMPLEMENTER_ID="implementer-1"
```

---

🧭 **Navigation**
- [Architecture Decisions Home](./README.md)
- [Architecture Home](../README.md)
- [Previous: Git Hooks Process Enforcement](./005-git-hooks-process-enforcement.md)
- [Related: Direct Reviewer-Implementer MCP Workflow](../diagrams/direct-reviewer-implementer-mcp-workflow.md)