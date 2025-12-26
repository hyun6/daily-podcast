from unittest.mock import MagicMock
from src.writer.llm_client import GeminiClient, DialogueScript

class MockGeminiClient(GeminiClient):
    def __init__(self):
        # Skip actual genai init
        pass

    def generate_script(self, text_content: str) -> DialogueScript:
        # Return a fixed dummy script
        return DialogueScript(
            title="Mock Podcast Episode",
            lines=[
                {"speaker": "Host A", "text": "This is a mock script.", "emotion": "neutral"},
                {"speaker": "Host B", "text": "Reasoning mode is simulated.", "emotion": "curious"}
            ]
        )
