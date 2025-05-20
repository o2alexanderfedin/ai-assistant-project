"""
Question-Based Embedding Module

This module implements the question-based embedding approach for enhanced semantic search.
It transforms content and queries into question format before embedding for better alignment
between information needs and content.

The module supports two modes:
1. Content Storage Mode: Stores document content directly in the vector database
2. File Reference Mode: Stores references to files instead of content
"""

from .transformer import EmbeddingGenerator
from .question_generator import QuestionGenerator, QueryTransformer, QuestionItem
from .file_reference import FileReference, FileProcessor
from .chroma_file_client import ChromaFileReferenceClient

__all__ = [
    'EmbeddingGenerator', 
    'QuestionGenerator', 
    'QueryTransformer', 
    'QuestionItem',
    'FileReference',
    'FileProcessor',
    'ChromaFileReferenceClient'
]