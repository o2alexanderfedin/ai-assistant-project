"""
Chroma Integration for Question-Based Embedding

This module provides functions to integrate the question-based embedding approach
with Chroma vector database through MCP protocol.
"""

import os
import json
import time
from typing import List, Dict, Any, Optional, Tuple
import requests
import logging

from .transformer import EmbeddingGenerator
from .question_generator import QuestionGenerator, QueryTransformer, QuestionItem

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger("chroma_qbe")

class ChromaQBEClient:
    """Client for Chroma Question-Based Embedding integration."""
    
    def __init__(
        self,
        chroma_host: str = "localhost",
        chroma_port: int = 8100,
        use_ssl: bool = False,
        embedding_model: str = "all-MiniLM-L6-v2",
        openai_api_key: Optional[str] = None
    ):
        """Initialize the Chroma QBE Client.
        
        Args:
            chroma_host: Hostname of the Chroma server
            chroma_port: Port of the Chroma server
            use_ssl: Whether to use SSL for connection
            embedding_model: Name of the sentence-transformer model to use
            openai_api_key: OpenAI API key for question generation (if None, uses env var)
        """
        self.protocol = "https" if use_ssl else "http"
        self.chroma_host = chroma_host
        self.chroma_port = chroma_port
        self.base_url = f"{self.protocol}://{self.chroma_host}:{self.chroma_port}/api/v2"
        
        # Initialize components
        self.openai_api_key = openai_api_key or os.environ.get("OPENAI_API_KEY")
        if not self.openai_api_key:
            logger.warning("No OpenAI API key provided - question generation will not work")
            
        self.embedding_generator = EmbeddingGenerator(model_name=embedding_model)
        
        try:
            self.question_generator = QuestionGenerator(api_key=self.openai_api_key)
            self.query_transformer = QueryTransformer(api_key=self.openai_api_key)
            logger.info(f"Initialized Chroma QBE Client with {embedding_model}")
        except Exception as e:
            logger.error(f"Failed to initialize question components: {str(e)}")
            raise
    
    def check_connection(self) -> bool:
        """Check if connection to Chroma is working.
        
        Returns:
            True if connection is successful, False otherwise
        """
        try:
            response = requests.get(f"{self.base_url}/heartbeat")
            return response.status_code == 200
        except Exception as e:
            logger.error(f"Connection error: {str(e)}")
            return False
            
    def list_collections(self) -> List[str]:
        """List all collections in Chroma.
        
        Returns:
            List of collection names
        """
        try:
            response = requests.get(f"{self.base_url}/collections")
            result = response.json()
            return [coll["name"] for coll in result.get("collections", [])]
        except Exception as e:
            logger.error(f"Error listing collections: {str(e)}")
            raise
    
    def create_collection(self, name: str, metadata: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        """Create a new collection.
        
        Args:
            name: Name of the collection
            metadata: Optional metadata for the collection
            
        Returns:
            Collection info dictionary
        """
        try:
            data = {
                "name": name,
                "metadata": metadata or {"description": "Question-based embedding collection"}
            }
            response = requests.post(f"{self.base_url}/collections", json=data)
            if response.status_code != 201:
                raise Exception(f"Failed to create collection: {response.text}")
                
            return response.json()
        except Exception as e:
            logger.error(f"Error creating collection: {str(e)}")
            raise
    
    def process_document(
        self,
        collection_name: str,
        document: str,
        document_id: Optional[str] = None,
        document_metadata: Optional[Dict[str, Any]] = None,
        content_type: str = "documentation",
        questions_per_chunk: int = 3,
        chunk_size: int = 1000,
        chunk_overlap: int = 200
    ) -> Tuple[str, List[QuestionItem]]:
        """Process a document and store question embeddings in Chroma.
        
        Args:
            collection_name: Name of the collection to store in
            document: Text content to process
            document_id: Optional ID for the document
            document_metadata: Optional metadata for the document
            content_type: Type of content (documentation, code, architecture, etc.)
            questions_per_chunk: Number of questions to generate per chunk
            chunk_size: Size of document chunks in characters
            chunk_overlap: Overlap between chunks in characters
            
        Returns:
            Tuple of (collection_id, list of generated questions)
        """
        if not document:
            raise ValueError("Document cannot be empty")
            
        # Check if collection exists, create if not
        collections = self.list_collections()
        if collection_name not in collections:
            collection_info = self.create_collection(collection_name)
            collection_id = collection_info["id"]
        else:
            # Get collection ID
            response = requests.get(f"{self.base_url}/collections")
            result = response.json()
            collection_id = next(
                (coll["id"] for coll in result.get("collections", []) if coll["name"] == collection_name), 
                None
            )
            if not collection_id:
                raise ValueError(f"Collection {collection_name} not found")
        
        # Generate document ID if not provided
        doc_id = document_id or f"doc_{int(time.time())}"
        
        # Chunk the document
        chunks = self._chunk_document(document, chunk_size, chunk_overlap)
        logger.info(f"Created {len(chunks)} chunks from document")
        
        # Process each chunk
        all_questions = []
        
        for i, chunk in enumerate(chunks):
            chunk_id = f"{doc_id}_chunk_{i}"
            
            # Generate questions
            questions = self.question_generator.generate_questions(
                content=chunk,
                content_type=content_type,
                question_count=questions_per_chunk,
                analysis_metadata={"chunk_id": chunk_id}
            )
            
            # Filter and evaluate questions
            questions = self.question_generator.evaluate_questions(questions, chunk)
            
            # Store questions in all_questions for return
            all_questions.extend(questions)
            
            # Generate embeddings for questions
            question_texts = [q.question_text for q in questions]
            embeddings = self.embedding_generator.batch_generate_embeddings(question_texts)
            
            # Prepare metadatas
            metadatas = []
            for q in questions:
                metadata = {
                    "document_id": doc_id,
                    "chunk_id": chunk_id,
                    "question_type": q.question_type,
                    "confidence": q.confidence,
                    "source_text": chunk[:100] + "..." if len(chunk) > 100 else chunk
                }
                # Add document metadata if provided
                if document_metadata:
                    metadata.update({f"doc_{k}": v for k, v in document_metadata.items()})
                metadatas.append(metadata)
                
            # Generate IDs
            ids = [f"{chunk_id}_question_{j}" for j in range(len(questions))]
            
            # Add to collection
            add_url = f"{self.base_url}/collections/{collection_id}/add"
            data = {
                "ids": ids,
                "embeddings": embeddings,
                "metadatas": metadatas,
                "documents": question_texts
            }
            
            try:
                response = requests.post(add_url, json=data)
                if response.status_code != 201:
                    logger.warning(f"Failed to add chunk {i} questions: {response.text}")
            except Exception as e:
                logger.error(f"Error adding chunk {i} questions: {str(e)}")
                
        logger.info(f"Added {len(all_questions)} questions from {len(chunks)} chunks to collection {collection_name}")
        return collection_id, all_questions
    
    def search(
        self,
        collection_name: str,
        query: str,
        transform_query: bool = True,
        n_results: int = 5,
        include_distances: bool = True
    ) -> Dict[str, Any]:
        """Search for relevant content using question-based embedding.
        
        Args:
            collection_name: Name of the collection to search
            query: Search query text
            transform_query: Whether to transform the query to question format
            n_results: Number of results to return
            include_distances: Whether to include similarity distances in results
            
        Returns:
            Search results dictionary with questions, documents, and metadata
        """
        # Get collection ID
        response = requests.get(f"{self.base_url}/collections")
        result = response.json()
        collection_id = next(
            (coll["id"] for coll in result.get("collections", []) if coll["name"] == collection_name), 
            None
        )
        if not collection_id:
            raise ValueError(f"Collection {collection_name} not found")
        
        # Transform query if needed
        if transform_query:
            transformed_queries = self.query_transformer.transform_query(query, max_variations=2)
            search_query = transformed_queries[0]  # Use the most specific question
            logger.info(f"Transformed query '{query}' to '{search_query}'")
        else:
            search_query = query
            
        # Generate embedding for the query
        query_embedding = self.embedding_generator.generate_embedding(search_query)
        
        # Prepare include parameters
        include = ["documents", "metadatas"]
        if include_distances:
            include.append("distances")
            
        # Execute search
        query_url = f"{self.base_url}/collections/{collection_id}/query"
        data = {
            "query_embeddings": [query_embedding],
            "n_results": n_results,
            "include": include
        }
        
        try:
            response = requests.post(query_url, json=data)
            if response.status_code != 200:
                raise Exception(f"Search failed: {response.text}")
                
            results = response.json()
            
            # Enhance results with original query info
            results["original_query"] = query
            if transform_query:
                results["transformed_query"] = search_query
                
            return results
        except Exception as e:
            logger.error(f"Error searching: {str(e)}")
            raise
    
    def _chunk_document(self, document: str, chunk_size: int = 1000, overlap: int = 200) -> List[str]:
        """Split document into overlapping chunks.
        
        Args:
            document: Document text to chunk
            chunk_size: Maximum size of each chunk in characters
            overlap: Overlap between chunks in characters
            
        Returns:
            List of document chunks
        """
        if len(document) <= chunk_size:
            return [document]
            
        chunks = []
        start = 0
        
        while start < len(document):
            # Find a good breakpoint near the chunk_size
            end = min(start + chunk_size, len(document))
            
            # Avoid breaking in the middle of a sentence if possible
            if end < len(document):
                # Look for sentence breaks (., !, ?)
                for i in range(min(100, end - start)):
                    if document[end - i - 1] in ['.', '!', '?'] and (end - i < len(document) and document[end - i].isspace()):
                        end = end - i
                        break
            
            chunks.append(document[start:end])
            start = max(start + chunk_size - overlap, end - overlap)  # Ensure progress while maintaining overlap
            
        return chunks