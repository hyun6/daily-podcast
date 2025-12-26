from youtube_transcript_api import YouTubeTranscriptApi
from src.fetcher.base import BaseFetcher
from typing import Optional
import urllib.parse

class YouTubeFetcher(BaseFetcher):
    def fetch(self, url: str) -> Optional[str]:
        video_id = self._extract_video_id(url)
        if not video_id:
            print(f"Invalid YouTube URL: {url}")
            return None
            
        try:
            transcript_list = YouTubeTranscriptApi.get_transcript(video_id, languages=['en', 'ko'])
            
            # Combine transcript text
            full_text = " ".join([item['text'] for item in transcript_list])
            return full_text
            
        except Exception as e:
            print(f"Error fetching YouTube transcript {url}: {e}")
            return None

    def _extract_video_id(self, url: str) -> Optional[str]:
        """
        Extracts video ID from various YouTube URL formats.
        """
        parsed_url = urllib.parse.urlparse(url)
        if parsed_url.hostname == 'youtu.be':
            return parsed_url.path[1:]
        if parsed_url.hostname in ('www.youtube.com', 'youtube.com'):
            if parsed_url.path == '/watch':
                p = urllib.parse.parse_qs(parsed_url.query)
                return p['v'][0]
            if parsed_url.path[:7] == '/embed/':
                return parsed_url.path.split('/')[2]
            if parsed_url.path[:3] == '/v/':
                return parsed_url.path.split('/')[2]
        return None
