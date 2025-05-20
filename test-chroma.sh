#!/bin/bash
# Script to test the Chroma MCP server in Docker

echo "Testing Chroma MCP server..."

# Test health endpoint
echo -e "\n1. Testing health endpoint..."
curl -s http://localhost:8080/health

# Test MCP list collections
echo -e "\n2. Testing MCP list collections..."
curl -s -X POST -H "Content-Type: application/json" \
     -d '{"name":"chroma_list_collections","parameters":{}}' \
     http://localhost:8080/v1/tools

# Test MCP create collection (if it doesn't exist)
echo -e "\n3. Testing MCP create collection..."
COLLECTIONS=$(curl -s -X POST -H "Content-Type: application/json" \
              -d '{"name":"chroma_list_collections","parameters":{}}' \
              http://localhost:8080/v1/tools)

if [[ "$COLLECTIONS" == *"test_collection"* ]]; then
  echo "Collection 'test_collection' already exists, skipping creation"
else
  curl -s -X POST -H "Content-Type: application/json" \
       -d '{"name":"chroma_create_collection","parameters":{"collection_name":"test_collection"}}' \
       http://localhost:8080/v1/tools
fi

# Test MCP add documents
echo -e "\n4. Testing MCP add documents..."
curl -s -X POST -H "Content-Type: application/json" \
     -d '{"name":"chroma_add_documents","parameters":{"collection_name":"test_collection","documents":["This is a test document for Chroma vector database"],"metadatas":[{"source":"test"}]}}' \
     http://localhost:8080/v1/tools

# Test MCP query documents
echo -e "\n5. Testing MCP query documents..."
curl -s -X POST -H "Content-Type: application/json" \
     -d '{"name":"chroma_query_documents","parameters":{"collection_name":"test_collection","query_texts":["Chroma vector database"],"n_results":1}}' \
     http://localhost:8080/v1/tools

echo -e "\n✅ Test completed. All operations should have received responses from the server."
echo "If any test failed, check if the Docker containers are running:"
echo "  docker ps | grep chroma"