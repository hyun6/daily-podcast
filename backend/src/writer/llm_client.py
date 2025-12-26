import os
import json
import time
import google.generativeai as genai
from typing import List, Optional
from src.config import settings
from src.models import DialogueScript, DialogueLine

class GeminiClient:
    def __init__(self, api_key: Optional[str] = None):
        self.api_key = api_key or settings.GEMINI_API_KEY
        genai.configure(api_key=self.api_key)
        
        # Configure model with Thinking Mode for Gemini 3 Flash
        self.model_name = "gemini-3-flash-preview" # or latest stable flash
        self.generation_config = {
            "temperature": 0.7,
            "top_p": 0.95,
            "top_k": 40,
            "max_output_tokens": 8192,
            "response_mime_type": "application/json",
            # Thinking mode config (if supported by SDK version, otherwise prompts handle it)
            # "thinking_config": {"level": "medium"} 
        }
        
        self.model = genai.GenerativeModel(
            model_name=self.model_name,
            generation_config=self.generation_config,
            system_instruction="You are a professional podcast scriptwriter. Create engaging 5-minute dialogues."
        )

    def generate_script(self, text_content: str) -> DialogueScript:
        """
        Generates a podcast script from the given text content using Gemini.
        Implements rate limiting for Free Tier.
        """
        # Rate Limiting: Sleep 2 seconds before request
        time.sleep(2)
        
        prompt = f"""
        Analyze the following text using your reasoning capabilities. Identify the key insights, main arguments, and emotional tone.
        Then, generate a 5-minute engaging podcast script between two hosts:
        - Host A (InJoon): Professional, male host. Leads the conversation.
        - Host B (SunHi): Curious, female co-host. Asks questions and adds reactions.

        The script must be in Korean.
        Output MUST be a JSON object with this schema:
        {{
            "title": "Creative Podcast Title",
            "lines": [
                {{"speaker": "Host A", "text": "...", "emotion": "neutral"}},
                {{"speaker": "Host B", "text": "...", "emotion": "excited"}}
            ]
        }}

        Source Text:
        {text_content[:10000]}  # Limit context window if needed
        """

        try:
            response = self.model.generate_content(prompt)
            
            # Parse JSON from response
            json_content = json.loads(response.text)
            
            # Convert to Pydantic model
            lines = [DialogueLine(**line) for line in json_content.get("lines", [])]
            return DialogueScript(
                title=json_content.get("title", "Untitled Podcast"),
                lines=lines
            )
            
        except Exception as e:
            print(f"Error generating script: {e}")
            # Return empty or error script
            return DialogueScript(title="Error Generating Script", lines=[])
