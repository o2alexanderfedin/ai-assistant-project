# Question-Based Embedding Implementation

## Table of Contents
- [Overview](#overview)
- [Installation](#installation)
- [Architecture](#architecture)
- [Components](#components)
- [Usage Modes](#usage-modes)
  - [Content Storage Mode](#content-storage-mode)
  - [File Reference Mode](#file-reference-mode)
- [Usage Examples](#usage-examples)
- [Integration with Chroma](#integration-with-chroma)
- [Performance Considerations](#performance-considerations)
- [Development](#development)

## Overview

This package implements the Question-Based Embedding (QBE) approach for enhanced semantic search, as described in the [architecture document](../../docs/architecture/components/question-based-embedding.md). 

The QBE approach improves search relevance by:
1. Transforming content into representative questions
2. Creating embeddings of these questions rather than raw content
3. Processing user queries into question format before searching
4. Using these aligned question-based representations for matching

## Installation

### Requirements

- Python 3.8+
- sentence-transformers
- openai
- chromadb
- requests
- numpy

### Package Installation

```bash
# Install from the project root
pip install -e .

# Or install dependencies directly
pip install sentence-transformers openai chromadb requests numpy
```

### API Keys

This implementation requires an OpenAI API key for question generation. Set it in your environment:

```bash
export OPENAI_API_KEY="your-api-key"
```

## Architecture

The implementation follows the architecture described in the design document with these key components:

1. **Document Processing Pipeline**
   - Content chunking
   - Question generation 
   - Question filtering and evaluation
   - Embedding generation

2. **Query Processing Pipeline**
   - Query analysis
   - Query-to-question transformation
   - Embedding generation
   - Vector search

3. **Chroma Integration**
   - Storage and retrieval of question embeddings
   - Integration with the MCP protocol

## Components

### EmbeddingGenerator

The `EmbeddingGenerator` class provides vector embeddings using Sentence Transformers:

```python
from embedding import EmbeddingGenerator

# Initialize with a model
generator = EmbeddingGenerator(model_name="all-MiniLM-L6-v2")

# Generate embeddings for a single text
embedding = generator.generate_embedding("What is question-based embedding?")

# Generate embeddings for multiple texts
embeddings = generator.batch_generate_embeddings([
    "What is vector search?",
    "How does RAG work?"
])
```

### QuestionGenerator

The `QuestionGenerator` creates representative questions from content:

```python
from embedding import QuestionGenerator

# Initialize with API key
generator = QuestionGenerator(api_key="your-openai-api-key")

# Generate questions from content
questions = generator.generate_questions(
    content="Question-based embeddings improve search relevance by aligning user intent with document content.",
    content_type="documentation",
    question_count=3
)

# Each question has metadata
for q in questions:
    print(f"Question: {q.question_text}")
    print(f"Type: {q.question_type}")
    print(f"Confidence: {q.confidence}")
```

### QueryTransformer

The `QueryTransformer` converts user queries into question format:

```python
from embedding import QueryTransformer

# Initialize transformer
transformer = QueryTransformer(api_key="your-openai-api-key")

# Transform a keyword query into questions
questions = transformer.transform_query(
    query="vector database performance",
    max_variations=3
)

# Result example:
# ['How does a vector database perform compared to traditional databases?',
#  'What factors affect vector database performance?',
#  'vector database performance']
```

### FileReference

The `FileReference` class represents a reference to a file with metadata:

```python
from embedding.file_reference import FileReference

# Create a file reference
file_ref = FileReference(
    file_path="/path/to/document.txt",
    chunk_index=2,  # Optional chunk information
    chunk_offset=1500,
    chunk_length=1000
)

# Get content from the reference
content = file_ref.get_content()

# Convert to/from dictionary
ref_dict = file_ref.to_dict()
restored_ref = FileReference.from_dict(ref_dict)
```

## Usage Modes

The implementation supports two distinct modes for working with documents:

### Content Storage Mode

In content storage mode, document content is processed and stored directly in the vector database. This is the default mode.

**Advantages:**
- Fast retrieval of relevant content without additional I/O
- Self-contained search results with content snippets
- No dependencies on external file system for retrieving results

**Use cases:**
- Short to medium-sized documents
- Content that changes infrequently
- When file paths might change or be unavailable

```python
from embedding.chroma_integration import ChromaQBEClient

# Initialize client for content storage mode
client = ChromaQBEClient(
    chroma_host="localhost",
    chroma_port=8100
)

# Process and store document content
client.process_document(
    collection_name="content_collection",
    document="Question-based embeddings improve search by...",
    document_id="doc_001",
    document_metadata={"source": "architecture_docs"}
)

# Search returns content directly
results = client.search(
    collection_name="content_collection",
    query="embedding performance"
)
```

### File Reference Mode

In file reference mode, document content is processed but only file references are stored in the vector database. This mode is more storage-efficient and keeps the database size small even for large document collections.

**Advantages:**
- Much lower storage requirements
- Always returns the latest file content
- Better for large document collections
- Clear separation between content and metadata

**Use cases:**
- Large document collections
- Content that changes frequently
- When file organization and paths are stable
- When you need to search but keep content separate

```python
from embedding.chroma_file_client import ChromaFileReferenceClient

# Initialize client for file reference mode
client = ChromaFileReferenceClient(
    chroma_host="localhost",
    chroma_port=8100
)

# Process files and store references
client.process_file(
    collection_name="file_collection",
    file_path="/path/to/document.txt"
)

# Search returns file references
results = client.search(
    collection_name="file_collection",
    query="embedding performance",
    return_contents=True  # Optional: read and return contents
)

# Access file paths from results
for result in results["results"]:
    file_path = result["file_reference"]["file_path"]
    print(f"Found in file: {file_path}")
    
    # Content only available if return_contents=True was specified
    if "content" in result:
        print(f"Content: {result['content']}")
```

## Usage Examples

### Content Storage Mode Example

```python
from embedding import EmbeddingGenerator, QuestionGenerator, QueryTransformer
from embedding.chroma_integration import ChromaQBEClient

# Initialize components
client = ChromaQBEClient()

# Process content
content = "Question-based embedding is a technique that represents content as questions rather than raw text."
client.process_document(collection_name="docs", document=content)

# Search
results = client.search(collection_name="docs", query="semantic search improvements")
```

### File Reference Mode Example

```python
from embedding.chroma_file_client import ChromaFileReferenceClient
from embedding.file_reference import FileProcessor

# Initialize client
client = ChromaFileReferenceClient()

# Process a single file
client.process_file(collection_name="files", file_path="/path/to/document.txt")

# Process a directory of files
client.process_directory(
    collection_name="files",
    directory_path="/path/to/documents",
    file_patterns=["*.txt", "*.md"],
    recursive=True
)

# Search for files
results = client.search(
    collection_name="files",
    query="semantic search",
    return_contents=False  # Set to True to include file contents
)

# Access results
for result in results["results"]:
    print(f"File: {result['file_reference']['file_path']}")
    print(f"Question: {result['question']}")
    print(f"Relevance: {result['relevance']}")
```

### Command Line Examples

The package includes two example scripts:

#### Content Storage Example

```bash
# Process a document and store content in Chroma
python -m src.embedding.example --document your_document.txt --collection content_collection

# Search for content
python -m src.embedding.example --query "your search query" --collection content_collection
```

#### File Reference Example

```bash
# Process a file and store references in Chroma
python -m src.embedding.file_example --file your_document.txt --collection file_collection

# Process a directory of files
python -m src.embedding.file_example --directory /path/to/docs --patterns "*.txt,*.md" --recursive --collection file_collection

# Search for files
python -m src.embedding.file_example --query "your search query" --collection file_collection

# Search and include file contents
python -m src.embedding.file_example --query "your search query" --collection file_collection --return-contents
```

## Integration with Chroma

This implementation integrates with Chroma vector database in two ways:

1. **Direct API Integration**: The client classes communicate with Chroma's HTTP API.

2. **MCP Protocol**: For Claude integration, the code works with the Chroma MCP server.

### MCP Usage

To use with the Chroma MCP server:

1. Start the Chroma server:
```bash
./start-chroma.sh
```

2. Configure the MCP client:
```bash
claude mcp add chroma uvx -- chroma-mcp --client-type http --host localhost --port 8100 --ssl false
```

3. Use in Claude conversations:
```
@chroma create_collection("qbe_docs")
```

## Performance Considerations

- **Embedding Model Selection**: The choice of embedding model significantly impacts performance. Options:
  - `all-MiniLM-L6-v2`: Fast, general purpose (384 dimensions)
  - `multi-qa-MiniLM-L6-cos-v1`: Optimized for Q&A pairs
  - `all-mpnet-base-v2`: Higher quality but slower
  - `text-embedding-3-small` (OpenAI): Excellent quality but requires API calls

- **Question Generation**: Uses the OpenAI API, which introduces:
  - API call latency during indexing
  - Cost considerations for large document collections
  - Rate limit considerations

- **Storage Mode Considerations**:
  - Content Storage: Higher storage requirements but faster retrieval
  - File Reference: Lower storage requirements but requires I/O for content retrieval

## Development

### Running Tests

```bash
pytest tests/embedding
```

### Adding New Models

To add support for new embedding models:

1. Update the `EmbeddingGenerator` class to support the new model
2. Ensure compatibility with Chroma's embedding format
3. Add documentation for the new model

---

🧭 **Navigation**:
- [Home](../../README.md)
- [Architecture Documentation](../../docs/architecture/README.md)
- [QBE Architecture](../../docs/architecture/components/question-based-embedding.md)
- [Discussion](../../docs/logs/2025-05-19/question-based-embedding-discussion.md)
- [File Reference Requirements](../../docs/logs/2025-05-20/qbe-file-reference-requirements.md)

Last updated: May 20, 2025