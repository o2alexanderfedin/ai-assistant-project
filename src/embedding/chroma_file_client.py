"""
Chroma File Reference Integration for Question-Based Embedding

This module extends the ChromaQBEClient to support file references,
allowing storage and retrieval of file paths instead of content.
"""

import os
import json
import time
import logging
from typing import List, Dict, Any, Optional, Tuple, Union
import requests

from .transformer import EmbeddingGenerator
from .question_generator import QuestionGenerator, QueryTransformer, QuestionItem
from .file_reference import FileReference, FileProcessor

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger("chroma_qbe.file")

class ChromaFileReferenceClient:
    """Client for Chroma Question-Based Embedding with file references."""
    
    def __init__(
        self,
        chroma_host: str = "localhost",
        chroma_port: int = 8100,
        use_ssl: bool = False,
        embedding_model: str = "all-MiniLM-L6-v2",
        openai_api_key: Optional[str] = None,
        chunk_size: int = 1000,
        chunk_overlap: int = 200
    ):
        """Initialize the Chroma File Reference Client.
        
        Args:
            chroma_host: Hostname of the Chroma server
            chroma_port: Port of the Chroma server
            use_ssl: Whether to use SSL for connection
            embedding_model: Name of the sentence-transformer model to use
            openai_api_key: OpenAI API key for question generation (if None, uses env var)
            chunk_size: Size of document chunks in characters
            chunk_overlap: Overlap between chunks in characters
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
            self.file_processor = FileProcessor(chunk_size=chunk_size, chunk_overlap=chunk_overlap)
            logger.info(f"Initialized Chroma File Reference Client with {embedding_model}")
        except Exception as e:
            logger.error(f"Failed to initialize components: {str(e)}")
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
                "metadata": metadata or {"description": "File reference collection", "type": "file_reference"}
            }
            response = requests.post(f"{self.base_url}/collections", json=data)
            if response.status_code != 201:
                raise Exception(f"Failed to create collection: {response.text}")
                
            return response.json()
        except Exception as e:
            logger.error(f"Error creating collection: {str(e)}")
            raise
            
    def _get_collection_id(self, collection_name: str) -> str:
        """Get the ID of a collection by name.
        
        Args:
            collection_name: Name of the collection
            
        Returns:
            Collection ID
            
        Raises:
            ValueError: If collection not found
        """
        response = requests.get(f"{self.base_url}/collections")
        result = response.json()
        collection_id = next(
            (coll["id"] for coll in result.get("collections", []) if coll["name"] == collection_name), 
            None
        )
        if not collection_id:
            raise ValueError(f"Collection {collection_name} not found")
        return collection_id
    
    def process_file(
        self,
        collection_name: str,
        file_path: str,
        content_type: str = "documentation",
        questions_per_chunk: int = 3,
        additional_metadata: Optional[Dict[str, Any]] = None
    ) -> List[QuestionItem]:
        """Process a file and store question embeddings with file references in Chroma.
        
        Args:
            collection_name: Name of the collection to store in
            file_path: Path to the file to process
            content_type: Type of content (documentation, code, architecture, etc.)
            questions_per_chunk: Number of questions to generate per chunk
            additional_metadata: Optional additional metadata to store with references
            
        Returns:
            List of generated questions
            
        Raises:
            FileNotFoundError: If file not found
            ValueError: If collection not found
        """
        file_path = os.path.abspath(file_path)
        if not os.path.exists(file_path):
            raise FileNotFoundError(f"File not found: {file_path}")
            
        # Check/create collection
        collections = self.list_collections()
        if collection_name not in collections:
            collection_info = self.create_collection(collection_name)
            collection_id = collection_info["id"]
        else:
            collection_id = self._get_collection_id(collection_name)
        
        # Process file into chunks with references
        chunks_with_refs = self.file_processor.process_file(file_path)
        logger.info(f"Created {len(chunks_with_refs)} chunks from file {file_path}")
        
        # Generate questions for each chunk
        all_questions = []
        all_file_refs = []
        
        for i, (chunk, file_ref) in enumerate(chunks_with_refs):
            # Generate questions
            questions = self.question_generator.generate_questions(
                content=chunk,
                content_type=content_type,
                question_count=questions_per_chunk,
                analysis_metadata={"chunk_index": file_ref.chunk_index}
            )
            
            # Filter and evaluate questions
            questions = self.question_generator.evaluate_questions(questions, chunk)
            
            # Store questions and references
            all_questions.extend(questions)
            
            # Create file references for each question
            for j, question in enumerate(questions):
                # Create a copy of the file reference for this question
                question_ref = FileReference(
                    file_path=file_ref.file_path,
                    chunk_index=file_ref.chunk_index,
                    chunk_offset=file_ref.chunk_offset,
                    chunk_length=file_ref.chunk_length,
                    metadata={
                        "question_index": j,
                        "question_type": question.question_type,
                        "confidence": question.confidence,
                        # Add any additional metadata
                        **(additional_metadata or {})
                    }
                )
                all_file_refs.append((question, question_ref))
        
        # Store in Chroma if we have questions
        if all_file_refs:
            # Generate embeddings for questions
            questions = [q for q, _ in all_file_refs]
            question_texts = [q.question_text for q in questions]
            embeddings = self.embedding_generator.batch_generate_embeddings(question_texts)
            
            # Prepare data for Chroma
            metadatas = []
            documents = []
            ids = []
            
            for i, (question, file_ref) in enumerate(all_file_refs):
                # Convert file reference to metadata
                ref_dict = file_ref.to_dict()
                
                # Store file path and reference info in metadata
                metadata = {
                    "file_path": ref_dict["file_path"],
                    "chunk_index": ref_dict.get("chunk_index", 0),
                    "question_type": question.question_type,
                    "confidence": question.confidence,
                    "reference_mode": True  # Mark as file reference mode
                }
                
                # Add file metadata
                if "metadata" in ref_dict:
                    metadata.update({f"file_{k}": v for k, v in ref_dict["metadata"].items()})
                
                # For documents, we store the question text but not the content
                documents.append(question.question_text)
                metadatas.append(metadata)
                
                # Generate a unique ID for this question+reference pair
                ids.append(f"file_{file_ref.get_unique_id()}_q{i}")
            
            # Add to collection
            add_url = f"{self.base_url}/collections/{collection_id}/add"
            data = {
                "ids": ids,
                "embeddings": embeddings,
                "metadatas": metadatas,
                "documents": documents
            }
            
            try:
                response = requests.post(add_url, json=data)
                if response.status_code != 201:
                    logger.warning(f"Failed to add file questions: {response.text}")
                    raise Exception(f"Failed to add file questions: {response.text}")
            except Exception as e:
                logger.error(f"Error adding file questions: {str(e)}")
                raise
                
        logger.info(f"Added {len(all_questions)} questions with file references to collection {collection_name}")
        return all_questions
    
    def process_directory(
        self,
        collection_name: str,
        directory_path: str,
        file_patterns: List[str] = ["*.txt", "*.md"],
        recursive: bool = True,
        content_type: str = "documentation",
        questions_per_chunk: int = 3,
        additional_metadata: Optional[Dict[str, Any]] = None
    ) -> Dict[str, List[QuestionItem]]:
        """Process all matching files in a directory.
        
        Args:
            collection_name: Name of the collection to store in
            directory_path: Path to the directory to process
            file_patterns: List of glob patterns to match files
            recursive: Whether to search directories recursively
            content_type: Type of content (documentation, code, architecture, etc.)
            questions_per_chunk: Number of questions to generate per chunk
            additional_metadata: Optional additional metadata to store with references
            
        Returns:
            Dictionary mapping file paths to lists of generated questions
        """
        directory_path = os.path.abspath(directory_path)
        if not os.path.isdir(directory_path):
            raise NotADirectoryError(f"Not a directory: {directory_path}")
        
        # Create processor to find files
        processor = FileProcessor()
        
        # Get all matching files
        from pathlib import Path
        all_files = []
        
        for pattern in file_patterns:
            if recursive:
                glob_pattern = "**/" + pattern
            else:
                glob_pattern = pattern
                
            for file_path in Path(directory_path).glob(glob_pattern):
                all_files.append(str(file_path))
        
        logger.info(f"Found {len(all_files)} files matching patterns {file_patterns} in {directory_path}")
        
        # Process each file
        results = {}
        for file_path in all_files:
            try:
                # Add directory-relative path to metadata
                meta = (additional_metadata or {}).copy()
                meta["rel_path"] = os.path.relpath(file_path, directory_path)
                
                # Process file
                questions = self.process_file(
                    collection_name=collection_name,
                    file_path=file_path,
                    content_type=content_type,
                    questions_per_chunk=questions_per_chunk,
                    additional_metadata=meta
                )
                results[file_path] = questions
            except Exception as e:
                logger.error(f"Error processing file {file_path}: {str(e)}")
        
        return results
    
    def search(
        self,
        collection_name: str,
        query: str,
        transform_query: bool = True,
        n_results: int = 5,
        include_distances: bool = True,
        return_contents: bool = False
    ) -> Dict[str, Any]:
        """Search for relevant files using question-based embedding.
        
        Args:
            collection_name: Name of the collection to search
            query: Search query text
            transform_query: Whether to transform the query to question format
            n_results: Number of results to return
            include_distances: Whether to include similarity distances in results
            return_contents: Whether to read and return file contents
            
        Returns:
            Search results dictionary with file references and optionally contents
        """
        collection_id = self._get_collection_id(collection_name)
        
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
            
            # Process results to extract file references
            processed_results = []
            
            if results["documents"] and len(results["documents"]) > 0:
                for i, (doc, metadata, *extra) in enumerate(zip(
                    results["documents"][0], 
                    results["metadatas"][0],
                    *(results["distances"][0] if include_distances and "distances" in results else []),
                )):
                    # Create a file reference from metadata
                    file_path = metadata.get("file_path")
                    if file_path:
                        file_ref = FileReference(
                            file_path=file_path,
                            chunk_index=metadata.get("chunk_index"),
                            chunk_offset=metadata.get("chunk_offset"),
                            chunk_length=metadata.get("chunk_length"),
                            metadata={k.replace("file_", ""): v for k, v in metadata.items() 
                                     if k.startswith("file_")}
                        )
                        
                        result_item = {
                            "question": doc,
                            "file_reference": file_ref.to_dict(),
                            "question_type": metadata.get("question_type"),
                            "confidence": metadata.get("confidence")
                        }
                        
                        # Add distance if included
                        if include_distances and "distances" in results:
                            result_item["distance"] = results["distances"][0][i]
                            result_item["relevance"] = 1 - results["distances"][0][i]
                        
                        # Add file content if requested
                        if return_contents:
                            try:
                                result_item["content"] = file_ref.get_content()
                            except Exception as e:
                                logger.warning(f"Failed to read content for {file_path}: {str(e)}")
                                result_item["content"] = f"[Error reading content: {str(e)}]"
                        
                        processed_results.append(result_item)
            
            # Return processed results
            return {
                "original_query": query,
                "transformed_query": search_query if transform_query else None,
                "results": processed_results,
                "total_results": len(processed_results)
            }
            
        except Exception as e:
            logger.error(f"Error searching: {str(e)}")
            raise