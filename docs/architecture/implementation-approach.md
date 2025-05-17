# 🛠️ Implementation Approach

<!-- 📑 TABLE OF CONTENTS -->
- [🛠️ Implementation Approach](#️-implementation-approach)
  - [📋 Overview](#-overview)
  - [🐚 Shell-Based Implementation](#-shell-based-implementation)
  - [📂 Implementation Structure](#-implementation-structure)
  - [🔄 Agent Lifecycle Management](#-agent-lifecycle-management)
  - [🔌 MCP Implementation](#-mcp-implementation)
  - [🧩 Integration Components](#-integration-components)
  - [📝 Configuration Management](#-configuration-management)
  - [🧪 Testing Approach](#-testing-approach)

---

## 📋 Overview

This document outlines the implementation approach for the multi-agent system, emphasizing the use of shell scripts as the primary implementation mechanism rather than Python or other programming languages. This approach favors simplicity, minimizes dependencies, and leverages existing tools to create a robust system.

## 🐚 Shell-Based Implementation

The system will be implemented primarily using shell scripts (bash), with the following principles:

1. **Minimal Dependencies**: Minimize external dependencies beyond standard Unix tools
2. **Simple Orchestration**: Use shell scripts for process management and coordination
3. **Configuration-Driven**: Configuration files drive behavior rather than complex code
4. **Leverage Existing Tools**: Utilize standard Unix tools and Claude Code's built-in capabilities
5. **Composable Components**: Build modular components that can be combined flexibly

### Benefits of Shell-Based Approach

- **Simplicity**: Shell scripts are easier to understand and maintain
- **Portability**: Works across different Unix-like environments
- **Low Overhead**: Minimal resource requirements
- **Direct System Interaction**: Natural integration with system processes
- **Transparency**: Clear visibility into operation and behavior

### Key Technologies

1. **Bash**: Primary scripting language
2. **jq**: JSON processing for configuration and messaging
3. **curl**: Network communication for APIs
4. **netcat/socat**: Socket communication for MCP protocol
5. **systemd/launchd**: Service management (if applicable)
6. **Claude Code CLI**: Direct interaction with Claude models

## 📂 Implementation Structure

The implementation follows this structure:

```
/
├── bin/                    # Executable scripts
│   ├── start-agent.sh      # Agent startup script
│   ├── stop-agent.sh       # Agent shutdown script
│   ├── create-agent.sh     # Agent creation script
│   ├── orchestrator.sh     # Orchestrator logic
│   ├── analyzer.sh         # Analyzer logic
│   └── utils/              # Utility scripts
│       ├── github.sh       # GitHub API utilities
│       ├── mcp.sh          # MCP protocol utilities
│       └── config.sh       # Configuration utilities
├── team/                   # Agent configurations (as previously defined)
├── processes/              # Process definitions (as previously defined)
├── config/                 # System configuration
└── logs/                   # Log files
```

## 🔄 Agent Lifecycle Management

Agent lifecycle is managed through shell scripts:

### Agent Creation

```bash
#!/bin/bash
# create-agent.sh - Creates a new agent based on specifications

# Import utilities
source "$(dirname "$0")/utils/config.sh"

# Parse arguments
AGENT_TYPE="$1"
AGENT_NAME="$2"
AGENT_CATEGORY="$3"
AGENT_SUBCATEGORY="${4:-}"

# Validate arguments
if [[ -z "$AGENT_TYPE" || -z "$AGENT_NAME" || -z "$AGENT_CATEGORY" ]]; then
  echo "Usage: create-agent.sh <agent_type> <agent_name> <category> [subcategory]"
  exit 1
fi

# Determine paths
if [[ -z "$AGENT_SUBCATEGORY" ]]; then
  AGENT_DIR="${TEAM_DIR}/${AGENT_CATEGORY}/${AGENT_TYPE}/${AGENT_NAME}"
else
  AGENT_DIR="${TEAM_DIR}/${AGENT_CATEGORY}/${AGENT_SUBCATEGORY}/${AGENT_TYPE}/${AGENT_NAME}"
fi

# Create agent directory structure
mkdir -p "${AGENT_DIR}/memory"

# Copy base template
TEMPLATE_DIR="${PROCESSES_DIR}/agent-creation/templates/${AGENT_CATEGORY}/${AGENT_TYPE}"
if [[ -d "$TEMPLATE_DIR" ]]; then
  cp -r "${TEMPLATE_DIR}/"* "${AGENT_DIR}/"
else
  echo "Error: Template not found for ${AGENT_TYPE}"
  exit 1
fi

# Generate agent configuration
generate_agent_config "$AGENT_DIR" "$AGENT_TYPE" "$AGENT_NAME"

# Generate agent profile
generate_agent_profile "$AGENT_DIR" "$AGENT_TYPE" "$AGENT_NAME"

echo "Agent created at: ${AGENT_DIR}"
```

### Agent Startup

```bash
#!/bin/bash
# start-agent.sh - Starts an agent

# Import utilities
source "$(dirname "$0")/utils/config.sh"

# Parse arguments
AGENT_PATH="$1"
DEBUG="${2:-false}"

# Validate arguments
if [[ -z "$AGENT_PATH" ]]; then
  echo "Usage: start-agent.sh <agent_path> [debug]"
  exit 1
fi

# Ensure agent path exists
if [[ ! -d "$AGENT_PATH" ]]; then
  echo "Error: Agent directory not found: ${AGENT_PATH}"
  exit 1
fi

# Load agent configuration
if [[ ! -f "${AGENT_PATH}/config.json" ]]; then
  echo "Error: Agent configuration not found"
  exit 1
fi

AGENT_ID=$(jq -r '.agent_id' "${AGENT_PATH}/config.json")
AGENT_NAME=$(jq -r '.name' "${AGENT_PATH}/config.json")
MCP_PORT=$(jq -r '.mcp_server_port' "${AGENT_PATH}/config.json")

# Set debug flags
if [[ "$DEBUG" == "true" ]]; then
  DEBUG_FLAGS="--verbose --debug --mcp-debug"
else
  DEBUG_FLAGS=""
fi

# Start Claude Code instance
CLAUDE_PID=$(claude-code \
  --profile "${AGENT_PATH}/profile.txt" \
  --system-prompt "${AGENT_PATH}/profile.txt" \
  $DEBUG_FLAGS \
  --mcp-server --port $MCP_PORT \
  --working-directory "${AGENT_PATH}/workspace" \
  --name "$AGENT_NAME" \
  > "${LOGS_DIR}/${AGENT_ID}.log" 2>&1 & echo $!)

# Store PID
echo "$CLAUDE_PID" > "${AGENT_PATH}/pid"

echo "Started agent ${AGENT_NAME} on port ${MCP_PORT} (PID: ${CLAUDE_PID})"
```

## 🔌 MCP Implementation

MCP communication is implemented using shell utilities:

```bash
#!/bin/bash
# mcp.sh - MCP protocol utilities

# Send MCP message
# Usage: send_mcp_message <host> <port> <message_json>
send_mcp_message() {
  local HOST="$1"
  local PORT="$2"
  local MESSAGE="$3"
  
  # Send message via curl
  curl -s -X POST "http://${HOST}:${PORT}/mcp" \
    -H "Content-Type: application/json" \
    -d "$MESSAGE"
}

# Create task message
# Usage: create_task_message <source_agent> <target_agent> <task_data>
create_task_message() {
  local SOURCE="$1"
  local TARGET="$2"
  local TASK_DATA="$3"
  
  cat <<EOF
{
  "message_id": "$(uuidgen)",
  "source_agent": "$SOURCE",
  "target_agent": "$TARGET",
  "message_type": "request",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "content": {
    "type": "task",
    "data": $TASK_DATA
  },
  "metadata": {
    "priority": "medium",
    "trace_id": "$(uuidgen)",
    "workflow_stage": "assignment"
  }
}
EOF
}

# Parse MCP response
# Usage: parse_mcp_response <response_json>
parse_mcp_response() {
  local RESPONSE="$1"
  
  # Extract relevant fields using jq
  local MESSAGE_TYPE=$(echo "$RESPONSE" | jq -r '.message_type')
  local CONTENT_TYPE=$(echo "$RESPONSE" | jq -r '.content.type')
  local DATA=$(echo "$RESPONSE" | jq -r '.content.data')
  
  # Return parsed data
  echo "$DATA"
}
```

## 🧩 Integration Components

### GitHub Integration

GitHub integration is implemented via shell scripts:

```bash
#!/bin/bash
# github.sh - GitHub API utilities

# Load GitHub token from environment
GITHUB_TOKEN="${GITHUB_TOKEN:-}"
if [[ -z "$GITHUB_TOKEN" ]]; then
  echo "Error: GITHUB_TOKEN environment variable not set"
  exit 1
fi

# GitHub API base URL
API_BASE="https://api.github.com"

# Create GitHub issue
# Usage: create_github_issue <repo> <title> <body> [labels]
create_github_issue() {
  local REPO="$1"
  local TITLE="$2"
  local BODY="$3"
  local LABELS="${4:-[]}"
  
  curl -s -X POST "${API_BASE}/repos/${REPO}/issues" \
    -H "Authorization: token ${GITHUB_TOKEN}" \
    -H "Accept: application/vnd.github.v3+json" \
    -d @- << EOF
{
  "title": "$TITLE",
  "body": "$BODY",
  "labels": $LABELS
}
EOF
}

# Get GitHub issues
# Usage: get_github_issues <repo> [state] [labels]
get_github_issues() {
  local REPO="$1"
  local STATE="${2:-open}"
  local LABELS="${3:-}"
  
  local QUERY=""
  if [[ -n "$LABELS" ]]; then
    QUERY="?state=${STATE}&labels=${LABELS}"
  else
    QUERY="?state=${STATE}"
  fi
  
  curl -s -X GET "${API_BASE}/repos/${REPO}/issues${QUERY}" \
    -H "Authorization: token ${GITHUB_TOKEN}" \
    -H "Accept: application/vnd.github.v3+json"
}

# Update GitHub issue
# Usage: update_github_issue <repo> <issue_number> <update_json>
update_github_issue() {
  local REPO="$1"
  local ISSUE_NUMBER="$2"
  local UPDATE_JSON="$3"
  
  curl -s -X PATCH "${API_BASE}/repos/${REPO}/issues/${ISSUE_NUMBER}" \
    -H "Authorization: token ${GITHUB_TOKEN}" \
    -H "Accept: application/vnd.github.v3+json" \
    -d "$UPDATE_JSON"
}
```

### Orchestrator Implementation

The Orchestrator is implemented as a shell script service:

```bash
#!/bin/bash
# orchestrator.sh - Main orchestrator service

# Import utilities
source "$(dirname "$0")/utils/config.sh"
source "$(dirname "$0")/utils/github.sh"
source "$(dirname "$0")/utils/mcp.sh"

# Load configuration
REPO=$(jq -r '.github.repo' "${CONFIG_DIR}/system.json")
POLL_INTERVAL=$(jq -r '.orchestrator.poll_interval' "${CONFIG_DIR}/system.json")
ANALYZER_ENDPOINT=$(jq -r '.mcp.client_endpoints.analyzer' "${CONFIG_DIR}/system.json")

# Log startup
log_message "Orchestrator starting"

# Main loop
while true; do
  # Poll for open GitHub issues
  log_message "Polling for issues"
  ISSUES=$(get_github_issues "$REPO" "open")
  
  # Process unassigned issues
  UNASSIGNED_ISSUES=$(echo "$ISSUES" | jq '[.[] | select(.assignees | length == 0)]')
  
  for ISSUE in $(echo "$UNASSIGNED_ISSUES" | jq -c '.[]'); do
    ISSUE_NUMBER=$(echo "$ISSUE" | jq -r '.number')
    ISSUE_TITLE=$(echo "$ISSUE" | jq -r '.title')
    
    log_message "Processing unassigned issue #${ISSUE_NUMBER}: ${ISSUE_TITLE}"
    
    # Create task data
    TASK_DATA=$(create_task_data "$ISSUE")
    
    # Send to analyzer for agent matching
    MESSAGE=$(create_task_message "orchestrator" "analyzer" "$TASK_DATA")
    RESPONSE=$(send_mcp_message "localhost" "$ANALYZER_PORT" "$MESSAGE")
    
    # Extract agent assignment
    AGENT_ID=$(echo "$RESPONSE" | jq -r '.content.data.agent_id')
    
    if [[ "$AGENT_ID" == "null" || -z "$AGENT_ID" ]]; then
      log_message "No suitable agent found for issue #${ISSUE_NUMBER}"
      
      # Create new agent if analyzer suggests it
      NEED_NEW_AGENT=$(echo "$RESPONSE" | jq -r '.content.data.need_new_agent')
      
      if [[ "$NEED_NEW_AGENT" == "true" ]]; then
        AGENT_SPEC=$(echo "$RESPONSE" | jq -r '.content.data.agent_specification')
        log_message "Creating new agent based on specification"
        
        # Call agent creation script
        AGENT_TYPE=$(echo "$AGENT_SPEC" | jq -r '.type')
        AGENT_NAME=$(echo "$AGENT_SPEC" | jq -r '.name')
        AGENT_CATEGORY=$(echo "$AGENT_SPEC" | jq -r '.category')
        AGENT_SUBCATEGORY=$(echo "$AGENT_SPEC" | jq -r '.subcategory')
        
        "${BIN_DIR}/create-agent.sh" "$AGENT_TYPE" "$AGENT_NAME" "$AGENT_CATEGORY" "$AGENT_SUBCATEGORY"
        
        # Start new agent
        AGENT_PATH="${TEAM_DIR}/${AGENT_CATEGORY}/${AGENT_SUBCATEGORY}/${AGENT_TYPE}/${AGENT_NAME}"
        "${BIN_DIR}/start-agent.sh" "$AGENT_PATH" true
        
        # Get agent ID
        AGENT_ID=$(jq -r '.agent_id' "${AGENT_PATH}/config.json")
      else
        # Skip this issue for now
        continue
      fi
    fi
    
    # Assign issue to agent
    log_message "Assigning issue #${ISSUE_NUMBER} to agent ${AGENT_ID}"
    
    # Get agent endpoint
    AGENT_CONFIG=$(find_agent_config "$AGENT_ID")
    AGENT_PORT=$(echo "$AGENT_CONFIG" | jq -r '.mcp_server_port')
    
    # Create task assignment message
    ASSIGNMENT_MESSAGE=$(create_task_message "orchestrator" "$AGENT_ID" "$TASK_DATA")
    
    # Send assignment to agent
    send_mcp_message "localhost" "$AGENT_PORT" "$ASSIGNMENT_MESSAGE"
    
    # Update GitHub issue with assignment
    update_github_issue "$REPO" "$ISSUE_NUMBER" "{\"assignees\": [\"$AGENT_ID\"]}"
  done
  
  # Sleep before next poll
  sleep "$POLL_INTERVAL"
done
```

## 📝 Configuration Management

Configuration is managed through JSON files and environment variables:

```bash
#!/bin/bash
# config.sh - Configuration utilities

# Base directories
export ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export BIN_DIR="${ROOT_DIR}/bin"
export CONFIG_DIR="${ROOT_DIR}/config"
export TEAM_DIR="${ROOT_DIR}/team"
export PROCESSES_DIR="${ROOT_DIR}/processes"
export LOGS_DIR="${ROOT_DIR}/logs"

# Ensure required directories exist
mkdir -p "${LOGS_DIR}"

# Load system configuration
SYSTEM_CONFIG="${CONFIG_DIR}/system.json"
if [[ ! -f "$SYSTEM_CONFIG" ]]; then
  echo "Error: System configuration not found at ${SYSTEM_CONFIG}"
  exit 1
fi

# Find agent configuration by ID
# Usage: find_agent_config <agent_id>
find_agent_config() {
  local AGENT_ID="$1"
  
  # Search for agent configuration
  find "${TEAM_DIR}" -type f -name "config.json" -exec grep -l "\"agent_id\": \"${AGENT_ID}\"" {} \; | head -n 1 | xargs cat
}

# Log message with timestamp
# Usage: log_message <message>
log_message() {
  local MESSAGE="$1"
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $MESSAGE"
}

# Generate agent configuration
# Usage: generate_agent_config <agent_dir> <agent_type> <agent_name>
generate_agent_config() {
  local AGENT_DIR="$1"
  local AGENT_TYPE="$2"
  local AGENT_NAME="$3"
  
  # Generate a unique ID
  local AGENT_ID="${AGENT_TYPE}-$(uuidgen | cut -d'-' -f1)"
  
  # Find next available port
  local BASE_PORT=8100
  local PORT=$BASE_PORT
  while nc -z localhost $PORT 2>/dev/null; do
    PORT=$((PORT + 1))
  done
  
  # Create configuration file
  cat > "${AGENT_DIR}/config.json" << EOF
{
  "agent_id": "${AGENT_ID}",
  "name": "${AGENT_NAME}",
  "type": "${AGENT_TYPE}",
  "model": "claude-3-7-sonnet-20250219",
  "debug_flags": "--verbose --debug --mcp-debug",
  "mcp_server_port": ${PORT},
  "working_directory": "${AGENT_DIR}/workspace"
}
EOF
}
```

## 🧪 Testing Approach

Testing is implemented using shell scripts and standard testing tools:

```bash
#!/bin/bash
# test-agent.sh - Test an agent's capabilities

# Import utilities
source "$(dirname "$0")/utils/config.sh"
source "$(dirname "$0")/utils/mcp.sh"

# Parse arguments
AGENT_PATH="$1"
TEST_TYPE="${2:-basic}"

# Validate arguments
if [[ -z "$AGENT_PATH" ]]; then
  echo "Usage: test-agent.sh <agent_path> [test_type]"
  exit 1
fi

# Ensure agent path exists
if [[ ! -d "$AGENT_PATH" ]]; then
  echo "Error: Agent directory not found: ${AGENT_PATH}"
  exit 1
fi

# Load agent configuration
if [[ ! -f "${AGENT_PATH}/config.json" ]]; then
  echo "Error: Agent configuration not found"
  exit 1
fi

AGENT_ID=$(jq -r '.agent_id' "${AGENT_PATH}/config.json")
MCP_PORT=$(jq -r '.mcp_server_port' "${AGENT_PATH}/config.json")

# Run tests based on test type
case "$TEST_TYPE" in
  "basic")
    echo "Running basic tests for agent ${AGENT_ID}"
    
    # Test MCP connectivity
    echo "Testing MCP connectivity..."
    if nc -z localhost $MCP_PORT; then
      echo "✓ MCP server is running on port ${MCP_PORT}"
    else
      echo "✗ MCP server is not accessible on port ${MCP_PORT}"
      exit 1
    fi
    
    # Test basic echo message
    echo "Testing basic message handling..."
    ECHO_MESSAGE=$(create_echo_message "$AGENT_ID")
    RESPONSE=$(send_mcp_message "localhost" "$MCP_PORT" "$ECHO_MESSAGE")
    
    if [[ -n "$RESPONSE" ]]; then
      echo "✓ Agent responded to echo message"
    else
      echo "✗ Agent failed to respond to echo message"
      exit 1
    fi
    ;;
    
  "capabilities")
    echo "Running capability tests for agent ${AGENT_ID}"
    
    # Load capability tests for agent type
    AGENT_TYPE=$(jq -r '.type' "${AGENT_PATH}/config.json")
    TEST_DIR="${ROOT_DIR}/test/agents/${AGENT_TYPE}"
    
    if [[ ! -d "$TEST_DIR" ]]; then
      echo "No capability tests found for agent type: ${AGENT_TYPE}"
      exit 1
    fi
    
    # Run each capability test
    for TEST_FILE in "${TEST_DIR}"/*.test; do
      TEST_NAME=$(basename "$TEST_FILE" .test)
      echo "Running capability test: ${TEST_NAME}"
      
      # Load test data
      TEST_DATA=$(cat "$TEST_FILE")
      
      # Create test message
      TEST_MESSAGE=$(create_test_message "$AGENT_ID" "$TEST_NAME" "$TEST_DATA")
      
      # Send to agent
      RESPONSE=$(send_mcp_message "localhost" "$MCP_PORT" "$TEST_MESSAGE")
      
      # Evaluate result
      EXPECTED_RESULT=$(jq -r '.expected_result' "$TEST_FILE")
      ACTUAL_RESULT=$(echo "$RESPONSE" | jq -r '.content.data.result')
      
      if [[ "$ACTUAL_RESULT" == "$EXPECTED_RESULT" ]]; then
        echo "✓ Test ${TEST_NAME} passed"
      else
        echo "✗ Test ${TEST_NAME} failed"
        echo "  Expected: ${EXPECTED_RESULT}"
        echo "  Actual: ${ACTUAL_RESULT}"
      fi
    done
    ;;
    
  *)
    echo "Unknown test type: ${TEST_TYPE}"
    echo "Available test types: basic, capabilities"
    exit 1
    ;;
esac

echo "Testing completed for agent ${AGENT_ID}"
```

---

<!-- 🧭 NAVIGATION -->
**Navigation**: [Home](./README.md) | [System Overview](./system-overview.md) | [Directory Structure](./directory-structure.md)

*Last updated: 2024-05-16*