# 🔄 Chroma MCP Server

## 📑 Table of Contents
- [Overview](#overview)
- [Implementation](#implementation)
- [Configuration](#configuration)
- [Usage with Claude](#usage-with-claude)
- [API Reference](#api-reference)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)

## Overview

The Chroma MCP Server provides an interface for Claude to interact with the Chroma vector database using the Model Context Protocol (MCP). This server allows Claude to perform operations such as creating collections, adding documents, and querying vector embeddings.

## Implementation

The server is implemented as a standalone Python application using FastAPI. It connects to a Chroma database (either local or remote) and exposes MCP-compatible endpoints that Claude can use.

Key components:
- **FastAPI Server**: Handles HTTP requests and responses
- **Chroma Client**: Connects to the Chroma database
- **MCP Protocol Handler**: Processes tool invocations from Claude

## Configuration

The server can be configured using environment variables or command-line arguments:

### Environment Variables

```
CHROMA_CLIENT_TYPE=http     # Type of Chroma client (http, persistent, ephemeral)
CHROMA_HOST=localhost       # Chroma database host
CHROMA_PORT=8100            # Chroma database port
CHROMA_SSL=false            # Whether to use SSL for Chroma connection
MCP_HOST=0.0.0.0            # Host to bind the MCP server to
MCP_PORT=8080               # Port to bind the MCP server to
CHROMA_DATA_DIR=/path/to/data # Data directory for persistent client
```

### Command-Line Arguments

```
--client-type [http|persistent|ephemeral]
--host HOSTNAME             # Chroma database host
--port PORT                 # Chroma database port
--ssl [true|false]          # Whether to use SSL
--data-dir DIRECTORY        # Data directory for persistent client
--mcp-host HOST             # Host to bind the MCP server to
--mcp-port PORT             # Port to bind the MCP server to
```

## Usage with Claude

To use the Chroma MCP server with Claude, follow these steps:

1. Start the Chroma database:
   ```bash
   docker run -p 8100:8000 chromadb/chroma
   ```

2. Start the Chroma MCP server:
   ```bash
   ./start_chroma_mcp.sh
   ```

3. Configure Claude to use the MCP server:
   ```bash
   claude mcp add chroma-local http://localhost:8080
   ```

4. Test the connection:
   ```bash
   claude mcp test chroma-local
   ```

## API Reference

### MCP Endpoint

- **POST /v1/tools**
  - Handles MCP tool invocations from Claude
  - Supported tools:
    - `chroma_list_collections`: Lists all collections
    - `chroma_create_collection`: Creates a new collection
    - `chroma_add_documents`: Adds documents to a collection
    - `chroma_query_documents`: Queries documents in a collection
    - `chroma_health`: Returns the health status of the Chroma database

### HTTP Endpoints

- **GET /health**: Health check endpoint
- **GET /collections**: Lists all collections
- **POST /collections/{name}**: Creates a new collection
- **POST /collections/{name}/add**: Adds documents to a collection
- **POST /collections/{name}/query**: Queries documents in a collection

## Testing

You can test the server using the provided test script:

```bash
python3 test_local_chroma_mcp.py
```

This script tests all the MCP endpoints and verifies that they work correctly.

## Troubleshooting

### Common Issues

1. **Connection Refused**: Make sure the Chroma database is running and accessible.
   ```
   Error: Connection refused
   ```
   Solution: Start the Chroma database or check the host and port.

2. **Collection Not Found**: The requested collection does not exist.
   ```
   Error: Collection 'name' not found
   ```
   Solution: Create the collection first before attempting to query it.

3. **Server Won't Start**: Check for port conflicts.
   ```
   Error: Address already in use
   ```
   Solution: Change the MCP_PORT environment variable or the --mcp-port argument.

### Debugging

To enable more verbose logging, set the logging level to DEBUG:

```python
logging.basicConfig(level=logging.DEBUG)
```

---

🧭 **Navigation**
- [Home](/README.md)
- [Up](../README.md)
- [MCP Protocol](../mcp-protocol.md)

Last updated: May 20, 2025