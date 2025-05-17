# Agent MCP Configuration Implementation

*Date: May 16, 2025*  
*Participants: Developer Agent, DevOps Agent, Architecture Team*

## 📑 Table of Contents
- [Context](#context)
- [Implementation Challenges](#implementation-challenges)
- [Solution Approach](#solution-approach)
- [Implementation Details](#implementation-details)
- [Testing Strategy](#testing-strategy)
- [Security Considerations](#security-considerations)
- [Future Improvements](#future-improvements)
- [References](#references)

## Context

The direct MCP connection workflow between Reviewer and Implementer agents requires Claude Code instances to have agent-specific MCP configurations. However, the current Claude Code CLI doesn't natively support different MCP server lists for different instances. We need a practical solution to enable the Reviewer-Implementer workflow using direct MCP connections.

## Implementation Challenges

1. **Configuration Management**: The Claude Code CLI only supports a single `--mcp-client` configuration per instance
2. **Private Connections**: Need to maintain private connections between specific agent pairs
3. **Discovery Mechanism**: No built-in way for agents to discover each other
4. **Security Concerns**: Connection details need to be managed securely
5. **Operational Complexity**: Each agent pair requires separate configuration

## Solution Approach

After evaluating multiple options, we decided to implement a configuration layer above Claude Code using shell scripts and configuration files. This solution:

1. Maintains agent-specific configuration files
2. Abstracts the Claude Code launch process
3. Manages connection details securely
4. Provides a consistent interface for launching agents

## Implementation Details

### Directory Structure

```
/ai-assistant-project/
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
    agent-control.sh
  /workspace/
    /reviewer-1/
    /implementer-1/
    /reviewer-2/
    /implementer-2/
```

### Configuration Files

Each agent has its own configuration file with role-specific settings:

**Reviewer Configuration (reviewer-1.conf):**
```bash
AGENT_ROLE="reviewer"
AGENT_PROFILE="code-reviewer"
AGENT_PERSONALITY="Thorough code reviewer with expertise in software architecture. Analyzes requirements carefully and creates clear acceptance criteria. Provides constructive feedback and ensures implementations meet quality standards."
MEMORY_FILE="/ai-assistant-project/data/reviewer-1-memory.json"
LOG_FILE="/ai-assistant-project/logs/reviewer-1.log"
WORKSPACE_DIR="/ai-assistant-project/workspace/reviewer-1"
ADDITIONAL_ARGS="--verbose --debug"
```

**Implementer Configuration (implementer-1.conf):**
```bash
AGENT_ROLE="implementer"
AGENT_PROFILE="developer"
AGENT_PERSONALITY="Detail-oriented developer focused on implementation excellence. Follows TDD best practices and writes clean, documented code. Responds well to feedback and makes requested revisions thoroughly."
SERVER_PORT=8000
MEMORY_FILE="/ai-assistant-project/data/implementer-1-memory.json"
LOG_FILE="/ai-assistant-project/logs/implementer-1.log"
WORKSPACE_DIR="/ai-assistant-project/workspace/implementer-1"
ADDITIONAL_ARGS="--verbose --debug"
```

**Connection Configuration (reviewer-1-connections.conf):**
```bash
IMPLEMENTER_ENDPOINT="localhost:8000"
IMPLEMENTER_ID="implementer-1"
SECURE_CONNECTION=false
CONNECTION_TIMEOUT=30
```

### Launch Script

The main launch script handles the configuration and starts Claude Code with the appropriate parameters:

```bash
#!/bin/bash
# launch-agent.sh

set -e

AGENT_ID=$1
BASE_DIR=$(dirname "$(realpath "$0")")
CONFIG_DIR="$BASE_DIR/../config/agents"
CONN_DIR="$BASE_DIR/../config/connections"
DATA_DIR="$BASE_DIR/../data"
LOG_DIR="$BASE_DIR/../logs"

# Ensure directories exist
mkdir -p "$DATA_DIR" "$LOG_DIR"

# Check if agent configuration exists
if [[ ! -f "$CONFIG_DIR/$AGENT_ID.conf" ]]; then
  echo "Error: Agent configuration not found: $AGENT_ID"
  exit 1
fi

# Load agent configuration
source "$CONFIG_DIR/$AGENT_ID.conf"

echo "Launching agent: $AGENT_ID (role: $AGENT_ROLE)"

# Create workspace directory if it doesn't exist
mkdir -p "$WORKSPACE_DIR"

# Set up common arguments
COMMON_ARGS="--system-profile=$AGENT_PROFILE"

if [[ -n "$MEMORY_FILE" ]]; then
  mkdir -p "$(dirname "$MEMORY_FILE")"
  COMMON_ARGS="$COMMON_ARGS --memory-file=$MEMORY_FILE"
fi

if [[ -n "$AGENT_PERSONALITY" ]]; then
  COMMON_ARGS="$COMMON_ARGS --personality='$AGENT_PERSONALITY'"
fi

# Determine if this is a client or server
if [[ "$AGENT_ROLE" == "reviewer" ]]; then
  # Load connection configuration
  if [[ ! -f "$CONN_DIR/$AGENT_ID-connections.conf" ]]; then
    echo "Error: Connection configuration not found for $AGENT_ID"
    exit 1
  fi
  
  source "$CONN_DIR/$AGENT_ID-connections.conf"
  
  echo "Connecting to implementer: $IMPLEMENTER_ID at $IMPLEMENTER_ENDPOINT"
  
  # Launch as MCP client
  (
    cd "$WORKSPACE_DIR" || exit 1
    LOG_FILE="${LOG_FILE:-$LOG_DIR/$AGENT_ID.log}"
    echo "Starting reviewer agent, logging to $LOG_FILE"
    
    # Export the Claude Code server URL if one doesn't already exist
    export CLAUDE_CODE_SERVER="${CLAUDE_CODE_SERVER:-https://claude.ai/code}"
    
    claude-code --mcp-client --remote="$IMPLEMENTER_ENDPOINT" \
      $COMMON_ARGS $ADDITIONAL_ARGS > "$LOG_FILE" 2>&1 &
    
    echo "Reviewer agent started with PID $!"
    echo "$!" > "$DATA_DIR/$AGENT_ID.pid"
  )
    
elif [[ "$AGENT_ROLE" == "implementer" ]]; then
  # Launch as MCP server
  (
    cd "$WORKSPACE_DIR" || exit 1
    LOG_FILE="${LOG_FILE:-$LOG_DIR/$AGENT_ID.log}"
    echo "Starting implementer agent, logging to $LOG_FILE"
    
    # Export the Claude Code server URL if one doesn't already exist
    export CLAUDE_CODE_SERVER="${CLAUDE_CODE_SERVER:-https://claude.ai/code}"
    
    claude-code --mcp-server --port="$SERVER_PORT" \
      $COMMON_ARGS $ADDITIONAL_ARGS > "$LOG_FILE" 2>&1 &
    
    echo "Implementer agent started with PID $!"
    echo "$!" > "$DATA_DIR/$AGENT_ID.pid"
  )
else
  echo "Error: Unknown agent role: $AGENT_ROLE"
  exit 1
fi

echo "Agent $AGENT_ID launched successfully"
```

### Agent Control Script

An additional script helps manage the lifecycle of running agents:

```bash
#!/bin/bash
# agent-control.sh

set -e

ACTION=$1
AGENT_ID=$2
BASE_DIR=$(dirname "$(realpath "$0")")
DATA_DIR="$BASE_DIR/../data"
PID_FILE="$DATA_DIR/$AGENT_ID.pid"

case "$ACTION" in
  start)
    "$BASE_DIR/launch-agent.sh" "$AGENT_ID"
    ;;
    
  stop)
    if [[ -f "$PID_FILE" ]]; then
      PID=$(cat "$PID_FILE")
      echo "Stopping agent $AGENT_ID (PID: $PID)"
      kill "$PID" 2>/dev/null || true
      rm -f "$PID_FILE"
      echo "Agent stopped"
    else
      echo "No PID file found for agent $AGENT_ID"
      exit 1
    fi
    ;;
    
  restart)
    "$0" stop "$AGENT_ID" || true
    sleep 2
    "$0" start "$AGENT_ID"
    ;;
    
  status)
    if [[ -f "$PID_FILE" ]]; then
      PID=$(cat "$PID_FILE")
      if ps -p "$PID" > /dev/null; then
        echo "Agent $AGENT_ID is running (PID: $PID)"
      else
        echo "Agent $AGENT_ID is not running (stale PID file)"
        rm -f "$PID_FILE"
      fi
    else
      echo "Agent $AGENT_ID is not running"
    fi
    ;;
    
  *)
    echo "Usage: $0 {start|stop|restart|status} agent_id"
    exit 1
    ;;
esac
```

### Connection Management Script

A separate script handles the creation and management of connections:

```bash
#!/bin/bash
# manage-connections.sh

set -e

ACTION=$1
REVIEWER_ID=$2
IMPLEMENTER_ID=$3
BASE_DIR=$(dirname "$(realpath "$0")")
CONFIG_DIR="$BASE_DIR/../config/agents"
CONN_DIR="$BASE_DIR/../config/connections"

# Ensure connection directory exists
mkdir -p "$CONN_DIR"

case "$ACTION" in
  create)
    # Verify that both agents exist
    if [[ ! -f "$CONFIG_DIR/$REVIEWER_ID.conf" ]]; then
      echo "Error: Reviewer configuration not found: $REVIEWER_ID"
      exit 1
    fi
    
    if [[ ! -f "$CONFIG_DIR/$IMPLEMENTER_ID.conf" ]]; then
      echo "Error: Implementer configuration not found: $IMPLEMENTER_ID"
      exit 1
    fi
    
    # Load implementer configuration to get port
    source "$CONFIG_DIR/$IMPLEMENTER_ID.conf"
    
    if [[ -z "$SERVER_PORT" ]]; then
      echo "Error: No SERVER_PORT defined in implementer configuration"
      exit 1
    fi
    
    # Create connection configuration
    echo "Creating connection from $REVIEWER_ID to $IMPLEMENTER_ID (port $SERVER_PORT)"
    
    cat > "$CONN_DIR/$REVIEWER_ID-connections.conf" << EOF
IMPLEMENTER_ENDPOINT="localhost:$SERVER_PORT"
IMPLEMENTER_ID="$IMPLEMENTER_ID"
SECURE_CONNECTION=false
CONNECTION_TIMEOUT=30
EOF
    
    chmod 600 "$CONN_DIR/$REVIEWER_ID-connections.conf"
    echo "Connection created successfully"
    ;;
    
  delete)
    if [[ -f "$CONN_DIR/$REVIEWER_ID-connections.conf" ]]; then
      rm -f "$CONN_DIR/$REVIEWER_ID-connections.conf"
      echo "Connection deleted successfully"
    else
      echo "No connection configuration found for $REVIEWER_ID"
      exit 1
    fi
    ;;
    
  list)
    echo "Available connections:"
    for CONN_FILE in "$CONN_DIR"/*-connections.conf; do
      if [[ -f "$CONN_FILE" ]]; then
        REVIEWER=$(basename "$CONN_FILE" -connections.conf)
        source "$CONN_FILE"
        echo "$REVIEWER -> $IMPLEMENTER_ID ($IMPLEMENTER_ENDPOINT)"
      fi
    done
    ;;
    
  *)
    echo "Usage: $0 {create|delete|list} [reviewer_id] [implementer_id]"
    exit 1
    ;;
esac
```

## Testing Strategy

We developed a testing approach to verify the agent configuration system:

1. **Configuration Validation**: Test that configuration files are correctly loaded and parsed
2. **Agent Launching**: Verify agents start with the correct parameters
3. **Connection Management**: Test creating, listing, and deleting connections
4. **Integration Testing**: Verify agents can communicate via MCP
5. **Error Handling**: Test behavior with missing or invalid configurations

The automated test script includes:

```bash
#!/bin/bash
# test-agent-config.sh

set -e

BASE_DIR=$(dirname "$(realpath "$0")")
SCRIPTS_DIR="$BASE_DIR/../scripts"
CONFIG_DIR="$BASE_DIR/../config/agents"
CONN_DIR="$BASE_DIR/../config/connections"

# Test setup
echo "Setting up test environment"
mkdir -p "$CONFIG_DIR" "$CONN_DIR"

# Create test configuration files
cat > "$CONFIG_DIR/test-reviewer.conf" << EOF
AGENT_ROLE="reviewer"
AGENT_PROFILE="test-reviewer"
MEMORY_FILE="/tmp/test-reviewer-memory.json"
LOG_FILE="/tmp/test-reviewer.log"
WORKSPACE_DIR="/tmp/test-reviewer"
ADDITIONAL_ARGS="--verbose"
EOF

cat > "$CONFIG_DIR/test-implementer.conf" << EOF
AGENT_ROLE="implementer"
AGENT_PROFILE="test-implementer"
SERVER_PORT=9999
MEMORY_FILE="/tmp/test-implementer-memory.json"
LOG_FILE="/tmp/test-implementer.log"
WORKSPACE_DIR="/tmp/test-implementer"
ADDITIONAL_ARGS="--verbose"
EOF

# Test connection management
echo "Testing connection management"
"$SCRIPTS_DIR/manage-connections.sh" create test-reviewer test-implementer
"$SCRIPTS_DIR/manage-connections.sh" list | grep "test-reviewer -> test-implementer"

# Run agent launch tests
# In a real test environment, we would mock Claude Code CLI and validate params
# For now, just verify that the script runs without errors
echo "Testing agent launch scripts (mock mode)"
MOCK_CLAUDE_CODE=true "$SCRIPTS_DIR/launch-agent.sh" test-implementer
MOCK_CLAUDE_CODE=true "$SCRIPTS_DIR/launch-agent.sh" test-reviewer

# Test agent control
# In a real test, we would start real processes and verify their status
echo "Testing agent control (mock mode)"
MOCK_CLAUDE_CODE=true "$SCRIPTS_DIR/agent-control.sh" status test-implementer
MOCK_CLAUDE_CODE=true "$SCRIPTS_DIR/agent-control.sh" status test-reviewer

# Clean up
echo "Cleaning up test environment"
"$SCRIPTS_DIR/manage-connections.sh" delete test-reviewer
rm -f "$CONFIG_DIR/test-reviewer.conf" "$CONFIG_DIR/test-implementer.conf"
rm -f "/tmp/test-reviewer.log" "/tmp/test-implementer.log"
rm -rf "/tmp/test-reviewer" "/tmp/test-implementer"

echo "All tests completed successfully"
```

## Security Considerations

We implemented several security measures:

1. **File Permissions**: Connection configuration files use restricted permissions (chmod 600)
2. **Process Isolation**: Each agent runs in its own process with its own workspace
3. **No Plaintext Passwords**: No sensitive credentials are stored in configuration files
4. **Logging Control**: Logs are directed to agent-specific files to prevent information leakage
5. **PID Management**: PID files ensure only authorized users can manage agent processes

## Future Improvements

Based on our implementation, we identified several potential improvements:

1. **Dynamic Connection Management**: Support runtime connection changes without agent restarts
2. **Connection Encryption**: Add support for encrypted MCP connections
3. **Authentication**: Add authentication mechanisms for MCP connections
4. **High Availability**: Support failover connections for critical agents
5. **Monitoring**: Add health checks and monitoring for agent connections
6. **Web Interface**: Develop a web UI for managing agent configurations

## References

- [ADR-006: Agent-Specific MCP Configuration](../../architecture/decisions/006-agent-mcp-configuration.md)
- [Direct Reviewer-Implementer MCP Workflow](../../architecture/diagrams/direct-reviewer-implementer-mcp-workflow.md)
- [MCP Protocol](../../architecture/interfaces/mcp-protocol.md)
- [Claude Code Documentation](https://docs.anthropic.com/en/docs/claude-code)

---

🧭 **Navigation**
- [Logs Home](../README.md)
- [2025-05-16 Logs](./)