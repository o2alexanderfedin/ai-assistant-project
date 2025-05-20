# 🧠 Memory MCP Server for Documentation RAG

**Date:** 2025-05-19

## 📋 Table of Contents
- [Overview](#overview)
- [Key Features](#key-features)
- [Architecture](#architecture)
- [Integration with RAG](#integration-with-rag)
- [Configuration](#configuration)
- [Usage Patterns](#usage-patterns)
- [Performance Considerations](#performance-considerations)

## Overview

The Memory MCP server provides a knowledge graph-based persistent memory layer that can significantly enhance our documentation search capabilities. By storing information in an entity-relation format, it enables more sophisticated semantic searches and context retention than basic vector stores alone.

## Key Features

1. **Knowledge Graph Structure**
   - Entities represent core concepts in our documentation
   - Relations define connections between concepts
   - Observations store discrete facts about entities

2. **Persistent Memory**
   - Information is retained between sessions
   - Allows for incremental knowledge building
   - Configurable storage location

3. **Rich Query Capabilities**
   - Full-text search across entities and observations
   - Direct access to named entities
   - Relationship traversal

4. **Simple Integration**
   - Works with Claude Desktop out of the box
   - NPX-based installation
   - Docker container option

## Architecture

The Memory MCP server implements a lightweight knowledge graph with:

```
[Entity] -- relation --> [Entity]
   |
   +-- [Observation 1]
   +-- [Observation 2]
```

### Components

1. **Entities**
   - Named nodes (e.g., "UserStory", "Epic", "TaskWorkflow")
   - Typed categorization (e.g., "component", "process", "artifact")
   - Container for observations

2. **Relations**
   - Directed connections between entities
   - Named relationship types (e.g., "belongs_to", "implements", "references")
   - Structured in active voice

3. **Observations**
   - Atomic facts about entities
   - Text-based for searchability
   - Can be added/removed independently

## Integration with RAG

The Memory MCP server complements our Simple RAG implementation in several ways:

### 1. Knowledge Structure

While vector databases excel at similarity search, they lack explicit relationship modeling. The knowledge graph provides:

- **Explicit relationships**: Direct connections between related documentation components
- **Hierarchical organization**: Clear parent-child relationships (e.g., epics to user stories)
- **Transitive connections**: Find related concepts through relationship chains

### 2. Semantic Enhancement

By integrating with our vector search:

- Use vector search for initial discovery
- Enrich results with knowledge graph relationships
- Follow connections to related documentation

### 3. Implementation Approach

```
┌───────────────┐    ┌───────────────┐    ┌───────────────┐
│               │    │               │    │               │
│  Document     │───▶│  Vector DB    │───▶│  LLM Response │
│  Processor    │    │  (Chroma)     │    │               │
│               │    │               │    │               │
└───────┬───────┘    └───────────────┘    └───────▲───────┘
        │                                         │
        │            ┌───────────────┐            │
        │            │               │            │
        └───────────▶│  Knowledge    │────────────┘
                     │  Graph Memory │
                     │               │
                     └───────────────┘
```

In this architecture:
1. Documents are processed into both vector embeddings and knowledge graph entities
2. Queries retrieve relevant content from both systems
3. Results are combined to provide richer, more contextual responses

## Configuration

### Claude Desktop Configuration

```json
{
  "mcpServers": {
    "memory": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-memory"
      ],
      "env": {
        "MEMORY_FILE_PATH": "/path/to/docs/memory.json"
      }
    }
  }
}
```

### Custom Prompting

To effectively utilize the memory server for documentation search, use a prompt similar to:

```
Follow these steps when searching for information in our documentation:

1. Document Context:
   - Retrieve relevant documentation from both vector search and your knowledge graph memory
   - Consider relationships between components, processes, and artifacts
   - Follow connections to related concepts when appropriate

2. Memory Management:
   - When finding important relationships between concepts in our documentation, add them to your memory
   - Create entities for key components, processes, and artifacts
   - Connect related concepts with explicit relation types
   - Store important facts as observations on the entities

3. Navigation Enhancement:
   - Use memory to provide navigation suggestions between related documentation
   - Highlight parent-child relationships (like epics to user stories)
   - Suggest related concepts based on graph connections
```

## Usage Patterns

### 1. Documentation Mapping

Create a knowledge graph of our documentation structure:

```javascript
// Example: Creating core documentation entities
await createEntities([
  {
    name: "Epic",
    entityType: "concept",
    observations: ["High-level initiative containing multiple user stories"]
  },
  {
    name: "UserStory",
    entityType: "concept",
    observations: ["Implementable feature that relates to an epic"]
  }
]);

// Example: Creating relationships
await createRelations([
  {
    from: "UserStory",
    to: "Epic",
    relationType: "belongs_to"
  }
]);
```

### 2. Document Navigation

When a user searches for information about "user stories," Claude can use the knowledge graph to:

1. Find the "UserStory" entity
2. Discover its relationship to "Epic"
3. Follow other relationships to find related concepts
4. Provide comprehensive information with proper context

### 3. Incremental Knowledge Building

As Claude processes more documentation:

1. New entities are added for key concepts
2. Additional relationships are established
3. Observations are enriched with new information
4. The knowledge graph continuously improves

## Performance Considerations

1. **Storage Requirements**
   - Knowledge graph data is compact (JSON-based)
   - Minimal disk space compared to vector databases
   - Acceptable memory footprint during operation

2. **Query Performance**
   - Fast direct entity lookup by name (O(1))
   - Efficient relationship traversal
   - Search operations scale with graph size

3. **Scaling Approach**
   - For documentation under 10,000 pages: single instance is sufficient
   - For larger documentation sets: consider partitioning by domain

4. **Limitations**
   - Not optimized for full-text search of document content
   - Requires explicit relationship modeling
   - Best used in conjunction with vector search

---

🧭 **Navigation**
- [Home](/docs/README.md)
- [Architecture](/docs/architecture/README.md)
- [Interfaces](/docs/architecture/interfaces/README.md)
- [RAG Implementation Analysis](/docs/logs/2025-05-19/rag-implementation-analysis.md)
- [MCP Server Management](/.claude/rules/mcp-server-management.md)