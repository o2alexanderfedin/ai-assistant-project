# Question-Based Embedding Implementation

## Table of Contents
- [Overview](#overview)
- [Installation](#installation)
- [Architecture](#architecture)
- [Components](#components)
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

### ChromaQBEClient

The `ChromaQBEClient` provides integration with Chroma vector database:

```python
from embedding.chroma_integration import ChromaQBEClient

# Initialize client
client = ChromaQBEClient(
    chroma_host="localhost",
    chroma_port=8100,
    embedding_model="all-MiniLM-L6-v2"
)

# Process a document into questions and store in Chroma
collection_id, questions = client.process_document(
    collection_name="documentation",
    document="Question-based embeddings improve search by...",
    document_id="doc_001",
    document_metadata={"source": "architecture_docs"},
    questions_per_chunk=3
)

# Search using question transformation
results = client.search(
    collection_name="documentation",
    query="embedding performance",
    transform_query=True,
    n_results=5
)
```

## Usage Examples

### Basic Example

```python
from embedding import EmbeddingGenerator, QuestionGenerator, QueryTransformer

# Initialize components
embedding_gen = EmbeddingGenerator()
question_gen = QuestionGenerator()
query_transformer = QueryTransformer()

# Process content
content = "Question-based embedding is a technique that represents content as questions rather than raw text."
questions = question_gen.generate_questions(content, question_count=2)

# Generate embeddings
question_embeddings = embedding_gen.batch_generate_embeddings([q.question_text for q in questions])

# Process a user query
user_query = "semantic search improvements"
transformed_queries = query_transformer.transform_query(user_query)
query_embedding = embedding_gen.generate_embedding(transformed_queries[0])

# Calculate similarity
from embedding.transformer import EmbeddingGenerator
similarity = embedding_gen.similarity(query_embedding, question_embeddings[0])
```

### Chroma Integration Example

See the full example script in [example.py](./example.py).

```bash
# Process a document and store questions in Chroma
python -m embedding.example --document your_document.txt --collection doc_questions

# Search for content
python -m embedding.example --query "your search query" --collection doc_questions
```

## Integration with Chroma

This implementation integrates with Chroma vector database in two ways:

1. **Direct API Integration**: The `ChromaQBEClient` class communicates with Chroma's HTTP API.

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

- **Caching**: The implementation includes basic caching for:
  - Transformed queries
  - Common questions

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

Last updated: May 20, 2025