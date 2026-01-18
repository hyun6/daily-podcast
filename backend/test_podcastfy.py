"""
Podcastfy Spike Test

이 스크립트는 Podcastfy 라이브러리가 한국어와 EdgeTTS 커스텀 목소리를 올바르게 지원하는지 검증합니다.
"""
import os
from dotenv import load_dotenv

# Load .env file for GEMINI_API_KEY
load_dotenv()

from podcastfy.client import generate_podcast

# Korean EdgeTTS configuration - matching the exact YAML structure
custom_config = {
    # Conversation Settings (top-level, matching conversation_config.yaml)
    "output_language": "Korean",
    "podcast_name": "일일 팟캐스트",
    "podcast_tagline": "AI가 들려주는 오늘의 이야기",
    "conversation_style": ["engaging", "conversational", "informative"],
    "roles_person1": "main host who explains topics clearly",
    "roles_person2": "curious co-host who asks questions",
    "ending_message": "오늘의 팟캐스트를 들어주셔서 감사합니다!",
    
    # TTS Settings - exact structure from conversation_config.yaml
    "text_to_speech": {
        "default_tts_model": "edge",
        "edge": {
            "default_voices": {
                "question": "ko-KR-InJoonNeural",  # Male - Host A
                "answer": "ko-KR-SunHiNeural"       # Female - Host B
            }
        }
    }
}

# Test with a simple Korean topic
# Using raw text instead of URL for simpler first test
test_text = """
인공지능(AI)이 우리 일상에 점점 더 깊이 들어오고 있습니다. 
스마트폰의 음성 비서부터 자율주행 자동차까지, AI 기술은 우리의 삶을 혁신적으로 변화시키고 있습니다.
하지만 동시에 AI가 일자리를 위협한다는 우려도 커지고 있습니다. 
전문가들은 AI와 함께 일하는 능력이 미래의 핵심 역량이 될 것이라고 말합니다.
"""

if __name__ == "__main__":
    print("=" * 50)
    print("Podcastfy Spike Test - 한국어 + EdgeTTS (v2)")
    print("=" * 50)
    
    # Check for GEMINI_API_KEY
    if not os.environ.get("GEMINI_API_KEY"):
        print("❌ Error: GEMINI_API_KEY not found in environment")
        exit(1)
    else:
        print("✅ GEMINI_API_KEY found")
    
    print("\n📝 Config Details:")
    print(f"   output_language: {custom_config['output_language']}")
    print(f"   default_tts_model: {custom_config['text_to_speech']['default_tts_model']}")
    print(f"   question voice: {custom_config['text_to_speech']['edge']['default_voices']['question']}")
    print(f"   answer voice: {custom_config['text_to_speech']['edge']['default_voices']['answer']}")
    
    print("\n🎙️ Generating podcast...")
    
    try:
        audio_file = generate_podcast(
            text=test_text,
            conversation_config=custom_config,
            tts_model="edge"
        )
        
        print("\n" + "=" * 50)
        print("✅ SUCCESS!")
        print(f"📁 Audio file: {audio_file}")
        print("=" * 50)
        print("\n다음 단계:")
        print("1. 생성된 오디오 파일을 재생하여 한국어 음성이 올바른지 확인하세요.")
        print("2. 두 명의 서로 다른 목소리(남성/여성)가 사용되었는지 확인하세요.")
        
    except Exception as e:
        print("\n" + "=" * 50)
        print(f"❌ FAILED: {e}")
        print("=" * 50)
        import traceback
        traceback.print_exc()
