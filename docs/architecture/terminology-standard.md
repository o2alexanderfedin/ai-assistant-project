# 📚 Standardized Terminology

This document defines the standard terminology to be used consistently across all architecture documentation.

## 📑 Table of Contents
- [Purpose](#purpose)
- [Agents](#agents)
- [Components](#components)
- [Processes](#processes)
- [Interfaces](#interfaces)
- [Technical Concepts](#technical-concepts)

## 🎯 Purpose

This document serves as the single source of truth for terminology used throughout the architecture documentation. It resolves inconsistencies found during architecture review and provides clear definitions for all key terms.

## 🤖 Agents

| Standard Term | Definition | Deprecated Terms |
|---------------|------------|------------------|
| Orchestrator Agent | The agent responsible for high-level task management, delegation, and coordination between specialized agents. | Task Manager, Controller |
| Analyzer Agent | The agent responsible for analyzing requirements, breaking down tasks, and creating initial plans. | Decomposition Agent, Planner |
| Developer Agent | The agent responsible for implementing code changes based on task requirements. | Implementer Agent, Coder, Engineer |
| Reviewer Agent | The agent responsible for reviewing code changes, suggesting improvements, and ensuring standards compliance. | QA Agent, Evaluator |
| Tester Agent | The agent responsible for writing and executing tests to verify implementations. | Test Engineer, QA Tester |
| Documentation Agent | The agent responsible for creating and maintaining documentation. | Documenter, Technical Writer |
| DevOps Agent | The agent responsible for handling deployment, infrastructure, and CI/CD processes. | Operations Agent, Deployment Agent |

## 🧩 Components

| Standard Term | Definition | Deprecated Terms |
|---------------|------------|------------------|
| Agent Factory | Component responsible for creating and initializing agent instances. | Agent Creator, Agent Generator |
| Agent Registry | Component that maintains a registry of all active agents and their capabilities. | Agent Directory, Agent Catalog |
| Agent State Store | Component that persists agent state across sessions. | Agent Memory, State Manager |
| Communication Hub | Component that facilitates communication between agents using the MCP protocol. | Message Bus, Communication Bus |
| Knowledge Base | Component that provides access to shared knowledge and context. | Information Repository, Wiki |
| Task Queue | Component that manages pending tasks prioritized for execution. | Work Queue, Job Queue |
| Task History | Component that maintains records of completed tasks and their outcomes. | Execution History, Work Log |
| Performance Metrics | Component that collects and analyzes agent performance data. | Analytics, Telemetry |
| Development Environment | Component that provides isolated development environments for agent work. | Dev Environment, Workspace |
| GitHub Connector | Component that interfaces with GitHub for repository operations. | GitHub Integration, Git Connector |
| CI/CD Connector | Component that interfaces with CI/CD systems for build and deployment. | CI/CD Integration, Pipeline Connector |

## 🔄 Processes

| Standard Term | Definition | Deprecated Terms |
|---------------|------------|------------------|
| Agent Creation Process | The process of creating and initializing agent instances. | Agent Instantiation, Agent Bootstrapping |
| Agent Lifecycle | The process that manages agent creation, operation, and retirement. | Agent Management, Agent Operation |
| Agent Task Matching | The process of matching tasks to appropriate agents based on capabilities. | Task Assignment, Capability Matching |
| Agent Task Workflow | The end-to-end process for task execution across multiple agents. | Task Execution Flow, Task Pipeline |
| TDD Workflow | The test-driven development process implemented by agents. | Test-First Development, TDD Cycle |
| Task Execution Process | The process of executing a single task by an agent. | Task Processing, Task Handling |

## 🔌 Interfaces

| Standard Term | Definition | Deprecated Terms |
|---------------|------------|------------------|
| MCP Protocol | The Model Context Protocol used for agent communication. | Agent Communication Protocol, Message Protocol |
| Development Environment Interface | The interface for interacting with development environments. | Workspace API, Environment Interface |
| GitHub Interface | The interface for interacting with GitHub. | GitHub API Client, GitHub Service |

## 🔧 Technical Concepts

| Standard Term | Definition | Deprecated Terms |
|---------------|------------|------------------|
| Human Organizational Model | Architecture modeling approach based on efficient human teams. | Human Team Model, Human Efficiency Model |
| STDIO-based MCP | MCP implementation using standard input/output for communication. | Shell-based MCP, Terminal MCP |

## Last updated: 2025-05-17

---

🧭 **Navigation**
- [Home](/docs/architecture/README.md)
- [System Overview](/docs/architecture/system-overview.md)