from typing import List, Dict, Any, Optional
import openai
import os
import json

class QuestionItem:
    """Represents a generated question with metadata."""
    
    def __init__(
        self, 
        question_text: str, 
        question_type: str, 
        confidence: float, 
        source_mapping: Dict[str, Any]
    ):
        """Initialize a question item.
        
        Args:
            question_text: The actual question text
            question_type: Category of question (factual, relationship, purpose, process)
            confidence: Estimated quality score (0-1)
            source_mapping: Reference to source content location and metadata
        """
        self.question_text = question_text
        self.question_type = question_type
        self.confidence = confidence
        self.source_mapping = source_mapping
        
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary representation."""
        return {
            "question_text": self.question_text,
            "question_type": self.question_type,
            "confidence": self.confidence,
            "source_mapping": self.source_mapping
        }
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'QuestionItem':
        """Create a QuestionItem from dictionary data."""
        return cls(
            question_text=data["question_text"],
            question_type=data["question_type"],
            confidence=data["confidence"],
            source_mapping=data["source_mapping"]
        )


class QuestionGenerator:
    """Generates representative questions from content."""
    
    def __init__(self, api_key: Optional[str] = None, model: str = "gpt-3.5-turbo"):
        """Initialize the question generator.
        
        Args:
            api_key: OpenAI API key (if None, will use OPENAI_API_KEY env variable)
            model: The model to use for question generation
        """
        self.api_key = api_key or os.environ.get("OPENAI_API_KEY")
        if not self.api_key:
            raise ValueError("API key must be provided either directly or via OPENAI_API_KEY environment variable")
        
        self.model = model
        self.client = openai.OpenAI(api_key=self.api_key)
        
    def generate_questions(
        self,
        content: str,
        content_type: str = "documentation",
        analysis_metadata: Optional[Dict[str, Any]] = None,
        question_count: int = 5
    ) -> List[QuestionItem]:
        """Generate representative questions from content.
        
        Args:
            content: The text content to generate questions from
            content_type: Type of content (documentation, code, issue, etc.)
            analysis_metadata: Optional topic and entity analysis of the content
            question_count: Target number of questions to generate
            
        Returns:
            List of QuestionItem objects
        """
        if not content:
            raise ValueError("Content cannot be empty")
            
        # Prepare prompt with content type-specific instructions
        prompt = self._create_prompt(content, content_type, analysis_metadata, question_count)
        
        # Call OpenAI API to generate questions
        response = self.client.chat.completions.create(
            model=self.model,
            messages=[
                {"role": "system", "content": """You are an expert at generating high-quality questions from content.
                Your task is to create diverse, representative questions that capture the key information,
                relationships, and intentions in the content. Output in JSON format only."""},
                {"role": "user", "content": prompt}
            ],
            temperature=0.7,
            response_format={"type": "json_object"}
        )
        
        # Parse the response
        result = json.loads(response.choices[0].message.content)
        
        # Convert to QuestionItem objects
        questions = []
        for q in result.get("questions", []):
            questions.append(QuestionItem(
                question_text=q["question"],
                question_type=q["type"],
                confidence=q["confidence"],
                source_mapping={
                    "content_id": q.get("content_id", "main"),
                    "source_text": content[:100] + "..." if len(content) > 100 else content,
                    "metadata": analysis_metadata or {}
                }
            ))
            
        return questions
        
    def _create_prompt(
        self, 
        content: str, 
        content_type: str,
        analysis_metadata: Optional[Dict[str, Any]],
        question_count: int
    ) -> str:
        """Create a prompt for the question generation based on content type.
        
        Args:
            content: The content to generate questions from
            content_type: Type of content
            analysis_metadata: Optional content analysis
            question_count: Number of questions to generate
            
        Returns:
            Formatted prompt string
        """
        # Base prompt
        prompt = f"""Generate {question_count} diverse, high-quality questions from the following {content_type} content.
        
Content:
{content}

Instructions:
1. Generate {question_count} questions that capture the key information in the content
2. Include different types of questions:
   - Factual questions about the main concepts
   - Relationship questions exploring connections between ideas
   - Purpose questions about the "why" behind concepts
   - Process questions about how things work or how to achieve goals
3. Prioritize questions that would be most useful for information retrieval
4. Avoid yes/no questions - focus on open-ended questions
5. Each question should be standalone and not require additional context

Response format:
Return a JSON object with this structure:
{
  "questions": [
    {
      "question": "What is X?",
      "type": "factual|relationship|purpose|process",
      "confidence": 0.95,
      "content_id": "unique_id_or_section_name"
    },
    ...
  ]
}
"""

        # Add metadata if provided
        if analysis_metadata:
            metadata_str = json.dumps(analysis_metadata, indent=2)
            prompt += f"\n\nContent Analysis Metadata:\n{metadata_str}\n"
            prompt += "\nUse this metadata to inform your question generation."
            
        # Add content type-specific instructions
        if content_type == "code":
            prompt += "\n\nFor code content, include questions about:\n"
            prompt += "- Function purpose and behavior\n"
            prompt += "- Parameter meanings and return values\n"
            prompt += "- Algorithm complexity and performance\n"
            prompt += "- Edge cases and error handling\n"
        elif content_type == "documentation":
            prompt += "\n\nFor documentation content, include questions about:\n"
            prompt += "- Main concepts and terminology\n"
            prompt += "- Steps and procedures\n"
            prompt += "- Configuration options and settings\n"
            prompt += "- Common use cases and examples\n"
        elif content_type == "architecture":
            prompt += "\n\nFor architecture content, include questions about:\n"
            prompt += "- Component relationships and interfaces\n"
            prompt += "- System design principles\n"
            prompt += "- Data flows and processing\n"
            prompt += "- Scalability and performance considerations\n"
            
        return prompt
        
    def evaluate_questions(self, questions: List[QuestionItem], content: str) -> List[QuestionItem]:
        """Evaluate and filter a list of generated questions.
        
        Args:
            questions: List of question items to evaluate
            content: The source content for verification
            
        Returns:
            Filtered and sorted list of question items
        """
        if not questions:
            return []
            
        # For now, just sort by confidence and return
        # In a production implementation, this would include deduplication, quality checks, etc.
        sorted_questions = sorted(questions, key=lambda q: q.confidence, reverse=True)
        
        return sorted_questions


class QueryTransformer:
    """Transforms user queries into question format."""
    
    def __init__(self, api_key: Optional[str] = None, model: str = "gpt-3.5-turbo"):
        """Initialize the query transformer.
        
        Args:
            api_key: OpenAI API key (if None, will use OPENAI_API_KEY env variable)
            model: The model to use for transformation
        """
        self.api_key = api_key or os.environ.get("OPENAI_API_KEY")
        if not self.api_key:
            raise ValueError("API key must be provided either directly or via OPENAI_API_KEY environment variable")
        
        self.model = model
        self.client = openai.OpenAI(api_key=self.api_key)
        
    def transform_query(
        self,
        query: str,
        query_analysis: Optional[Dict[str, Any]] = None,
        max_variations: int = 3
    ) -> List[str]:
        """Transform a user query into question format.
        
        Args:
            query: Original user query text
            query_analysis: Optional analysis of query intent and structure
            max_variations: Maximum number of question variations to generate
            
        Returns:
            List of transformed questions in priority order
        """
        if not query:
            raise ValueError("Query cannot be empty")
            
        # Check if query is already a question
        if self._is_question(query):
            return [query]  # Return as is if already a question
            
        # Create prompt
        prompt = self._create_transform_prompt(query, query_analysis, max_variations)
        
        # Call OpenAI API
        response = self.client.chat.completions.create(
            model=self.model,
            messages=[
                {"role": "system", "content": """You are an expert at transforming search queries into 
                well-formed questions. Your task is to convert user input into questions that capture
                the underlying information need. Output in JSON format only."""},
                {"role": "user", "content": prompt}
            ],
            temperature=0.3,
            response_format={"type": "json_object"}
        )
        
        # Parse the response
        result = json.loads(response.choices[0].message.content)
        questions = result.get("questions", [])
        
        # Always include original query at the end as fallback
        if query not in questions:
            questions.append(query)
            
        return questions
        
    def _is_question(self, text: str) -> bool:
        """Check if text is already a question.
        
        Args:
            text: Text to check
            
        Returns:
            True if the text appears to be a question
        """
        text = text.strip()
        
        # Basic checks for question indicators
        question_starters = ["what", "when", "where", "which", "who", "whom", "whose", 
                            "why", "how", "can", "could", "would", "will", "is", "are", 
                            "do", "does", "did", "should", "have", "has", "had"]
                            
        first_word = text.split()[0].lower() if text else ""
        
        return (
            text.endswith("?") or 
            first_word in question_starters or
            "?" in text
        )
        
    def _create_transform_prompt(
        self, 
        query: str,
        query_analysis: Optional[Dict[str, Any]],
        max_variations: int
    ) -> str:
        """Create prompt for query transformation.
        
        Args:
            query: Original user query
            query_analysis: Optional query analysis
            max_variations: Maximum variations to generate
            
        Returns:
            Formatted prompt string
        """
        prompt = f"""Transform the following search query into up to {max_variations} well-formed questions that
capture the same information need:

QUERY: {query}

Instructions:
1. Create {max_variations} different question variations that express the same information need
2. Rank questions from most specific to most general
3. Ensure questions are grammatically correct and clear
4. Preserve all specific entities and technical terms from the original query
5. Questions should be standalone and not reference "the query" or "the document"

Response format:
Return a JSON object with this structure:
{{
  "questions": [
    "First and most specific question variation?",
    "Second question variation?",
    "Third more general question variation?"
  ]
}}
"""

        # Add query analysis if available
        if query_analysis:
            analysis_str = json.dumps(query_analysis, indent=2)
            prompt += f"\n\nQuery Analysis:\n{analysis_str}\n"
            prompt += "\nUse this analysis to inform your question transformations."
            
        return prompt