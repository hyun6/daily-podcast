FROM python:3.11-slim

# 시스템 의존성 설치
# ffmpeg: 오디오 처리
# mecab, libmecab-dev, mecab-ko-dic: 한국어 형태소 분석 (TTS/Text 처리용)
# curl, git: 유틸리티
RUN apt-get update && apt-get install -y \
    ffmpeg \
    mecab \
    libmecab-dev \
    mecab-ko-dic \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Python 의존성 설치
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 소스 코드 복사
COPY . .

# 필요한 디렉토리 생성
RUN mkdir -p data/audio data/transcripts downloads

# 포트 노출
EXPOSE 8000

# 서버 실행
CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]
