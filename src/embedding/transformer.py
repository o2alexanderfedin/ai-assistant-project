from typing import List, Optional

import numpy as np
from sentence_transformers import SentenceTransformer

class EmbeddingGenerator:
    """Transformer-based embedding generator for question-based embeddings."""

    def __init__(self, model_name: str = "all-MiniLM-L6-v2"):
        """Initialize the generator with a model.
        
        Args:
            model_name: Name of the SentenceTransformer model to use
                        Default: all-MiniLM-L6-v2 (efficient general-purpose model)
                        Other options: 
                        - paraphrase-MiniLM-L6-v2 (better for paraphrase detection)
                        - multi-qa-MiniLM-L6-cos-v1 (optimized for question-answer pairs)
                        - all-mpnet-base-v2 (higher quality but slower)
        """
        self.model = SentenceTransformer(model_name)
        self.model_name = model_name
        self.embedding_dim = self.model.get_sentence_embedding_dimension()
        print(f"Initialized {model_name} with {self.embedding_dim} dimensions")

    def prepare_text(self, text: str) -> str:
        """Prepare text for embedding generation.
        
        Args:
            text: Input text to prepare
            
        Returns:
            Cleaned and normalized text
            
        Raises:
            ValueError: If text is empty
        """
        if not text:
            raise ValueError("Text cannot be empty")
        
        # Basic normalization
        return str(text).strip()

    def generate_embedding(self, text: str) -> List[float]:
        """Generate embedding for a single text.
        
        Args:
            text: Input text to embed
            
        Returns:
            List of floats representing the embedding vector
            
        Raises:
            ValueError: If text is empty
        """
        if not text:
            raise ValueError("Text cannot be empty")

        text = self.prepare_text(text)
        embedding = self.model.encode(text)
        return embedding.tolist() if isinstance(embedding, np.ndarray) else embedding

    def batch_generate_embeddings(self, texts: List[str]) -> List[List[float]]:
        """Generate embeddings for multiple texts efficiently.
        
        Args:
            texts: List of input texts to embed
            
        Returns:
            List of embedding vectors (each a list of floats)
            
        Raises:
            ValueError: If texts list is empty
        """
        if not texts:
            raise ValueError("Text list cannot be empty")

        texts = [self.prepare_text(text) for text in texts]
        embeddings = self.model.encode(texts)
        return embeddings.tolist() if isinstance(embeddings, np.ndarray) else embeddings

    def similarity(self, embedding1: List[float], embedding2: List[float]) -> float:
        """Calculate cosine similarity between two embeddings.
        
        Args:
            embedding1: First embedding vector
            embedding2: Second embedding vector
            
        Returns:
            Cosine similarity score (0-1 range)
            
        Raises:
            ValueError: If embeddings have different dimensions
        """
        if len(embedding1) != len(embedding2):
            raise ValueError(f"Embedding dimensions don't match: {len(embedding1)} vs {len(embedding2)}")
            
        # Convert to numpy arrays for efficient computation
        v1 = np.array(embedding1)
        v2 = np.array(embedding2)
        
        # Compute cosine similarity: dot(v1, v2) / (norm(v1) * norm(v2))
        dot_product = np.dot(v1, v2)
        norm_v1 = np.linalg.norm(v1)
        norm_v2 = np.linalg.norm(v2)
        
        # Avoid division by zero
        if norm_v1 == 0 or norm_v2 == 0:
            return 0.0
            
        similarity = dot_product / (norm_v1 * norm_v2)
        
        # Ensure result is in valid range
        return max(min(float(similarity), 1.0), -1.0)