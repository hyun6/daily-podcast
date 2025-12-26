import pytest
from fastapi.testclient import TestClient
from unittest.mock import patch, AsyncMock
from src.main import app

client = TestClient(app)

from src.writer.mock_client import MockGeminiClient

# Mock TTS Engine to avoid real network/file ops
@patch("src.api_router.tts_engine.generate_audio", new_callable=AsyncMock)
@patch("src.fetcher.text_fetchers.RSSFetcher.fetch")
@patch("src.api_router.llm_client", new=MockGeminiClient())
def test_generate_endpoint(mock_rss_fetch, mock_generate_audio):
    # Setup Mocks
    mock_rss_fetch.return_value = "Mock RSS Content"
    mock_generate_audio.return_value = "downloads/mock_episode.mp3"

    # Define Request Payload
    payload = {
        "sources": [
            {"source_type": "rss", "url": "https://example.com/feed.xml", "name": "Example Feed"}
        ],
        "force_refresh": True
    }

    # Call API
    response = client.post("/api/v1/generate", json=payload)

    # Assertions
    assert response.status_code == 200
    data = response.json()
    assert data["file_path"] == "downloads/mock_episode.mp3"
    assert data["metadata"]["title"] == "Mock Podcast Episode"
    assert "Example Feed" in data["metadata"]["sources"]

def test_episodes_list():
    response = client.get("/api/v1/episodes")
    assert response.status_code == 200
    assert "episodes" in response.json()
