FROM python:3.11-slim

# 시스템 의존성 설치
# ffmpeg: 오디오 처리
# 시스템 의존성 설치
RUN apt-get update --allow-releaseinfo-change && apt-get install -y --no-install-recommends \
    ffmpeg \
    mecab \
    libmecab-dev \
    mecab-ipadic \
    mecab-ipadic-utf8 \
    curl \
    git \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# mecab-ko-dic 설치 (옵션: 필요시 주석 해제)
# RUN pip install mecab-ko-dic

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
