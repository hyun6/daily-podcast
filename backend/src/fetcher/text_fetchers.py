import feedparser
import requests
from bs4 import BeautifulSoup
from src.fetcher.base import BaseFetcher
from typing import Optional

class RSSFetcher(BaseFetcher):
    def fetch(self, url: str) -> Optional[str]:
        try:
            feed = feedparser.parse(url)
            if not feed.entries:
                return None
            
            # Combine title and description of latest 3 entries
            content = []
            for entry in feed.entries[:3]:
                title = entry.get("title", "")
                summary = entry.get("summary", "") or entry.get("description", "")
                # Remove HTML tags from summary
                soup = BeautifulSoup(summary, "html.parser")
                clean_summary = soup.get_text()
                content.append(f"Title: {title}\nSummary: {clean_summary}")
            
            return "\n\n".join(content)
        except Exception as e:
            print(f"Error fetching RSS {url}: {e}")
            return None

class WebFetcher(BaseFetcher):
    def fetch(self, url: str) -> Optional[str]:
        try:
            headers = {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
            }
            response = requests.get(url, headers=headers, timeout=10)
            response.raise_for_status()
            
            soup = BeautifulSoup(response.text, 'html.parser')
            
            # Extract main content (simplified heuristics)
            # Try to find common article tags
            article = soup.find('article') or soup.find('main') or soup.find('div', class_='content')
            
            if article:
                return article.get_text(separator='\n', strip=True)
            
            # Fallback: get all body text
            return soup.body.get_text(separator='\n', strip=True) if soup.body else None
            
        except Exception as e:
            print(f"Error fetching Web {url}: {e}")
            return None
