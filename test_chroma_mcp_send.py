#!/usr/bin/env python3
"""
Test script to send a document to Chroma via MCP protocol.
"""

import asyncio
import json
import os
import sys
from typing import Dict, List, Optional

try:
    from mcp import ClientSession
    from mcp.client.streamable_http import streamablehttp_client
except ImportError:
    print("Error: MCP package not found. Please install it with 'pip install mcp'")
    sys.exit(1)

async def send_document_to_chroma():
    # MCP server URL - this is where the Chroma MCP server is listening
    url = "http://localhost:8080/mcp"
    print(f"Connecting to MCP server at {url}...")
    
    try:
        # Connect to the MCP server
        async with streamablehttp_client(url) as (read_stream, write_stream, _):
            print("Connection established.")
            
            # Create an MCP client session
            async with ClientSession(read_stream, write_stream) as session:
                print("Initializing session...")
                await session.initialize()
                print("Session initialized.")
                
                # Get available tools
                tools = await session.get_tools()
                tool_names = [tool.name for tool in tools]
                print(f"Available tools: {', '.join(tool_names)}")
                
                # Try to list collections first
                if "chroma_list_collections" in tool_names:
                    print("\nListing collections...")
                    collections = await session.call_tool("chroma_list_collections")
                    print(f"Collections: {collections}")
                
                # Create a test collection if needed
                if "chroma_create_collection" in tool_names:
                    collection_name = "test_mcp_collection"
                    print(f"\nCreating collection '{collection_name}'...")
                    result = await session.call_tool(
                        "chroma_create_collection", 
                        {"collection_name": collection_name}
                    )
                    print(f"Create collection result: {result}")
                
                # Add a document to the collection
                if "chroma_add_documents" in tool_names:
                    collection_name = "test_mcp_collection"
                    documents = ["This is a test document sent via MCP"]
                    metadatas = [{"source": "mcp_test", "timestamp": "2025-05-20"}]
                    ids = ["mcp_doc_1"]
                    
                    print(f"\nAdding document to collection '{collection_name}'...")
                    result = await session.call_tool(
                        "chroma_add_documents",
                        {
                            "collection_name": collection_name,
                            "documents": documents,
                            "metadatas": metadatas,
                            "ids": ids
                        }
                    )
                    print(f"Add document result: {result}")
                
                # Query the document
                if "chroma_query_documents" in tool_names:
                    collection_name = "test_mcp_collection"
                    query_texts = ["test document"]
                    
                    print(f"\nQuerying collection '{collection_name}'...")
                    result = await session.call_tool(
                        "chroma_query_documents",
                        {
                            "collection_name": collection_name,
                            "query_texts": query_texts,
                            "n_results": 1
                        }
                    )
                    print(f"Query result: {result}")
                
    except Exception as e:
        print(f"Error: {str(e)}")
        return False
    
    return True

if __name__ == "__main__":
    print("Testing Chroma MCP document sending...")
    success = asyncio.run(send_document_to_chroma())
    if success:
        print("\nTest completed successfully!")
    else:
        print("\nTest failed.")
        sys.exit(1)