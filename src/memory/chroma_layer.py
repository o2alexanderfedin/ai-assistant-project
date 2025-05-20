"""
ChromaDB Layer

This module represents the bottom layer of our memory system.
It interacts directly with the ChromaDB and stores file references with embeddings.
"""

import os
import logging
from typing import List, Dict, Any, Optional
import chromadb
from chromadb.utils import embedding_functions

logger = logging.getLogger("memory.chroma_layer")

class ChromaLayer:
    """
    Bottom layer that interfaces directly with ChromaDB.
    Only deals with file references and embeddings.
    """
    
    def __init__(
        self,
        collection_name: str = "memory_collection",
        chroma_host: str = "localhost",
        chroma_port: int = 8100,
        use_http: bool = True,
        use_ssl: bool = False,
        embedding_model: Optional[str] = None,
    ):
        """
        Initialize the ChromaDB layer.
        
        Args:
            collection_name: Name of the collection to use
            chroma_host: Hostname of the ChromaDB server
            chroma_port: Port of the ChromaDB server
            use_http: Whether to use HTTP client
            use_ssl: Whether to use SSL for connection
            embedding_model: Optional embedding model name (if None, won't use embedding function)
        """
        self.collection_name = collection_name
        
        # Connect to ChromaDB
        if use_http:
            protocol = "https" if use_ssl else "http"
            self.chroma_client = chromadb.HttpClient(
                host=chroma_host,
                port=chroma_port,
                ssl=use_ssl
            )
            logger.info(f"Connected to ChromaDB via {protocol}://{chroma_host}:{chroma_port}")
        else:
            self.chroma_client = chromadb.EphemeralClient()
            logger.info("Using in-memory ChromaDB client")
        
        # Set up embedding function if model provided
        self.embedding_function = None
        if embedding_model:
            self.embedding_function = embedding_functions.SentenceTransformerEmbeddingFunction(model_name=embedding_model)
            logger.info(f"Using embedding model: {embedding_model}")
        
        # Get or create collection
        self.collection = self.chroma_client.get_or_create_collection(
            name=collection_name,
            embedding_function=self.embedding_function
        )
        logger.info(f"Using collection: {collection_name}")
    
    def store(
        self,
        file_path: str,
        embedding: List[float],
        metadata: Optional[Dict[str, Any]] = None,
        id: Optional[str] = None,
    ) -> str:
        """
        Store a file reference with its embedding in ChromaDB.
        
        Args:
            file_path: Path to the file
            embedding: Pre-computed embedding vector
            metadata: Optional metadata to store
            id: Optional ID for the entry (if None, will use file path hash)
            
        Returns:
            ID of the stored entry
        """
        # Create ID from file path if not provided
        if id is None:
            import hashlib
            id = hashlib.md5(file_path.encode()).hexdigest()
        
        # Prepare metadata
        if metadata is None:
            metadata = {}
        
        # Always store the file path in metadata
        metadata["file_path"] = file_path
        
        try:
            # Store in Chroma
            self.collection.add(
                embeddings=[embedding],
                metadatas=[metadata],
                ids=[id]
            )
            logger.info(f"Stored file reference in ChromaDB: {file_path} (ID: {id})")
            return id
        except Exception as e:
            logger.error(f"Error storing file reference in ChromaDB: {str(e)}")
            raise
    
    def query(
        self,
        embedding: List[float],
        n_results: int = 5,
        include_metadata: bool = True,
        include_distances: bool = True,
    ) -> Dict[str, Any]:
        """
        Query ChromaDB using an embedding vector.
        
        Args:
            embedding: Query embedding vector
            n_results: Number of results to return
            include_metadata: Whether to include metadata in results
            include_distances: Whether to include distances in results
            
        Returns:
            Query results from ChromaDB
        """
        include = ["metadatas"] if include_metadata else []
        if include_distances:
            include.append("distances")
        
        try:
            results = self.collection.query(
                query_embeddings=[embedding],
                n_results=n_results,
                include=include
            )
            
            # Always retrieve file paths
            file_paths = []
            for metadata in results.get("metadatas", [[]])[0]:
                file_paths.append(metadata.get("file_path", "unknown"))
            
            # Add file paths to results for convenience
            results["file_paths"] = file_paths
            
            return results
        except Exception as e:
            logger.error(f"Error querying ChromaDB: {str(e)}")
            raise
    
    def get_by_id(self, id: str) -> Dict[str, Any]:
        """
        Retrieve an entry by its ID.
        
        Args:
            id: ID of the entry to retrieve
            
        Returns:
            Entry data including metadata and embedding
        """
        try:
            result = self.collection.get(
                ids=[id],
                include=["metadatas", "embeddings"]
            )
            
            if not result or not result.get("ids"):
                logger.warning(f"No entry found with ID: {id}")
                return {}
            
            return {
                "id": result["ids"][0],
                "metadata": result["metadatas"][0] if result.get("metadatas") else {},
                "embedding": result["embeddings"][0] if result.get("embeddings") else []
            }
        except Exception as e:
            logger.error(f"Error retrieving entry from ChromaDB: {str(e)}")
            raise
    
    def get_all(self, limit: int = 100) -> List[Dict[str, Any]]:
        """
        Get all entries in the collection.
        
        Args:
            limit: Maximum number of entries to retrieve
            
        Returns:
            List of entries with their metadata
        """
        try:
            result = self.collection.get(
                limit=limit,
                include=["metadatas"]
            )
            
            entries = []
            for i, id in enumerate(result.get("ids", [])):
                metadata = result["metadatas"][i] if result.get("metadatas") else {}
                entries.append({
                    "id": id,
                    "metadata": metadata,
                    "file_path": metadata.get("file_path", "unknown")
                })
            
            return entries
        except Exception as e:
            logger.error(f"Error retrieving all entries from ChromaDB: {str(e)}")
            raise
    
    def count(self) -> int:
        """
        Get the number of entries in the collection.
        
        Returns:
            Count of entries
        """
        return self.collection.count()