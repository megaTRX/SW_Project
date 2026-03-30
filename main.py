import os
import time
import sys
from google import genai  # 최신 SDK
from faster_whisper import WhisperModel
from gtts import gTTS
import pygame
import speech_recognition as sr

# --- [1. 환경 설정] ---
GEMINI_API_KEY = "AIzaSyC6Kl2eHXflS9K9mc700-crsWsfKbo_D6s" # 무료 gemini-API
client = genai.Client(api_key=GEMINI_API_KEY)

#  2.0-flash를 사용하고 싶었으나, 무료는 15회가 한계임.
# gemma-3-4를 사용하기로함
MODEL_NAME = "gemma-3-4b-it"

print("STT 모델 로딩 중 (라즈베리파이 5 최적화)...")
stt_model = WhisperModel("small", device="cpu", compute_type="float32", cpu_threads=4) # base 모델은 인식 정확도가 너무 떨어져서 인식 속도가 더 걸리더라도 small 모델을 사용
pygame.mixer.init()

def speak(text):
    """음성 출력 (TTS)"""
    print(f"Gemini: {text}")
    try:
        tts = gTTS(text=text, lang='ko')
        tts.save("response.mp3")
        pygame.mixer.music.load("response.mp3")
        pygame.mixer.music.play()
        while pygame.mixer.music.get_busy():
            time.sleep(0.1)
        pygame.mixer.music.unload()
        if os.path.exists("response.mp3"):
            os.remove("response.mp3")
    except Exception as e:
        print(f"TTS 출력 에러: {e}")

def listen_and_transcribe():
    """음성 인식 (STT)"""
    r = sr.Recognizer()
    with sr.Microphone() as source:
        print("\n[듣고 있습니다...] (어르신, 말씀하세요)")
        r.adjust_for_ambient_noise(source, duration=0.8)
        try:
            audio = r.listen(source, timeout=10, phrase_time_limit=10)
            with open("input.wav", "wb") as f:
                f.write(audio.get_wav_data())
            
            segments, _ = stt_model.transcribe("input.wav", beam_size=5, language="ko")
            text = "".join([s.text for s in segments]).strip()
            return text
        except Exception as e:
            return ""

def get_gemini_response(prompt):
    try:
        response = client.models.generate_content(
            model=MODEL_NAME,
            contents=f"너는 노인을 돌보는 다정한 AI 비서야.이모티콘은 전부 생략해서 말해줘: {prompt}"
        )
        return response.text
    except Exception as e:
        print(f"\n[Gemini API 상세 에러]: {e}")
        return "죄송해요 어르신, 다시 말씀해 주시겠어요?"

# --- [메인 루프] ---
def main():
    print(f"AI 음성 비서 가동 중 (모델: {MODEL_NAME})")
    try:
        while True:
            user_input = listen_and_transcribe()
            if not user_input:
                continue
            
            print(f"나: {user_input}")
            ai_answer = get_gemini_response(user_input)
            speak(ai_answer)
            
    except KeyboardInterrupt:
        print("\n프로그램을 종료합니다.")
    finally:
        if os.path.exists("input.wav"):
            os.remove("input.wav")

if __name__ == "__main__":
    main()
