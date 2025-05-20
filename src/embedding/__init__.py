"""
Question-Based Embedding Module

This module implements the question-based embedding approach for enhanced semantic search.
It transforms content and queries into question format before embedding for better alignment
between information needs and content.
"""

from .transformer import EmbeddingGenerator
from .question_generator import QuestionGenerator, QueryTransformer, QuestionItem

__all__ = ['EmbeddingGenerator', 'QuestionGenerator', 'QueryTransformer', 'QuestionItem']