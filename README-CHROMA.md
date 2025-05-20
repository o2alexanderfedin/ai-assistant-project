# Chroma Setup for Claude

This document provides instructions for using Chroma with Claude.

## Table of Contents
- [Current Status](#current-status)
- [Connection Information](#connection-information)
- [Setup](#setup)
- [Testing](#testing)
- [Usage with Claude](#usage-with-claude)
- [Available Capabilities](#available-capabilities)
- [Troubleshooting](#troubleshooting)
- [Next Steps](#next-steps)

## Current Status

The Chroma vector database is running as a Docker container with these configurations:
- Container name: chroma
- Host port: 8100
- Internal port: 8000

## Connection Information

### Chroma API

You can interact with the Chroma API directly:
- Endpoint: http://localhost:8100/api/v2

### For Claude Desktop

To use Chroma with Claude Desktop, you need to install the `uv` package manager (which includes `uvx`) and the `chroma-mcp` plugin:

```bash
# Install uv using Homebrew (uvx is included)
brew install uv

# Install chroma-mcp package
pip install chroma-mcp
```

Then update your `.claude/claude_desktop_config.json` file with the following configuration:

```json
{
  "mcpServers": {
    "memory": {
      "command": "uvx",
      "args": ["memory-mcp", "--storage-dir", "${HOME}/mcp_storage/memory"]
    },
    "chroma": {
      "command": "uvx",
      "args": ["chroma-mcp", "--client-type", "http", "--host", "localhost", "--port", "8100", "--ssl", "false"]
    }
  }
}
```

### For Claude Code CLI

To configure Chroma for Claude Code CLI, run:

```bash
claude mcp add chroma uvx -- chroma-mcp --client-type http --host localhost --port 8100 --ssl false
```

## Setup

### Starting the Chroma Server

Use the provided script to start the Chroma server:

```bash
./start-chroma.sh
```

This script will:
- Start the Chroma container using Docker Compose
- Initialize the required collections
- Make the server available on port 8100

### Stopping the Server

To stop the Chroma server:

```bash
./stop-chroma.sh
```

## Testing

To test if the Chroma database is accessible, run:

```bash
python3 test_chroma.py
```

This should return a successful response from the Chroma database.

For a more comprehensive test that adds and queries documents:

```bash
python3 direct_chroma_client.py
```

To test the MCP server connection:

```bash
python3 test_chroma_mcp.py
```

## Usage with Claude

You can use the @chroma prefix to direct queries to the Chroma vector database:

```
@chroma list_collections()
```

Common operations:

```
@chroma create_collection("project_docs")
@chroma add("project_docs", "This is an important document about the architecture.")
@chroma query("project_docs", "Tell me about the architecture")
```

## Available Capabilities

The Chroma MCP integration provides these capabilities:

1. **Collection Management**:
   - Create collections with custom metadata
   - List collections
   - Get collection information

2. **Document Operations**:
   - Add documents with IDs, content, metadata, and embeddings
   - Query documents using semantic search
   - Retrieve documents with their metadata

3. **Vector Search**:
   - Perform semantic searches using embeddings
   - Retrieve documents with similarity scores

## Troubleshooting

Common issues and solutions:

1. **Connection Refused**: 
   - Ensure the Chroma server is running with `docker ps`
   - Check container logs with `docker logs chroma`

2. **API Errors**: 
   - Verify the server is running on the expected port
   - Ensure your API requests match the expected format

3. **Integration Failures**: 
   - Check your Claude settings are correctly configured
   - Verify the MCP server can connect to the Chroma instance

## Next Steps

1. Populate the Chroma database with document embeddings
2. Create collections for different document types
3. Use the @chroma prefix to query your collections

---

🧭 **Navigation**:
[Home](./README.md) | [Architecture Docs](./docs/architecture/README.md)

Last updated: May 20, 2025