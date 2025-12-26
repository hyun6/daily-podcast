import pytest
from unittest.mock import MagicMock, patch
from src.fetcher.text_fetchers import RSSFetcher, WebFetcher
from src.fetcher.youtube_fetcher import YouTubeFetcher

# --- RSS Fetcher Tests ---
@patch("src.fetcher.text_fetchers.feedparser.parse")
def test_rss_fetcher_success(mock_parse):
    # Mock feed data
    mock_entry = MagicMock()
    mock_entry.get.side_effect = lambda key, default=None: {
        "title": "Test Title",
        "summary": "Test Summary",
        "description": "Test Description"
    }.get(key, default)
    
    mock_feed = MagicMock()
    mock_feed.entries = [mock_entry]
    mock_parse.return_value = mock_feed

    fetcher = RSSFetcher()
    result = fetcher.fetch("http://test.rss")
    
    assert result is not None
    assert "Title: Test Title" in result
    assert "Summary: Test Summary" in result

@patch("src.fetcher.text_fetchers.feedparser.parse")
def test_rss_fetcher_empty(mock_parse):
    mock_feed = MagicMock()
    mock_feed.entries = []
    mock_parse.return_value = mock_feed

    fetcher = RSSFetcher()
    result = fetcher.fetch("http://test.rss")
    
    assert result is None

# --- Web Fetcher Tests ---
@patch("src.fetcher.text_fetchers.requests.get")
def test_web_fetcher_success(mock_get):
    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.text = "<html><body><article>Test Article Content</article></body></html>"
    mock_get.return_value = mock_response

    fetcher = WebFetcher()
    result = fetcher.fetch("http://test.web")
    
    assert result == "Test Article Content"

# --- YouTube Fetcher Tests ---
@patch("src.fetcher.youtube_fetcher.YouTubeTranscriptApi")
def test_youtube_fetcher_success(MockApi):
    MockApi.get_transcript.return_value = [
        {"text": "Hello", "start": 0, "duration": 1},
        {"text": "World", "start": 1, "duration": 1}
    ]

    fetcher = YouTubeFetcher()
    # Test with standard URL
    result = fetcher.fetch("https://www.youtube.com/watch?v=dQw4w9WgXcQ")
    
    assert result == "Hello World"

def test_youtube_id_extraction():
    fetcher = YouTubeFetcher()
    assert fetcher._extract_video_id("https://youtu.be/dQw4w9WgXcQ") == "dQw4w9WgXcQ"
    assert fetcher._extract_video_id("https://www.youtube.com/watch?v=dQw4w9WgXcQ") == "dQw4w9WgXcQ"
    assert fetcher._extract_video_id("https://www.youtube.com/embed/dQw4w9WgXcQ") == "dQw4w9WgXcQ"
