"""
Memory Manager

This module represents the top layer of our memory system.
It converts text to files using hashing and manages the memory storage.
"""

import os
import hashlib
import base64
import logging
from typing import List, Dict, Any, Optional

from .file_layer import FileLayer
from .chroma_layer import ChromaLayer

logger = logging.getLogger("memory.manager")

class MemoryManager:
    """
    Top layer that converts text to files and manages memory storage.
    Handles text input, creates files, and passes to the File Processing layer.
    """
    
    def __init__(
        self,
        memory_dir: str = "./memories",
        file_layer: Optional[FileLayer] = None,
        collection_name: str = "memory_collection",
    ):
        """
        Initialize the memory manager.
        
        Args:
            memory_dir: Directory to store memory files
            file_layer: Optional pre-configured FileLayer instance
            collection_name: Name of the collection (used if file_layer not provided)
        """
        # Create memory directory if it doesn't exist
        self.memory_dir = os.path.abspath(memory_dir)
        os.makedirs(self.memory_dir, exist_ok=True)
        
        # Initialize file layer
        self.file_layer = file_layer or FileLayer(
            chroma_layer=ChromaLayer(collection_name=collection_name)
        )
        
        logger.info(f"Memory manager initialized with directory: {self.memory_dir}")
    
    def _text_to_filename(self, text: str) -> str:
        """
        Convert text to a filename using SHA256 hash and base32 encoding.
        
        Args:
            text: Text to convert
            
        Returns:
            Base32-encoded SHA256 hash of the text
        """
        # Calculate SHA256 hash
        sha256 = hashlib.sha256(text.encode()).digest()
        
        # Convert to base32 for a filename-safe string
        base32 = base64.b32encode(sha256).decode()
        
        # Remove padding characters (=) if any
        base32 = base32.rstrip('=')
        
        # Use a .txt extension
        filename = f"{base32}.txt"
        
        return filename
    
    def store(
        self,
        text: str,
        metadata: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """
        Store text in memory.
        
        Args:
            text: Text to store
            metadata: Optional metadata to associate with the text
            
        Returns:
            Information about the stored memory
        """
        # Convert text to filename
        filename = self._text_to_filename(text)
        file_path = os.path.join(self.memory_dir, filename)
        
        # Store text in file
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(text)
            
        logger.info(f"Stored text in file: {file_path} ({len(text)} characters)")
        
        # Process file and store in ChromaDB
        entry_id = self.file_layer.process_file(
            file_path=file_path,
            id=None,  # Let the system generate an ID
            metadata=metadata
        )
        
        return {
            "id": entry_id,
            "file_path": file_path,
            "filename": filename,
            "chars": len(text)
        }
    
    def retrieve(self, id: str) -> Dict[str, Any]:
        """
        Retrieve a memory by its ID.
        
        Args:
            id: ID of the memory to retrieve
            
        Returns:
            Memory data including content and metadata
        """
        # Get entry from ChromaDB
        entry = self.file_layer.chroma_layer.get_by_id(id)
        
        if not entry:
            logger.warning(f"No memory found with ID: {id}")
            return {}
        
        # Get file path from metadata
        file_path = entry.get("metadata", {}).get("file_path")
        
        if not file_path or not os.path.exists(file_path):
            logger.warning(f"Memory file not found: {file_path}")
            return entry
        
        # Read content from file
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
                
            # Add content to entry
            entry["content"] = content
            
            return entry
        except Exception as e:
            logger.error(f"Error reading memory file: {str(e)}")
            entry["error"] = str(e)
            return entry
    
    def query(
        self,
        query_text: str,
        n_results: int = 5,
        include_content: bool = True
    ) -> Dict[str, Any]:
        """
        Query memories using text.
        
        Args:
            query_text: Text to search for
            n_results: Number of results to return
            include_content: Whether to include memory content in results
            
        Returns:
            Query results including memory data
        """
        return self.file_layer.query(
            query_text=query_text,
            n_results=n_results,
            include_content=include_content
        )
    
    def list_memories(self, limit: int = 100) -> List[Dict[str, Any]]:
        """
        List all stored memories.
        
        Args:
            limit: Maximum number of memories to retrieve
            
        Returns:
            List of memory entries with metadata
        """
        return self.file_layer.chroma_layer.get_all(limit=limit)
    
    def count(self) -> int:
        """
        Get the total number of stored memories.
        
        Returns:
            Count of memories
        """
        return self.file_layer.chroma_layer.count()