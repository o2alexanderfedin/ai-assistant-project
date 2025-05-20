#!/usr/bin/env python3
"""
Memory System Example

Demonstrates the usage of the layered memory system.
"""

import os
import logging
import argparse
import json
from typing import Dict, Any

from memory_manager import MemoryManager

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger("memory.example")

def store_text(memory_manager: MemoryManager, text: str, metadata: Dict[str, Any] = None) -> Dict[str, Any]:
    """Store text in memory and return details."""
    result = memory_manager.store(text=text, metadata=metadata)
    logger.info(f"Stored text with ID: {result['id']}")
    logger.info(f"File path: {result['file_path']}")
    return result

def query_memories(memory_manager: MemoryManager, query: str, n_results: int = 3) -> Dict[str, Any]:
    """Query memories and return results."""
    results = memory_manager.query(query_text=query, n_results=n_results, include_content=True)
    logger.info(f"Found {len(results.get('file_paths', []))} results for query: {query}")
    return results

def display_results(results: Dict[str, Any]) -> None:
    """Display search results in a readable format."""
    file_paths = results.get("file_paths", [])
    contents = results.get("contents", [])
    distances = results.get("distances", [[]])[0] if "distances" in results else []
    
    if not file_paths:
        print("No results found.")
        return
    
    print("\n=== Search Results ===\n")
    
    for i, (file_path, distance) in enumerate(zip(file_paths, distances)):
        content = contents[i] if i < len(contents) else "[Content not available]"
        
        print(f"Result #{i+1}")
        print(f"File: {os.path.basename(file_path)}")
        print(f"Relevance: {1.0 - distance:.4f}" if distance else "Relevance: N/A")
        print("\nContent:")
        print("-" * 40)
        # Print first 200 chars of content with ellipsis if longer
        if len(content) > 200:
            print(f"{content[:200]}...\n")
        else:
            print(f"{content}\n")
        print("-" * 40)
        print()

def main():
    parser = argparse.ArgumentParser(description="Memory System Example")
    parser.add_argument("--store", type=str, help="Text to store in memory")
    parser.add_argument("--query", type=str, help="Query to search memories")
    parser.add_argument("--list", action="store_true", help="List all memories")
    parser.add_argument("--memory-dir", type=str, default="./memories", help="Directory for memory files")
    parser.add_argument("--collection", type=str, default="memory_collection", help="ChromaDB collection name")
    
    args = parser.parse_args()
    
    if not (args.store or args.query or args.list):
        parser.print_help()
        return
    
    # Initialize memory manager
    memory_manager = MemoryManager(
        memory_dir=args.memory_dir,
        collection_name=args.collection
    )
    
    # Store text if provided
    if args.store:
        result = store_text(
            memory_manager=memory_manager,
            text=args.store,
            metadata={"source": "example.py", "type": "text"}
        )
        print(f"Stored text with ID: {result['id']}")
        print(f"File: {os.path.basename(result['file_path'])}")
    
    # Query memories if provided
    if args.query:
        results = query_memories(
            memory_manager=memory_manager,
            query=args.query
        )
        display_results(results)
    
    # List all memories if requested
    if args.list:
        memories = memory_manager.list_memories()
        count = memory_manager.count()
        
        print(f"\n=== All Memories ({count} total) ===\n")
        
        for i, memory in enumerate(memories):
            print(f"Memory #{i+1}")
            print(f"ID: {memory['id']}")
            print(f"File: {os.path.basename(memory['file_path'])}")
            print(f"Metadata: {json.dumps(memory['metadata'], indent=2)}")
            print()

if __name__ == "__main__":
    main()