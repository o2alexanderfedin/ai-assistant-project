# 🔌 MCP Servers

This directory contains Model Context Protocol (MCP) servers used in our project as git submodules. These servers enable Claude to interact with external data sources and tools.

## 📋 Available MCP Servers

### Simple RAG Implementations

| Server | Description | Original Repository | Status |
|--------|-------------|---------------------|--------|
| memory-mcp | Memory-based MCP server for storing and retrieving documents | [modelcontextprotocol/servers](https://github.com/modelcontextprotocol/servers/tree/main/src/memory) | ✅ Integrated |
| chroma-mcp | Chroma vector store MCP server for advanced document search | [chroma-core/chroma-mcp](https://github.com/chroma-core/chroma-mcp) | ✅ Integrated |

### GraphRAG Implementations

| Server | Description | Original Repository | Status |
|--------|-------------|---------------------|--------|
| *None yet* | - | - | - |

## 🛠️ Using MCP Servers with Claude Desktop

### Memory MCP Server

The Memory MCP server provides a simple document storage and retrieval system with vector search capabilities.

#### Configuration

Add the following to your Claude Desktop configuration file:

```json
{
  "mcpServers": {
    "memory": {
      "command": "uvx",
      "args": ["memory-mcp", "--storage-dir", "/path/to/storage/directory"]
    }
  }
}
```

#### Features

- Document storage and retrieval
- Vector-based semantic search
- Persistent storage option
- Simple interface for Claude integration

#### Command Line Arguments

- `--storage-dir`: Directory for persistent storage (optional)
- `--embedding-model`: Embedding model to use (default: BAAI/bge-small-en-v1.5)
- `--chunk-size`: Maximum chunk size for documents (default: 500)
- `--chunk-overlap`: Overlap between chunks (default: 50)

### Chroma MCP Server

The Chroma MCP server provides integration with the Chroma vector database, enabling advanced document search and retrieval capabilities.

#### Configuration

Add the following to your Claude Desktop configuration file:

```json
{
  "mcpServers": {
    "chroma": {
      "command": "uvx",
      "args": ["chroma-mcp"]
    }
  }
}
```

For connecting to our Docker Compose Chroma instance:

```json
{
  "mcpServers": {
    "chroma": {
      "command": "uvx",
      "args": ["chroma-mcp", "--client-type", "http", "--host", "localhost", "--port", "8100", "--ssl", "false"]
    }
  }
}
```

#### Client Types

The Chroma MCP server supports multiple client types:
- `ephemeral`: In-memory Chroma client (default)
- `persistent`: File-based storage
- `http`: Connect to a Chroma server
- `cloud`: Connect to Chroma Cloud (api.trychroma.com)

#### Environment Variables

You can also configure the Chroma MCP server using environment variables:

```
CHROMA_CLIENT_TYPE="http"
CHROMA_HOST="localhost"
CHROMA_PORT="8100"
CHROMA_SSL="false"
```

#### Features

- Vector search capabilities
- Full-text search
- Metadata filtering
- Multiple embedding options (OpenAI, Cohere, Voyage AI, etc.)
- Integration with existing Chroma database

## 🔄 Updating MCP Servers

To update all MCP server submodules to their latest versions:

```bash
git submodule update --remote
```

To update a specific MCP server:

```bash
git submodule update --remote .claude/mcp-servers/simple-rag/memory-mcp
```

## 🔒 Security Note

Never commit authentication credentials or API keys in MCP server configurations. Use environment variables or secure storage for sensitive information.

---

🧭 **Navigation**
- [Home](/CLAUDE.md)
- [Rules: MCP Server Management](/.claude/rules/mcp-server-management.md)
- [RAG Implementation Analysis](/docs/logs/2025-05-19/rag-implementation-analysis.md)