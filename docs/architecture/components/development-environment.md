# Development Environment Component

*Last Updated: May 16, 2025*

## 📑 Table of Contents
- [Purpose](#purpose)
- [Component Design](#component-design)
- [Key Features](#key-features)
- [Integration Points](#integration-points)
- [Implementation Details](#implementation-details)
- [Configuration](#configuration)
- [Usage Examples](#usage-examples)
- [Security Considerations](#security-considerations)
- [Testing Strategy](#testing-strategy)
- [Future Improvements](#future-improvements)

## Purpose

The Development Environment component provides standardized, reproducible, and isolated development environments for the multi-agent system. It ensures consistent testing and development across agents, maintaining environment parity between development, testing, and production. This component supports the Test-Driven Development workflow by providing isolated environments for running tests and implementing code.

## 🏗️ Component Design

The Development Environment component follows a modular architecture with these core elements:

1. **Environment Manager**: Coordinates environment lifecycle (creation, configuration, destruction)
2. **Environment Templates**: Predefined configurations for different development scenarios
3. **Dependency Manager**: Handles installation and versioning of required dependencies
4. **Isolation System**: Ensures environments are properly isolated using containers or virtual environments
5. **State Persister**: Saves and restores environment state for continuity
6. **Resource Controller**: Manages resource allocation and limits

The component uses a resource-efficient approach, creating environments on-demand and destroying them when no longer needed, while also supporting environment caching for frequently used configurations.

```
┌─────────────────────────────────────────────────────────┐
│                Development Environment                  │
│                                                         │
│  ┌──────────────────┐        ┌─────────────────────┐    │
│  │   Environment    │        │     Dependency      │    │
│  │     Manager      │◄──────►│      Manager        │    │
│  └──────────────────┘        └─────────────────────┘    │
│           ▲                           ▲                 │
│           │                           │                 │
│           ▼                           ▼                 │
│  ┌──────────────────┐        ┌─────────────────────┐    │
│  │   Environment    │        │     Isolation       │    │
│  │    Templates     │◄──────►│      System         │    │
│  └──────────────────┘        └─────────────────────┘    │
│           ▲                           ▲                 │
│           │                           │                 │
│           ▼                           ▼                 │
│  ┌──────────────────┐        ┌─────────────────────┐    │
│  │      State       │        │      Resource       │    │
│  │    Persister     │◄──────►│     Controller      │    │
│  └──────────────────┘        └─────────────────────┘    │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

## 🔑 Key Features

### Environment Templates

- **Standard Environments**: Basic configurations for common development tasks
- **Agent-Specific Environments**: Templates tailored to specific agent roles
- **Testing Environments**: Specialized for Test-Driven Development
- **Integration Environments**: Configured for multi-component testing

### Environment Management

- **On-Demand Creation**: Environments created when needed and destroyed afterward
- **State Persistence**: Save and restore development progress
- **Resource Optimization**: Efficient resource allocation based on task needs
- **Environment Caching**: Reuse environments to avoid recreation costs

### Development Tools

- **Tool Integration**: Standard development tools pre-configured
- **IDE Configuration**: Standard editor configurations for consistent development
- **Debugging Support**: Integrated debugging tools
- **Language/Runtime Support**: Multi-language and runtime version management

### Testing Infrastructure

- **Test Execution Environment**: Isolated environments for running tests
- **Test Data Management**: Generation and management of test data
- **Coverage Analysis**: Tools for analyzing test coverage
- **Performance Testing**: Infrastructure for benchmarking and performance testing

## 🔄 Integration Points

The Development Environment component integrates with:

1. **Agent Factory**: Receives environment specifications when new agents are created
2. **GitHub Connector**: Pulls code and configuration from repositories
3. **CI/CD Connector**: Provides development environments matching CI/CD pipelines
4. **Task History Component**: Records environment configurations used for tasks
5. **Knowledge Base Component**: Stores and retrieves environment configurations
6. **Performance Metrics Component**: Monitors environment resource usage

## 💻 Implementation Details

The Development Environment component is implemented primarily using shell scripts for portability and minimal dependencies, with support for Docker and containerization for isolation.

```bash
#!/bin/bash

# Configuration
CONFIG_DIR="$(pwd)/config/dev_env"
TEMPLATE_DIR="$CONFIG_DIR/templates"
STATE_DIR="$(pwd)/.dev_env_state"
LOG_FILE="$(pwd)/logs/dev_env.log"
DEBUG=${DEV_ENV_DEBUG:-false}

# Initialize environment manager
function init_env_manager() {
  # Create required directories
  mkdir -p "$CONFIG_DIR"
  mkdir -p "$TEMPLATE_DIR"
  mkdir -p "$STATE_DIR"
  mkdir -p "$(dirname "$LOG_FILE")"
  
  log_info "Development Environment Manager initialized"
}

# Create a new development environment from template
function create_environment() {
  local env_name="$1"
  local template_name="$2"
  local resource_profile="${3:-default}"
  
  log_info "Creating environment '$env_name' from template '$template_name'"
  
  # Validate template exists
  if [[ ! -f "$TEMPLATE_DIR/$template_name.json" ]]; then
    log_error "Template '$template_name' not found"
    return 1
  fi
  
  # Create environment directory
  local env_dir="$STATE_DIR/$env_name"
  mkdir -p "$env_dir"
  
  # Load template
  local template_config
  template_config=$(cat "$TEMPLATE_DIR/$template_name.json")
  
  # Apply resource profile
  local resource_config
  resource_config=$(cat "$CONFIG_DIR/resources/$resource_profile.json")
  
  # Generate environment configuration
  jq -s '.[0] * .[1]' <(echo "$template_config") <(echo "$resource_config") > "$env_dir/config.json"
  
  # Create environment based on isolation type
  local isolation_type
  isolation_type=$(echo "$template_config" | jq -r '.isolation_type')
  
  case "$isolation_type" in
    "docker")
      create_docker_environment "$env_name" "$env_dir"
      ;;
    "virtualenv")
      create_virtualenv_environment "$env_name" "$env_dir"
      ;;
    "native")
      create_native_environment "$env_name" "$env_dir"
      ;;
    *)
      log_error "Unsupported isolation type: $isolation_type"
      return 1
      ;;
  esac
  
  log_info "Environment '$env_name' created successfully"
  echo "$env_dir"
}

# Execute command in environment
function execute_in_environment() {
  local env_name="$1"
  local command="$2"
  
  log_info "Executing in environment '$env_name': $command"
  
  # Check if environment exists
  local env_dir="$STATE_DIR/$env_name"
  if [[ ! -d "$env_dir" ]]; then
    log_error "Environment '$env_name' not found"
    return 1
  fi
  
  # Load environment configuration
  local config
  config=$(cat "$env_dir/config.json")
  
  # Determine isolation type and execute accordingly
  local isolation_type
  isolation_type=$(echo "$config" | jq -r '.isolation_type')
  
  case "$isolation_type" in
    "docker")
      execute_in_docker "$env_name" "$command"
      ;;
    "virtualenv")
      execute_in_virtualenv "$env_name" "$command"
      ;;
    "native")
      execute_in_native "$env_name" "$command"
      ;;
    *)
      log_error "Unsupported isolation type: $isolation_type"
      return 1
      ;;
  esac
}

# Create Docker-based environment
function create_docker_environment() {
  local env_name="$1"
  local env_dir="$2"
  
  # Load environment configuration
  local config
  config=$(cat "$env_dir/config.json")
  
  # Extract Docker parameters
  local image
  image=$(echo "$config" | jq -r '.docker.image')
  local port_mappings
  port_mappings=$(echo "$config" | jq -r '.docker.ports | join(" -p ")')
  local volume_mappings
  volume_mappings=$(echo "$config" | jq -r '.docker.volumes | join(" -v ")')
  local env_vars
  env_vars=$(echo "$config" | jq -r '.docker.env | to_entries | map("-e " + .key + "=" + .value) | join(" ")')
  
  # Build Docker run command
  local docker_cmd="docker run --name dev-env-$env_name -d"
  
  # Add port mappings if any
  if [[ -n "$port_mappings" ]]; then
    docker_cmd="$docker_cmd -p $port_mappings"
  fi
  
  # Add volume mappings if any
  if [[ -n "$volume_mappings" ]]; then
    docker_cmd="$docker_cmd -v $volume_mappings"
  fi
  
  # Add environment variables if any
  if [[ -n "$env_vars" ]]; then
    docker_cmd="$docker_cmd $env_vars"
  fi
  
  # Add image and ensure container keeps running
  docker_cmd="$docker_cmd $image tail -f /dev/null"
  
  # Run the container
  eval "$docker_cmd"
  
  # Initialize the environment (install dependencies, etc.)
  local init_commands
  init_commands=$(echo "$config" | jq -r '.docker.init | join(" && ")')
  
  if [[ -n "$init_commands" ]]; then
    docker exec "dev-env-$env_name" bash -c "$init_commands"
  fi
  
  # Save container ID
  docker inspect "dev-env-$env_name" | jq '.[0].Id' > "$env_dir/container_id"
}

# Additional implementation details for other isolation types...

# Destroy environment
function destroy_environment() {
  local env_name="$1"
  
  log_info "Destroying environment '$env_name'"
  
  # Check if environment exists
  local env_dir="$STATE_DIR/$env_name"
  if [[ ! -d "$env_dir" ]]; then
    log_error "Environment '$env_name' not found"
    return 1
  fi
  
  # Load environment configuration
  local config
  config=$(cat "$env_dir/config.json")
  
  # Determine isolation type and cleanup accordingly
  local isolation_type
  isolation_type=$(echo "$config" | jq -r '.isolation_type')
  
  case "$isolation_type" in
    "docker")
      destroy_docker_environment "$env_name" "$env_dir"
      ;;
    "virtualenv")
      destroy_virtualenv_environment "$env_name" "$env_dir"
      ;;
    "native")
      destroy_native_environment "$env_name" "$env_dir"
      ;;
    *)
      log_error "Unsupported isolation type: $isolation_type"
      return 1
      ;;
  esac
  
  # Remove environment directory
  rm -rf "$env_dir"
  
  log_info "Environment '$env_name' destroyed successfully"
}

# Helper functions for logging
function log_info() {
  echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
  if [[ "$DEBUG" == "true" ]]; then
    echo "[INFO] $1" >&2
  fi
}

function log_error() {
  echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
  echo "[ERROR] $1" >&2
}

# Main entry point
function dev_env_main() {
  local command="$1"
  shift
  
  case "$command" in
    "init")
      init_env_manager
      ;;
    "create")
      create_environment "$@"
      ;;
    "execute")
      execute_in_environment "$@"
      ;;
    "destroy")
      destroy_environment "$@"
      ;;
    "list")
      list_environments
      ;;
    "save")
      save_environment_state "$@"
      ;;
    "restore")
      restore_environment_state "$@"
      ;;
    *)
      echo "Unknown command: $command"
      echo "Available commands: init, create, execute, destroy, list, save, restore"
      return 1
      ;;
  esac
}

# If script is executed directly
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  dev_env_main "$@"
fi
```

## ⚙️ Configuration

The Development Environment component is configured using JSON templates:

### Base Environment Template

```json
{
  "name": "base-environment",
  "description": "Base development environment with common tools",
  "isolation_type": "docker",
  "docker": {
    "image": "ubuntu:latest",
    "ports": ["8080:8080"],
    "volumes": ["${PWD}:/workspace"],
    "env": {
      "ENVIRONMENT": "development",
      "DEBUG": "true"
    },
    "init": [
      "apt-get update",
      "apt-get install -y git curl jq build-essential"
    ]
  },
  "native": {
    "working_dir": "${PWD}",
    "env": {
      "ENVIRONMENT": "development",
      "DEBUG": "true"
    },
    "init": [
      "which git >/dev/null || { echo 'git not installed'; exit 1; }",
      "which curl >/dev/null || { echo 'curl not installed'; exit 1; }",
      "which jq >/dev/null || { echo 'jq not installed'; exit 1; }"
    ]
  },
  "resource_limits": {
    "cpu": "1.0",
    "memory": "1024m",
    "disk": "10g"
  }
}
```

### Agent-specific Environment Template

```json
{
  "name": "developer-agent-environment",
  "description": "Environment for Developer Agent tasks",
  "extends": "base-environment",
  "isolation_type": "docker",
  "docker": {
    "image": "node:latest",
    "ports": ["3000:3000", "9229:9229"],
    "volumes": ["${PWD}:/workspace", "${HOME}/.npmrc:/root/.npmrc"],
    "env": {
      "NODE_ENV": "development"
    },
    "init": [
      "npm install -g typescript jest",
      "cd /workspace && npm install"
    ]
  },
  "tools": {
    "editors": ["vim", "nano"],
    "languages": ["javascript", "typescript"],
    "testing": ["jest", "mocha"],
    "debugging": ["node-inspect"]
  },
  "resource_limits": {
    "cpu": "2.0",
    "memory": "2048m",
    "disk": "20g"
  }
}
```

## 🧪 Usage Examples

### Creating a Development Environment

```bash
# Create a new environment for a developer agent
dev_env_main create dev-agent-123 developer-agent-environment high-resource

# Output: /Users/alexanderfedin/Projects/ai-assistant-project/.dev_env_state/dev-agent-123
```

### Running Tests in an Environment

```bash
# Execute tests in the development environment
dev_env_main execute dev-agent-123 "cd /workspace && npm test"
```

### Saving Environment State

```bash
# Save the current state of an environment
dev_env_main save dev-agent-123 checkpoint-1
```

## 🔒 Security Considerations

1. **Isolation Integrity**: Maintains strong boundaries between environments
2. **Credential Management**: Securely handles access credentials for repositories and services
3. **Resource Limits**: Prevents resource exhaustion through strict allocation limits
4. **Dependency Scanning**: Verifies dependencies for vulnerabilities before installation
5. **Ephemeral Environments**: Creates temporary environments to minimize attack surface
6. **Least Privilege Principle**: Environments run with minimal required permissions

## 🧪 Testing Strategy

The Development Environment component is tested using:

1. **Unit Tests**: Testing individual functions for environment creation, execution, and destruction
2. **Integration Tests**: Verifying integration with other components
3. **Resource Tests**: Ensuring proper resource allocation and limits
4. **Isolation Tests**: Verifying environment isolation and security
5. **Performance Tests**: Measuring environment creation and destruction times

## 🚀 Future Improvements

1. **Environment Snapshots**: Point-in-time captures for faster restoration
2. **Environment Sharing**: Mechanisms for agents to collaborate in shared environments
3. **Cloud Environment Support**: Extension to support cloud-based development environments
4. **GUI Integration**: Visual interfaces for environment management
5. **Prebuilt Environment Registry**: Central repository of optimized environment templates
6. **Auto-scaling Resources**: Dynamic resource allocation based on workload
7. **Cross-platform Support**: Enhanced compatibility across different operating systems

---

🧭 **Navigation**
- [Architecture Home](../README.md)
- [Components](./README.md)
- [Related Interface](../interfaces/development-environment-interface.md)
- [Related ADR](../decisions/004-development-environment-strategy.md)
- [Previous: CI/CD Connector](./cicd-connector.md)