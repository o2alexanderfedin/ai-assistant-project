"""
File Reference Utilities for Question-Based Embedding

This module provides utilities for working with file references in the
Question-Based Embedding system, allowing storage and retrieval of file paths
instead of content.
"""

import os
import time
import hashlib
import mimetypes
import logging
from typing import Dict, Any, List, Optional, Tuple, Union
from pathlib import Path
from datetime import datetime

logger = logging.getLogger("chroma_qbe.file_reference")

class FileReference:
    """Represents a reference to a file with metadata."""
    
    def __init__(
        self,
        file_path: str,
        chunk_index: Optional[int] = None,
        chunk_offset: Optional[int] = None,
        chunk_length: Optional[int] = None,
        metadata: Optional[Dict[str, Any]] = None
    ):
        """Initialize a file reference.
        
        Args:
            file_path: Absolute path to the file
            chunk_index: Optional index of chunk within the file
            chunk_offset: Optional character offset of chunk within file
            chunk_length: Optional length of chunk in characters
            metadata: Optional additional metadata
        """
        self.file_path = os.path.abspath(file_path)
        self.chunk_index = chunk_index
        self.chunk_offset = chunk_offset
        self.chunk_length = chunk_length
        self._metadata = metadata or {}
        
        # Add file stats
        self._add_file_stats()
        
    def _add_file_stats(self):
        """Add file statistics to metadata."""
        try:
            if os.path.exists(self.file_path):
                stats = os.stat(self.file_path)
                self._metadata.update({
                    "file_size": stats.st_size,
                    "last_modified": datetime.fromtimestamp(stats.st_mtime).isoformat(),
                    "content_type": mimetypes.guess_type(self.file_path)[0] or "unknown",
                    "file_name": os.path.basename(self.file_path),
                    "directory": os.path.dirname(self.file_path)
                })
            else:
                logger.warning(f"File not found: {self.file_path}")
                self._metadata.update({
                    "file_exists": False,
                    "file_name": os.path.basename(self.file_path),
                    "directory": os.path.dirname(self.file_path)
                })
        except Exception as e:
            logger.error(f"Error getting file stats for {self.file_path}: {str(e)}")
    
    def get_content(self) -> str:
        """Get the content from the referenced file.
        
        Returns:
            Content of the file or specified chunk
            
        Raises:
            FileNotFoundError: If the file does not exist
            ValueError: If the chunk specifications are invalid
        """
        if not os.path.exists(self.file_path):
            raise FileNotFoundError(f"File not found: {self.file_path}")
            
        with open(self.file_path, 'r', encoding='utf-8') as f:
            if self.chunk_offset is not None and self.chunk_length is not None:
                f.seek(self.chunk_offset)
                return f.read(self.chunk_length)
            else:
                return f.read()
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary representation.
        
        Returns:
            Dictionary with file reference data
        """
        result = {
            "file_path": self.file_path,
            "metadata": self._metadata
        }
        
        if self.chunk_index is not None:
            result["chunk_index"] = self.chunk_index
            
        if self.chunk_offset is not None:
            result["chunk_offset"] = self.chunk_offset
            
        if self.chunk_length is not None:
            result["chunk_length"] = self.chunk_length
            
        return result
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'FileReference':
        """Create a FileReference from a dictionary.
        
        Args:
            data: Dictionary with file reference data
            
        Returns:
            FileReference instance
        """
        return cls(
            file_path=data["file_path"],
            chunk_index=data.get("chunk_index"),
            chunk_offset=data.get("chunk_offset"),
            chunk_length=data.get("chunk_length"),
            metadata=data.get("metadata", {})
        )
    
    def get_unique_id(self) -> str:
        """Generate a unique ID for this file reference.
        
        Returns:
            Unique ID string
        """
        base = f"{self.file_path}:{self.chunk_index or 0}:{self.chunk_offset or 0}:{self.chunk_length or 0}"
        return hashlib.md5(base.encode('utf-8')).hexdigest()
        

class FileProcessor:
    """Processes files for question-based embedding."""
    
    def __init__(self, chunk_size: int = 1000, chunk_overlap: int = 200):
        """Initialize the file processor.
        
        Args:
            chunk_size: Maximum size of each chunk in characters
            chunk_overlap: Overlap between chunks in characters
        """
        self.chunk_size = chunk_size
        self.chunk_overlap = chunk_overlap
        
    def read_file(self, file_path: str) -> str:
        """Read content from a file.
        
        Args:
            file_path: Path to the file to read
            
        Returns:
            File content as string
            
        Raises:
            FileNotFoundError: If the file does not exist
        """
        file_path = os.path.abspath(file_path)
        if not os.path.exists(file_path):
            raise FileNotFoundError(f"File not found: {file_path}")
            
        with open(file_path, 'r', encoding='utf-8') as f:
            return f.read()
            
    def process_file(self, file_path: str) -> List[Tuple[str, FileReference]]:
        """Process a file into chunks with file references.
        
        Args:
            file_path: Path to the file to process
            
        Returns:
            List of (chunk_content, file_reference) tuples
            
        Raises:
            FileNotFoundError: If the file does not exist
        """
        file_path = os.path.abspath(file_path)
        content = self.read_file(file_path)
        
        # Create chunks with references
        chunks_with_refs = []
        
        # Create chunks
        if len(content) <= self.chunk_size:
            # Single chunk case
            ref = FileReference(file_path=file_path, chunk_index=0, 
                               chunk_offset=0, chunk_length=len(content))
            chunks_with_refs.append((content, ref))
        else:
            # Multiple chunks
            start = 0
            chunk_index = 0
            
            while start < len(content):
                # Find a good breakpoint near the chunk_size
                end = min(start + self.chunk_size, len(content))
                
                # Avoid breaking in the middle of a sentence if possible
                if end < len(content):
                    # Look for sentence breaks (., !, ?)
                    for i in range(min(100, end - start)):
                        if content[end - i - 1] in ['.', '!', '?'] and (end - i < len(content) and content[end - i].isspace()):
                            end = end - i
                            break
                
                chunk = content[start:end]
                ref = FileReference(
                    file_path=file_path,
                    chunk_index=chunk_index,
                    chunk_offset=start,
                    chunk_length=len(chunk)
                )
                
                chunks_with_refs.append((chunk, ref))
                
                # Move to next chunk
                start = max(start + self.chunk_size - self.chunk_overlap, end - self.chunk_overlap)
                chunk_index += 1
                
        return chunks_with_refs
    
    def process_directory(
        self, 
        directory_path: str,
        file_patterns: List[str] = ["*.txt", "*.md"],
        recursive: bool = True
    ) -> List[Tuple[str, FileReference]]:
        """Process all matching files in a directory.
        
        Args:
            directory_path: Path to the directory to process
            file_patterns: List of glob patterns to match files
            recursive: Whether to search directories recursively
            
        Returns:
            List of (chunk_content, file_reference) tuples for all matching files
        """
        directory_path = os.path.abspath(directory_path)
        if not os.path.isdir(directory_path):
            raise NotADirectoryError(f"Not a directory: {directory_path}")
            
        all_chunks_with_refs = []
        
        for pattern in file_patterns:
            if recursive:
                glob_pattern = os.path.join(directory_path, "**", pattern)
            else:
                glob_pattern = os.path.join(directory_path, pattern)
                
            for file_path in Path(directory_path).glob(glob_pattern):
                try:
                    file_chunks = self.process_file(str(file_path))
                    all_chunks_with_refs.extend(file_chunks)
                except Exception as e:
                    logger.error(f"Error processing file {file_path}: {str(e)}")
                    
        return all_chunks_with_refs