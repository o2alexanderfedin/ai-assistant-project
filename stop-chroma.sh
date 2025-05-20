#!/bin/bash
# Script to stop the Chroma and Chroma MCP Docker containers

echo "Stopping Chroma database and MCP server..."
docker compose -f docker-compose.rebuilt.yml down

# Check if containers were stopped
if ! docker ps | grep -q chroma; then
  echo -e "\n✅ Chroma containers stopped successfully"
else
  echo -e "\n❌ Error: Failed to stop containers"
fi