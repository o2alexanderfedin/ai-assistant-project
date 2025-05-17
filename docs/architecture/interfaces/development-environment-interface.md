# Development Environment Interface

*Last Updated: May 16, 2025*

## 📑 Table of Contents
- [Purpose](#purpose)
- [Interface Definition](#interface-definition)
- [Data Structures](#data-structures)
- [API Methods](#api-methods)
- [Integration Examples](#integration-examples)
- [Error Handling](#error-handling)
- [Security Considerations](#security-considerations)
- [Limitations](#limitations)
- [Future Improvements](#future-improvements)

## Purpose

The Development Environment Interface provides a standardized way for agents and components to create, manage, and use isolated development environments. This interface enables consistent environment management across the multi-agent system, supporting Test-Driven Development workflows and ensuring reproducible environment configurations.

## 🔌 Interface Definition

The Development Environment interface exposes a shell-based API that follows UNIX principles:

1. Each command performs a single, well-defined function
2. Commands can be composed through standard I/O
3. Commands return exit codes to indicate success or failure
4. Complex operations are built from simpler commands

The primary interface is the `dev_env` command-line tool that provides a comprehensive set of subcommands for managing environments.

## 🧱 Data Structures

### Environment Configuration

```json
{
  "name": "string",             // Environment name (required)
  "description": "string",      // Human-readable description (optional)
  "isolation_type": "string",   // "docker", "virtualenv", or "native" (required)
  "extends": "string",          // Parent template name (optional)
  
  "docker": {                   // Docker-specific configuration (required if isolation_type is "docker")
    "image": "string",          // Docker image name (required)
    "ports": ["string"],        // Port mappings (optional)
    "volumes": ["string"],      // Volume mappings (optional)
    "env": {                    // Environment variables (optional)
      "key": "value"
    },
    "init": ["string"]          // Initialization commands (optional)
  },
  
  "virtualenv": {               // Virtualenv-specific configuration (required if isolation_type is "virtualenv")
    "python_version": "string", // Python version to use (required)
    "packages": ["string"],     // Packages to install (optional)
    "env": {                    // Environment variables (optional)
      "key": "value"
    },
    "init": ["string"]          // Initialization commands (optional)
  },
  
  "native": {                   // Native-specific configuration (required if isolation_type is "native")
    "working_dir": "string",    // Working directory (required)
    "env": {                    // Environment variables (optional)
      "key": "value"
    },
    "init": ["string"]          // Initialization commands (optional)
  },
  
  "tools": {                    // Tools to include in the environment (optional)
    "editors": ["string"],      // Text editors (optional)
    "languages": ["string"],    // Programming languages (optional)
    "testing": ["string"],      // Testing frameworks (optional)
    "debugging": ["string"]     // Debugging tools (optional)
  },
  
  "resource_limits": {          // Resource limits (optional)
    "cpu": "string",            // CPU limit (e.g., "1.0")
    "memory": "string",         // Memory limit (e.g., "1024m")
    "disk": "string"            // Disk space limit (e.g., "10g")
  }
}
```

### Environment State

```json
{
  "id": "string",               // Environment ID (required)
  "name": "string",             // Environment name (required)
  "status": "string",           // "running", "stopped", or "error" (required)
  "isolation_type": "string",   // "docker", "virtualenv", or "native" (required)
  "created_at": "string",       // ISO 8601 timestamp (required)
  "last_used": "string",        // ISO 8601 timestamp (required)
  "resource_usage": {           // Resource usage statistics (optional)
    "cpu": "string",            // CPU usage percentage (e.g., "45.2%")
    "memory": "string",         // Memory usage (e.g., "256.5 MB")
    "disk": "string"            // Disk usage (e.g., "1.2 GB")
  },
  "container_id": "string",     // Container ID (if isolation_type is "docker")
  "virtualenv_path": "string",  // Virtualenv path (if isolation_type is "virtualenv")
  "working_dir": "string",      // Working directory (if isolation_type is "native")
  "owner": "string",            // Environment owner (required)
  "tenant": "string"            // Tenant ID (required)
}
```

## 🔧 API Methods

### Environment Management

#### 1. Create Environment

```bash
dev_env create <environment_name> <template_name> [resource_profile]
```

**Parameters:**
- `environment_name`: Unique name for the environment
- `template_name`: Name of the template to use
- `resource_profile`: Optional resource profile to apply (default: "default")

**Returns:** Path to the environment directory

**Example:**
```bash
# Create a new development environment for a developer agent
dev_env create dev-agent-123 developer-agent-environment high-resource
# Returns: /path/to/.dev_env_state/dev-agent-123
```

#### 2. Execute in Environment

```bash
dev_env execute <environment_name> <command>
```

**Parameters:**
- `environment_name`: Name of the environment to use
- `command`: Command to execute in the environment

**Returns:** Command output

**Example:**
```bash
# Run tests in the development environment
dev_env execute dev-agent-123 "cd /workspace && npm test"
```

#### 3. List Environments

```bash
dev_env list [status] [tenant]
```

**Parameters:**
- `status`: Optional filter by status ("running", "stopped", "error")
- `tenant`: Optional filter by tenant ID

**Returns:** JSON array of environment states

**Example:**
```bash
# List all running environments
dev_env list running
```

#### 4. Destroy Environment

```bash
dev_env destroy <environment_name>
```

**Parameters:**
- `environment_name`: Name of the environment to destroy

**Returns:** Success message

**Example:**
```bash
# Destroy an environment when finished
dev_env destroy dev-agent-123
```

### State Management

#### 5. Save Environment State

```bash
dev_env save <environment_name> <checkpoint_name>
```

**Parameters:**
- `environment_name`: Name of the environment to save
- `checkpoint_name`: Name for the checkpoint

**Returns:** Path to the checkpoint file

**Example:**
```bash
# Save environment state before making significant changes
dev_env save dev-agent-123 pre-refactor
```

#### 6. Restore Environment State

```bash
dev_env restore <environment_name> <checkpoint_name>
```

**Parameters:**
- `environment_name`: Name of the environment to restore
- `checkpoint_name`: Name of the checkpoint to restore

**Returns:** Success message

**Example:**
```bash
# Restore environment to previous state
dev_env restore dev-agent-123 pre-refactor
```

### Template Management

#### 7. List Templates

```bash
dev_env template list [category]
```

**Parameters:**
- `category`: Optional filter by template category

**Returns:** JSON array of template information

**Example:**
```bash
# List all developer templates
dev_env template list developer
```

#### 8. Create Template

```bash
dev_env template create <template_name> <template_file>
```

**Parameters:**
- `template_name`: Name for the new template
- `template_file`: Path to JSON template definition

**Returns:** Success message

**Example:**
```bash
# Create a new template from a JSON file
dev_env template create custom-nodejs-template /path/to/template.json
```

### Resource Management

#### 9. Get Resource Usage

```bash
dev_env resources <environment_name>
```

**Parameters:**
- `environment_name`: Name of the environment to query

**Returns:** JSON object with resource usage statistics

**Example:**
```bash
# Get resource usage for an environment
dev_env resources dev-agent-123
```

## 🔄 Integration Examples

### Agent Factory Integration

```bash
# Agent Factory creates a development environment for a new agent
agent_id="developer-agent-42"
template="developer-agent-environment"
resource_profile="standard"

# Create the environment
env_dir=$(dev_env create $agent_id $template $resource_profile)

# Save environment information in agent configuration
agent_config_file="/path/to/agents/$agent_id/config.json"
jq --arg env_dir "$env_dir" '.environment_dir = $env_dir' "$agent_config_file" > tmp.json && mv tmp.json "$agent_config_file"
```

### GitHub Connector Integration

```bash
# Clone repository in a development environment
env_name="dev-agent-123"
repo_url="https://github.com/organization/repository.git"
branch="feature/new-feature"

# Execute git clone in the environment
dev_env execute $env_name "git clone -b $branch $repo_url /workspace/repo"
```

### CI/CD Connector Integration

```bash
# Run tests in a development environment
env_name="dev-agent-123"
test_command="cd /workspace/repo && npm test"

# Execute tests and capture results
test_results=$(dev_env execute $env_name "$test_command")
exit_code=$?

# Report test results to CI/CD system
if [ $exit_code -eq 0 ]; then
  cicd_connector report_test_success "unit-tests" "$test_results"
else
  cicd_connector report_test_failure "unit-tests" "$test_results"
fi
```

## ⚠️ Error Handling

The Development Environment interface follows these error handling principles:

1. **Exit Codes**: All commands return standard UNIX exit codes (0 for success, non-zero for failure)
2. **Error Messages**: Error details are printed to STDERR
3. **Logging**: All operations are logged to a log file
4. **Retries**: Operations include automatic retries for transient failures
5. **Cleanup**: Failed operations include cleanup to prevent resource leaks

### Common Error Scenarios

| Error Code | Description | Resolution |
|------------|-------------|------------|
| 1 | General error | Check error message for details |
| 2 | Environment not found | Verify environment name |
| 3 | Template not found | Verify template name |
| 4 | Resource limits exceeded | Adjust resource profile or clean up unused environments |
| 5 | Docker not available | Install Docker or use alternative isolation type |
| 6 | Command execution failed | Check command syntax and environment state |
| 7 | Checkpoint not found | Verify checkpoint name |
| 8 | Permission denied | Check user permissions |

## 🔒 Security Considerations

1. **Isolation Boundaries**: Environment isolation boundaries must be respected
2. **Credential Management**: Sensitive credentials should not be stored in environment templates
3. **Resource Limits**: Resource limits must be enforced to prevent DoS attacks
4. **Multi-tenancy**: Environments from different tenants must be isolated
5. **Cleanup**: Environments must be properly destroyed after use

## ⚠️ Limitations

1. **Docker Dependency**: Full functionality requires Docker to be installed
2. **Resource Overhead**: Container-based environments have some resource overhead
3. **Network Access**: Default network access may need to be restricted
4. **Filesystem Access**: Filesystem access is limited to specified volumes
5. **Performance**: Environment creation has some latency

## 🚀 Future Improvements

1. **Environment Sharing**: Mechanism for agents to share environments
2. **Environment Snapshots**: Point-in-time snapshots for faster environment restoration
3. **Remote Environments**: Support for remote development environments
4. **Environment Monitoring**: Enhanced monitoring of environment resource usage
5. **Template Registry**: Central repository of optimized environment templates
6. **GUI Interface**: Visual interface for environment management
7. **Cloud Integration**: Support for cloud-based development environments

---

🧭 **Navigation**
- [Architecture Home](../README.md)
- [Interfaces](./README.md)
- [Related Component](../components/development-environment.md)
- [Related ADR](../decisions/004-development-environment-strategy.md)