# 📋 Question-Based Embedding File Reference Requirements

**Date:** 2025-05-20

## 📑 Table of Contents
- [Overview](#overview)
- [Requirements](#requirements)
- [Implementation Plan](#implementation-plan)
- [Technical Considerations](#technical-considerations)

## Overview

This document captures requirements for enhancing the Question-Based Embedding (QBE) implementation to support a file reference mode. The enhancement involves adding the ability to store references to files instead of the full content in Chroma, allowing for efficient storage and retrieval of file paths when searching.

## Requirements

The Question-Based Embedding system must support two distinct modes:

### Mode 1: Content Storage (Current Implementation)
- Process document content directly
- Generate questions from document content
- Store questions and content chunks in ChromaDB
- Return relevant content chunks in search results

### Mode 2: File Reference Storage (New Requirement)
- Accept a file path as input
- Compute embeddings from the file's content
- Store only the file path in ChromaDB, not the actual content
- When querying, return the relevant file paths rather than content
- Optionally, provide a mechanism to retrieve content on demand when needed

## Implementation Plan

1. **Enhance `ChromaQBEClient` Class**
   - Add a `reference_mode` parameter to control behavior
   - Modify document processing to handle file paths directly
   - Update metadata structure to store file paths consistently

2. **Create File Processing Functions**
   - Implement functions to read and process different file types
   - Support basic text files initially, with extensibility for PDF, DOCX, etc.
   - Implement content extraction that preserves file reference

3. **Update Search Results Handling**
   - Modify result formatting based on mode
   - In reference mode, return file paths with relevance scores
   - Provide helpers for retrieving content when needed

4. **Extend Example Script**
   - Update to demonstrate both modes
   - Add examples of using reference mode with various file types
   - Show how to access original content when needed

## Technical Considerations

1. **File Path Storage**
   - Store absolute paths for reliability
   - Include file metadata (type, size, modification date)
   - Handle path normalization for cross-platform compatibility

2. **Chunking Strategy**
   - For reference mode, need to track which chunks come from which files
   - Consider storing chunk position information for later retrieval

3. **Performance Implications**
   - Reference mode significantly reduces storage requirements
   - May require additional I/O when retrieving actual content during result processing
   - Consider implementing a file cache for frequently accessed files

4. **Security Considerations**
   - Validate file paths to prevent path traversal attacks
   - Consider access control for file paths
   - Include options to store relative paths for portability

---

🧭 **Navigation**:
- [Home](/README.md)
- [Architecture Documentation](/docs/architecture/README.md)
- [QBE Architecture](/docs/architecture/components/question-based-embedding.md)
- [Question-Based Embedding Discussion](/docs/logs/2025-05-19/question-based-embedding-discussion.md)

Last updated: May 20, 2025