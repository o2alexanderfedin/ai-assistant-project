#!/usr/bin/env python3
"""
Example usage of question-based embedding with Chroma.

This example demonstrates:
1. Processing a document into chunks
2. Generating questions from each chunk
3. Creating embeddings from those questions
4. Storing in Chroma DB
5. Transforming user queries into questions
6. Performing similarity search

Requirements:
- sentence-transformers
- chromadb
- openai

Set OPENAI_API_KEY in your environment before running.
"""

import os
import json
import argparse
from typing import List, Dict, Any
import chromadb
from chromadb.utils import embedding_functions

from transformer import EmbeddingGenerator
from question_generator import QuestionGenerator, QueryTransformer, QuestionItem

# Example document chunking function
def chunk_document(document: str, chunk_size: int = 1000, overlap: int = 200) -> List[str]:
    """Split document into overlapping chunks."""
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

def main():
    parser = argparse.ArgumentParser(description="Question-based embedding example")
    parser.add_argument("--document", type=str, help="Path to document file to process")
    parser.add_argument("--query", type=str, help="Query to search for")
    parser.add_argument("--collection", type=str, default="question_embeddings", help="Chroma collection name")
    parser.add_argument("--embedding-model", type=str, default="all-MiniLM-L6-v2", help="Sentence transformer model name")
    args = parser.parse_args()
    
    # Check API key
    api_key = os.environ.get("OPENAI_API_KEY")
    if not api_key:
        raise ValueError("OPENAI_API_KEY environment variable must be set")
    
    # Initialize components
    embedding_generator = EmbeddingGenerator(model_name=args.embedding_model)
    question_generator = QuestionGenerator(api_key=api_key)
    query_transformer = QueryTransformer(api_key=api_key)
    
    # Initialize Chroma client
    chroma_client = chromadb.EphemeralClient()
    sentence_transformer_ef = embedding_functions.SentenceTransformerEmbeddingFunction(model_name=args.embedding_model)
    
    collection = chroma_client.get_or_create_collection(
        name=args.collection,
        embedding_function=sentence_transformer_ef
    )
    
    # Process document if provided
    if args.document:
        with open(args.document, 'r') as f:
            document = f.read()
            
        print(f"Processing document: {args.document} ({len(document)} characters)")
        
        # Chunk the document
        chunks = chunk_document(document)
        print(f"Created {len(chunks)} chunks")
        
        # Process each chunk
        for i, chunk in enumerate(chunks):
            print(f"\nProcessing chunk {i+1}/{len(chunks)}")
            
            # Generate questions
            questions = question_generator.generate_questions(
                content=chunk,
                content_type="documentation",
                question_count=3
            )
            
            # Print generated questions
            print("Generated questions:")
            for q in questions:
                print(f"- {q.question_text} ({q.question_type}, confidence: {q.confidence:.2f})")
            
            # Store in Chroma
            question_texts = [q.question_text for q in questions]
            question_metadatas = [{"chunk_id": i, 
                                   "question_type": q.question_type, 
                                   "confidence": q.confidence,
                                   "chunk_text": chunk[:100] + "..." if len(chunk) > 100 else chunk} 
                                 for q in questions]
            question_ids = [f"chunk_{i}_question_{j}" for j in range(len(questions))]
            
            # Add to collection
            collection.add(
                documents=question_texts,
                metadatas=question_metadatas,
                ids=question_ids
            )
            
        print(f"\nAdded {collection.count()} questions to Chroma collection '{args.collection}'")
    
    # Search if query provided
    if args.query:
        print(f"\nProcessing query: {args.query}")
        
        # Transform query into questions
        transformed_queries = query_transformer.transform_query(args.query, max_variations=2)
        print("Transformed queries:")
        for q in transformed_queries:
            print(f"- {q}")
        
        # Search using the first transformed query
        search_query = transformed_queries[0]
        results = collection.query(
            query_texts=[search_query],
            n_results=3,
            include=["documents", "metadatas", "distances"]
        )
        
        # Display results
        print("\nSearch results:")
        if results["documents"] and len(results["documents"]) > 0:
            for i, (doc, metadata, distance) in enumerate(
                zip(results["documents"][0], results["metadatas"][0], results["distances"][0])
            ):
                print(f"\nResult {i+1}:")
                print(f"Question: {doc}")
                print(f"Relevance: {1 - distance:.2f}")
                print(f"Original chunk: {metadata['chunk_text']}")
                print(f"Type: {metadata['question_type']}, Confidence: {metadata['confidence']}")
        else:
            print("No results found")
    
    print("\nExample completed successfully")

if __name__ == "__main__":
    main()