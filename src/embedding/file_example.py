#!/usr/bin/env python3
"""
Example usage of question-based embedding with file references.

This example demonstrates:
1. Processing files into chunks
2. Generating questions from each chunk
3. Creating embeddings from those questions
4. Storing file references in Chroma DB
5. Transforming user queries into questions
6. Searching and retrieving file paths

Requirements:
- sentence-transformers
- chromadb
- openai

Set OPENAI_API_KEY in your environment before running.
"""

import os
import json
import argparse
import sys
from pathlib import Path
from typing import List, Dict, Any

from transformer import EmbeddingGenerator
from question_generator import QuestionGenerator, QueryTransformer, QuestionItem
from file_reference import FileReference, FileProcessor
from chroma_file_client import ChromaFileReferenceClient

def main():
    parser = argparse.ArgumentParser(description="Question-based embedding with file references example")
    parser.add_argument("--file", type=str, help="Path to file to process")
    parser.add_argument("--directory", type=str, help="Path to directory to process")
    parser.add_argument("--patterns", type=str, default="*.txt,*.md", help="File patterns to match (comma-separated)")
    parser.add_argument("--recursive", action="store_true", help="Recursively process directories")
    parser.add_argument("--query", type=str, help="Query to search for")
    parser.add_argument("--collection", type=str, default="file_references", help="Chroma collection name")
    parser.add_argument("--return-contents", action="store_true", help="Return file contents with search results")
    parser.add_argument("--embedding-model", type=str, default="all-MiniLM-L6-v2", help="Sentence transformer model name")
    
    args = parser.parse_args()
    
    if not args.file and not args.directory and not args.query:
        parser.print_help()
        print("\nError: You must specify at least one of --file, --directory, or --query")
        sys.exit(1)
    
    # Check API key
    api_key = os.environ.get("OPENAI_API_KEY")
    if not api_key:
        print("Error: OPENAI_API_KEY environment variable must be set")
        sys.exit(1)
    
    # Initialize client
    client = ChromaFileReferenceClient(
        embedding_model=args.embedding_model,
        openai_api_key=api_key
    )
    
    # Process file if provided
    if args.file:
        file_path = os.path.abspath(args.file)
        if not os.path.exists(file_path):
            print(f"Error: File not found: {file_path}")
            sys.exit(1)
            
        print(f"Processing file: {file_path}")
        try:
            questions = client.process_file(
                collection_name=args.collection,
                file_path=file_path,
                questions_per_chunk=3
            )
            
            print(f"Generated {len(questions)} questions from file")
            print("\nSample questions:")
            for i, q in enumerate(questions[:3]):  # Show first 3 questions
                print(f"{i+1}. {q.question_text} ({q.question_type}, confidence: {q.confidence:.2f})")
                
        except Exception as e:
            print(f"Error processing file: {str(e)}")
            sys.exit(1)
    
    # Process directory if provided
    if args.directory:
        dir_path = os.path.abspath(args.directory)
        if not os.path.isdir(dir_path):
            print(f"Error: Directory not found: {dir_path}")
            sys.exit(1)
            
        patterns = args.patterns.split(",")
        print(f"Processing directory: {dir_path}")
        print(f"File patterns: {patterns}")
        print(f"Recursive: {args.recursive}")
        
        try:
            results = client.process_directory(
                collection_name=args.collection,
                directory_path=dir_path,
                file_patterns=patterns,
                recursive=args.recursive,
                questions_per_chunk=3
            )
            
            # Print summary
            total_files = len(results)
            total_questions = sum(len(questions) for questions in results.values())
            print(f"\nProcessed {total_files} files, generated {total_questions} questions")
            
            # Print first few results
            if total_files > 0:
                print("\nFirst few files processed:")
                for i, (file_path, questions) in enumerate(list(results.items())[:3]):  # Show first 3 files
                    print(f"\n{i+1}. {file_path}: {len(questions)} questions")
                    for j, q in enumerate(questions[:2]):  # Show first 2 questions per file
                        print(f"   {j+1}. {q.question_text}")
                        
        except Exception as e:
            print(f"Error processing directory: {str(e)}")
            sys.exit(1)
    
    # Search if query provided
    if args.query:
        print(f"\nSearching for: {args.query}")
        
        try:
            results = client.search(
                collection_name=args.collection,
                query=args.query,
                transform_query=True,
                n_results=5,
                return_contents=args.return_contents
            )
            
            # Print results
            if results.get("transformed_query"):
                print(f"Transformed query: {results['transformed_query']}")
                
            print(f"\nFound {results['total_results']} results")
            
            for i, result in enumerate(results["results"]):
                print(f"\nResult {i+1}:")
                print(f"Question: {result['question']}")
                print(f"File: {result['file_reference']['file_path']}")
                
                if "relevance" in result:
                    print(f"Relevance: {result['relevance']:.2f}")
                    
                print(f"Type: {result['question_type']}, Confidence: {result['confidence']}")
                
                # Print chunk info if available
                if "chunk_index" in result["file_reference"]:
                    print(f"Chunk: {result['file_reference']['chunk_index']}")
                
                # Print content if available
                if "content" in result:
                    content = result["content"]
                    # Truncate if too long
                    if len(content) > 300:
                        content = content[:300] + "..."
                    print(f"\nContent: {content}")
        
        except Exception as e:
            print(f"Error searching: {str(e)}")
            sys.exit(1)
    
    print("\nExample completed successfully")

if __name__ == "__main__":
    main()