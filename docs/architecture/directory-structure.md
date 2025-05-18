# 📁 System Directory Structure

<!-- 📑 TABLE OF CONTENTS -->
- [📁 System Directory Structure](#-system-directory-structure)
  - [📋 Overview](#-overview)
  - [📂 Root Directory Layout](#-root-directory-layout)
  - [🤖 Agent Directory Structure](#-agent-directory-structure)
  - [🔄 Process Directory Structure](#-process-directory-structure)
  - [🛠️ Configuration Management](#️-configuration-management)
  - [🧪 Testing Directory Structure](#-testing-directory-structure)
  - [📊 Directory Conventions](#-directory-conventions)

---

## 📋 Overview

This document defines the directory structure for the multi-agent system, focusing on organizing agent configurations, processes, and related artifacts in a consistent, maintainable way. The structure follows SOLID, KISS, and DRY principles, ensuring that each agent and process has a single responsibility and is organized logically.

## 📂 Root Directory Layout

The root directory of the system is organized as follows:

```
/
├── team/                   # Agent configurations and profiles
├── processes/              # Process definitions and templates
├── tools/                  # Shared tools and utilities
├── docs/                   # Documentation
│   ├── architecture/       # Architecture documentation
│   ├── logs/               # Session logs
│   └── api/                # API documentation
├── config/                 # System-wide configuration
├── test/                   # Test cases and test data
└── CLAUDE.md               # System instructions and rules
```

## 🤖 Agent Directory Structure

Agent configurations are organized in a hierarchical structure under the `team` directory:

```
team/
├── development/            # Development-focused agents
│   ├── frontend/           # Frontend development agents
│   │   ├── react/          # React specialists
│   │   │   ├── react-dev-1/  # Specific agent instance
│   │   │   │   ├── config.json     # Agent configuration
│   │   │   │   ├── profile.txt     # System prompt
│   │   │   │   ├── capabilities.json  # Capability definition
│   │   │   │   └── memory/       # Agent memory files
│   │   │   └── ...
│   │   ├── vue/            # Vue specialists
│   │   └── ui/             # Generic UI developers
│   ├── backend/            # Backend development agents
│   │   ├── nodejs/         # Node.js specialists
│   │   ├── python/         # Python specialists
│   │   └── java/           # Java specialists
│   └── fullstack/          # Full-stack developers
├── testing/                # Testing-focused agents
│   ├── unit/               # Unit testing specialists
│   ├── integration/        # Integration testing specialists
│   ├── e2e/                # End-to-end testing specialists
│   └── security/           # Security testing specialists
├── review/                 # Review-focused agents
│   ├── code-reviewer/      # Code review specialists
│   ├── architecture-reviewer/  # Architecture review specialists
│   └── performance-reviewer/  # Performance review specialists
├── documentation/          # Documentation-focused agents
│   ├── technical-writer/   # Technical writing specialists
│   ├── api-documenter/     # API documentation specialists
│   └── user-guide-writer/  # User guide specialists
├── devops/                 # DevOps-focused agents
│   ├── ci-cd/              # CI/CD specialists
│   ├── infrastructure/     # Infrastructure specialists
│   └── monitoring/         # Monitoring specialists
├── coordination/           # Coordination agents
│   ├── orchestrator/       # Task orchestration agents
│   ├── analyzer/           # Task analysis agents
│   └── agent-factory/      # Agent creation specialists
└── domain-specific/        # Domain-specific agents
    ├── finance/            # Finance domain specialists
    ├── healthcare/         # Healthcare domain specialists
    └── ecommerce/          # E-commerce domain specialists
```

### Agent Configuration Files

Each agent directory contains:

1. **config.json**: Base configuration for the Claude Code instance
   ```json
   {
     "agent_id": "react-dev-1",
     "name": "React Developer 1",
     "model": "claude-3-7-sonnet-20250219",
     "debug_flags": "--verbose --debug --mcp-debug",
     "mcp_server_port": 8101,
     "working_directory": "/workspace/team/development/frontend/react/react-dev-1"
   }
   ```

2. **profile.txt**: The system prompt defining the agent's role and persona
   ```
   # React Frontend Developer

   ## Role Definition
   You are a specialized React frontend developer responsible for implementing 
   UI components and frontend functionality. Your expertise is in React, JavaScript, 
   CSS, and frontend architecture.

   ## Capabilities
   - Create and modify React components
   - Implement responsive UI designs
   - Optimize frontend performance
   - Follow Test-Driven Development
   - ...
   ```

3. **capabilities.json**: Detailed capability definitions
   ```json
   {
     "technical_skills": {
       "react": 0.9,
       "javascript": 0.8,
       "css": 0.7,
       "html": 0.8,
       "typescript": 0.6
     },
     "development_activities": [
       "implementation",
       "bugfixing",
       "testing",
       "review"
     ],
     "domains": [
       "ui_components",
       "state_management",
       "api_integration"
     ]
   }
   ```

4. **memory/**: Directory for agent memory files and persistent state

## 🔄 Process Directory Structure

Process definitions are organized in a hierarchical structure under the `processes` directory:

```
processes/
├── task-execution/          # Task execution processes
│   ├── default/             # Default execution process
│   │   ├── process.json     # Process definition
│   │   ├── workflow.md      # Process documentation
│   │   └── templates/       # Process templates
│   ├── development/         # Development-specific processes
│   │   ├── frontend/        # Frontend development processes
│   │   ├── backend/         # Backend development processes
│   │   └── fullstack/       # Full-stack development processes
│   ├── testing/             # Testing-specific processes
│   └── documentation/       # Documentation-specific processes
├── tdd/                     # TDD workflow processes
│   ├── default/             # Default TDD process
│   ├── frontend/            # Frontend TDD adaptations
│   ├── backend/             # Backend TDD adaptations
│   └── domain-specific/     # Domain-specific TDD adaptations
├── review/                  # Review processes
│   ├── code-review/         # Code review processes
│   ├── design-review/       # Design review processes
│   └── architecture-review/ # Architecture review processes
├── agent-creation/          # Agent creation processes
│   ├── templates/           # Agent templates
│   │   ├── development/     # Development agent templates
│   │   ├── testing/         # Testing agent templates
│   │   └── ...
│   ├── validation/          # Validation processes
│   └── deployment/          # Deployment processes
└── orchestration/           # Orchestration processes
    ├── task-matching/       # Task matching processes
    ├── load-balancing/      # Load balancing processes
    └── escalation/          # Escalation processes
```

### Process Definition Files

Each process directory contains:

1. **process.json**: Process definition and configuration
   ```json
   {
     "process_id": "frontend-tdd",
     "name": "Frontend TDD Process",
     "version": "1.0.0",
     "description": "Test-Driven Development process adapted for frontend development",
     "applicable_agents": ["development/frontend/*"],
     "applicable_tasks": ["implementation", "bugfix"],
     "phases": [
       {
         "name": "test-creation",
         "required": true,
         "templates": ["test-templates/react-component.js"]
       },
       {
         "name": "implementation",
         "required": true,
         "follows": "test-creation"
       },
       {
         "name": "refactoring",
         "required": true,
         "follows": "implementation"
       }
     ]
   }
   ```

2. **workflow.md**: Detailed process documentation
   ```markdown
   # Frontend TDD Process

   ## Overview
   This process defines the Test-Driven Development workflow for frontend tasks.

   ## Phases

   ### 1. Test Creation
   - Create component test file
   - Define expected rendering
   - Define expected behavior
   - Verify test fails

   ### 2. Implementation
   ...
   ```

3. **templates/**: Directory containing templates for different process phases

## 🛠️ Configuration Management

Configuration management follows these principles:

1. **Inheritance**: Configurations can inherit from parent directories
   ```
   team/development/config.json        # Base config for all development agents
   team/development/frontend/config.json  # Frontend-specific overrides
   team/development/frontend/react/config.json  # React-specific overrides
   ```

2. **Variables**: Configuration files can use variables
   ```json
   {
     "base_url": "${SYSTEM_BASE_URL}",
     "log_dir": "${LOG_ROOT}/team/development/frontend/react"
   }
   ```

3. **Environment-Specific**: Different environments can have different configurations
   ```
   config/
   ├── development/
   │   └── env.json
   ├── staging/
   │   └── env.json
   └── production/
       └── env.json
   ```

## 🧪 Testing Directory Structure

The testing structure mirrors the agent and process structures:

```
test/
├── agents/                   # Agent tests
│   ├── development/          # Tests for development agents
│   │   ├── frontend/         # Tests for frontend agents
│   │   └── ...
│   └── ...
├── processes/                # Process tests
│   ├── task-execution/       # Tests for task execution processes
│   ├── tdd/                  # Tests for TDD processes
│   └── ...
├── integration/              # Integration tests
│   ├── agent-communication/  # Tests for agent communication
│   ├── github-integration/   # Tests for GitHub integration
│   └── ...
└── system/                   # System-level tests
    ├── end-to-end/           # End-to-end tests
    └── performance/          # Performance tests
```

## 📊 Directory Conventions

The system follows these directory conventions:

1. **Naming Conventions**:
   - Use kebab-case for directory and file names
   - Use descriptive, purpose-indicating names
   - Follow a consistent naming pattern within categories

2. **Directory Structure Principles**:
   - **Single Responsibility**: Each directory has a clear, single purpose
   - **Open/Closed**: Structure allows extension without modification
   - **Liskov Substitution**: Subtypes should be interchangeable
   - **Interface Segregation**: Avoid forcing dependencies on unused files
   - **Dependency Inversion**: High-level modules don't depend on low-level ones

3. **File Organization**:
   - Group related files together
   - Keep directory depth reasonable (max 5-6 levels)
   - Maintain balance between breadth and depth
   - Use README.md files to explain directory purpose

4. **Path References**:
   - Use relative paths for cross-references within the same module
   - Use absolute paths for references across different modules
   - Document path reference patterns in code

---

<!-- 🧭 NAVIGATION -->
**Navigation**: [Home](./README.md) | [System Overview](./system-overview.md) | [Component Index](./components/README.md)

*Last updated: 2025-05-16*