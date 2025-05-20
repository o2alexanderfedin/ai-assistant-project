#!/bin/bash
# Script to start the Chroma and Chroma MCP Docker containers

# Check if Docker is running
if ! command -v docker &> /dev/null; then
  echo "❌ Error: Docker is not installed or not in PATH"
  exit 1
fi

# Check if Docker daemon is running
if ! docker info &> /dev/null; then
  echo "❌ Error: Docker daemon is not running. Please start Docker Desktop"
  exit 1
fi

# Check if ports are already in use
PORT_8080=$(lsof -i:8080 -sTCP:LISTEN -t 2>/dev/null)
if [ -n "$PORT_8080" ]; then
  echo "❌ Error: Port 8080 is already in use by process $PORT_8080"
  echo "Please stop the process or choose a different port"
  exit 1
fi

PORT_8100=$(lsof -i:8100 -sTCP:LISTEN -t 2>/dev/null)
if [ -n "$PORT_8100" ]; then
  echo "❌ Error: Port 8100 is already in use by process $PORT_8100"
  echo "Please stop the process or choose a different port"
  exit 1
fi

echo "Starting Chroma database and MCP server in Docker..."
docker compose -f docker-compose.rebuilt.yml up -d

sleep 2  # Wait for containers to initialize

# Check if containers are running
if docker ps | grep -q chroma-mcp && docker ps | grep -q chroma; then
  echo -e "\n✅ Chroma database and MCP server started successfully!"
  echo "- Chroma database running on port 8100"
  echo "- Chroma MCP server running on port 8080"
  echo -e "\nConfigure Claude to use the MCP server:"
  echo "  claude mcp add chroma http://localhost:8080"
else
  echo -e "\n❌ Error: Failed to start containers. Check logs:"
  echo "  docker logs chroma"
  echo "  docker logs chroma-mcp"
fi