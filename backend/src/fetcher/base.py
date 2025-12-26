from abc import ABC, abstractmethod
from typing import Optional

class BaseFetcher(ABC):
    @abstractmethod
    def fetch(self, url: str) -> Optional[str]:
        """
        Fetch content from the given URL and return the extracted text.
        Returns None if fetching fails.
        """
        pass
