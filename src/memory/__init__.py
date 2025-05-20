"""
Memory System

A layered memory system for storing and retrieving text via embeddings.

Layers:
1. Top: MemoryManager - Converts text to files using hashing
2. Middle: FileLayer - Processes files and generates embeddings
3. Bottom: ChromaLayer - Stores file references and embeddings in ChromaDB

Chain of Responsibility:
- Text → MemoryManager → FileLayer → ChromaLayer
- Query → [Embedding] → ChromaDB → [Files] → Content
"""

from .chroma_layer import ChromaLayer
from .file_layer import FileLayer
from .memory_manager import MemoryManager

__all__ = ['ChromaLayer', 'FileLayer', 'MemoryManager']