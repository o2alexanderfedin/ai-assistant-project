"""
File Processing Layer

This module represents the middle layer of our memory system.
It processes files, generates embeddings, and passes file references to the ChromaDB layer.
"""

import os
import logging
from typing import List, Dict, Any, Optional, Tuple

from .chroma_layer import ChromaLayer

logger = logging.getLogger("memory.file_layer")

class FileLayer:
    """
    Middle layer that processes files and generates embeddings.
    Gets file paths, reads content, generates embeddings, and passes to ChromaDB.
    """
    
    def __init__(
        self,
        chroma_layer: Optional[ChromaLayer] = None,
        collection_name: str = "memory_collection",
    ):
        """
        Initialize the file processing layer.
        
        Args:
            chroma_layer: Optional pre-configured ChromaLayer instance
            collection_name: Name of the collection (used if chroma_layer not provided)
        """
        self.chroma_layer = chroma_layer or ChromaLayer(collection_name=collection_name)
        logger.info("File layer initialized")
    
    def generate_embedding(self, content: str) -> List[float]:
        """
        Generate an embedding for the given content.
        
        Args:
            content: Text content to generate embedding for
            
        Returns:
            Embedding vector as a list of floats
        """
        # STUB: This is a placeholder for actual embedding generation
        # In a real implementation, this would use a proper embedding model
        import hashlib
        import random
        
        # Use a hash of the content to seed a random generator for reproducibility
        content_hash = hashlib.md5(content.encode()).digest()
        seed = int.from_bytes(content_hash[:4], byteorder='big')
        random.seed(seed)
        
        # Generate a 384-dimensional embedding (common for models like all-MiniLM-L6-v2)
        embedding_size = 384
        embedding = [random.uniform(-1, 1) for _ in range(embedding_size)]
        
        # Normalize the embedding to unit length
        norm = sum(x*x for x in embedding) ** 0.5
        if norm > 0:
            embedding = [x/norm for x in embedding]
        
        logger.info(f"Generated stub embedding of size {len(embedding)}")
        return embedding
    
    def process_file(
        self,
        file_path: str,
        id: Optional[str] = None,
        metadata: Optional[Dict[str, Any]] = None
    ) -> str:
        """
        Process a file, generate embedding, and store in ChromaDB.
        
        Args:
            file_path: Path to the file to process
            id: Optional ID for the ChromaDB entry
            metadata: Optional metadata to store with the entry
            
        Returns:
            ID of the stored entry
        """
        try:
            # Verify file exists
            if not os.path.exists(file_path):
                raise FileNotFoundError(f"File not found: {file_path}")
            
            # Read file content
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
                
            logger.info(f"Read content from file: {file_path} ({len(content)} characters)")
            
            # Generate embedding
            embedding = self.generate_embedding(content)
            
            # Prepare metadata
            if metadata is None:
                metadata = {}
                
            # Add file metadata
            file_stats = os.stat(file_path)
            metadata.update({
                "file_size": file_stats.st_size,
                "last_modified": file_stats.st_mtime,
                "file_name": os.path.basename(file_path),
                "chars": len(content)
            })
            
            # Store in ChromaDB layer
            entry_id = self.chroma_layer.store(
                file_path=file_path,
                embedding=embedding,
                metadata=metadata,
                id=id
            )
            
            return entry_id
            
        except Exception as e:
            logger.error(f"Error processing file {file_path}: {str(e)}")
            raise
    
    def query(
        self,
        query_text: str,
        n_results: int = 5,
        include_content: bool = False
    ) -> Dict[str, Any]:
        """
        Query the system using text.
        
        Args:
            query_text: Text to search for
            n_results: Number of results to return
            include_content: Whether to include file content in results
            
        Returns:
            Query results including file paths and optionally content
        """
        # Generate embedding for query
        embedding = self.generate_embedding(query_text)
        
        # Query ChromaDB layer
        results = self.chroma_layer.query(
            embedding=embedding,
            n_results=n_results,
            include_metadata=True,
            include_distances=True
        )
        
        # Optionally load content
        if include_content:
            contents = []
            for file_path in results.get("file_paths", []):
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        contents.append(f.read())
                except Exception as e:
                    logger.error(f"Error reading file {file_path}: {str(e)}")
                    contents.append(f"[Error reading file: {str(e)}]")
            
            results["contents"] = contents
        
        return results