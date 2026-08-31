import ssl
ssl._create_default_https_context = ssl._create_unverified_context
import urllib3
urllib3.disable_warnings()
import os
import time
import queue
import threading
import sys
import numpy as np
import sounddevice as sd
import soundfile as sf
import requests
import spidev
from google import genai
from groq import Groq
from gtts import gTTS
from gpiozero import PWMOutputDevice
from datetime import datetime
import pygame

GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY", "")
GROQ_API_KEY = os.environ.get("GROQ_API_KEY", "")
NGROK_HEADERS = {'ngrok-skip-browser-warning': 'true'}
BACKEND_URL = "http://172.27.148.134:8000"
SESSION_ID = "rpi-001"

client_gemini = genai.Client(api_key=GEMINI_API_KEY)
client_groq = Groq(api_key=GROQ_API_KEY)

MODEL_NAME = "gemini-2.0-flash-lite"
SAMPLERATE = 16000
BLOCK_SIZE = 4000

audio_queue = queue.Queue()
pygame.mixer.init()

is_speaking = False

# 가스 감지 설정
BUZZER_PIN = 18
buzzer = PWMOutputDevice(BUZZER_PIN, frequency=2000)
spi = spidev.SpiDev()
spi.open(0, 0)
spi.max_speed_hz = 1000000
GAS_THRESHOLD = 900

def read_adc(channel):
    if channel < 0 or channel > 7:
        return -1
    adc = spi.xfer2([1, (8 + channel) << 4, 0])
    data = ((adc[1] & 3) << 8) + adc[2]
    return data

def send_gas_alert():
    try:
        requests.post(f"{BACKEND_URL}/alert/gas", verify=False, headers=NGROK_HEADERS)
        print("✅ 백엔드 가스 감지 알림 전송 완료!")
    except Exception as e:
        print(f"❌ 알림 전송 오류: {e}")

def gas_detection_thread():
    print("🔥 가스 감지 모니터링 시작!")
    while True:
        try:
            gas_level = read_adc(0)
            if gas_level > GAS_THRESHOLD:
                print(f"🚨 가스 감지됨! 수치: {gas_level}")
                buzzer.value = 0.5
                send_gas_alert()
                speak("위험! 가스가 감지되었습니다! 즉시 환기하세요!")
                time.sleep(5)
            else:
                buzzer.value = 0.0
            time.sleep(0.5)
        except Exception as e:
            print(f"가스 감지 오류: {e}")
            time.sleep(1)

def alert_check_thread():
    while True:
        try:
            res = requests.get(f"{BACKEND_URL}/alert/unresolved", verify=False, headers=NGROK_HEADERS, timeout=5)
            alerts = res.json()
            for alert in alerts:
                if not alert.get("is_resolved"):
                    speak(alert["message"])
                    requests.patch(f"{BACKEND_URL}/alert/{alert['id']}/resolve", verify=False, headers=NGROK_HEADERS, timeout=5)
        except Exception as e:
            print(f"알림 확인 오류: {e}")
        time.sleep(30)

def save_message(role, content):
    try:
        requests.post(f"{BACKEND_URL}/chat/", verify=False, headers=NGROK_HEADERS, json={
            "session_id": SESSION_ID,
            "role": role,
            "content": content
        }, timeout=5)
    except Exception as e:
        print(f"백엔드 저장 오류: {e}")

def check_alerts():
    try:
        res = requests.get(f"{BACKEND_URL}/alert/unresolved", verify=False, headers=NGROK_HEADERS, timeout=5)
        alerts = res.json()
        for alert in alerts:
            requests.patch(f"{BACKEND_URL}/alert/{alert['id']}/resolve", verify=False, headers=NGROK_HEADERS, timeout=5)
    except Exception as e:
        print(f"알림 확인 오류: {e}")

def speak(text):
    global is_speaking
    is_speaking = True
    try:
        import asyncio
        import edge_tts
        
        async def _speak():
            communicate = edge_tts.Communicate(text, "ko-KR-SunHiNeural")
            temp_mp3 = "/dev/shm/response.mp3"
            await communicate.save(temp_mp3)
            pygame.mixer.music.load(temp_mp3)
            pygame.mixer.music.play()
            while pygame.mixer.music.get_busy():
                time.sleep(0.1)
            pygame.mixer.music.unload()
        
        asyncio.run(_speak())
    except Exception as e:
        print(f"TTS 오류: {e}")
    finally:
        time.sleep(0.8)
        while not audio_queue.empty():
            try:
                audio_queue.get_nowait()
            except queue.Empty:
                break
        is_speaking = False

def get_ai_response(prompt):
    try:
        now = datetime.now().strftime("%Y년 %m월 %d일 %H시 %M분")
        response = client_groq.chat.completions.create(
            model="llama-3.1-8b-instant",
            messages=[
                {"role": "system", "content": f"너는 다정한 AI 손주야. 이모티콘은 말하지마. 짧고 친절하게 한국어로 대답해. 현재 시간은 {now}이야."},
                {"role": "user", "content": prompt}
            ]
        )
        return response.choices[0].message.content
    except Exception as e:
        print(f"Groq API 에러: {e}")
        return "죄송해요 어르신, 다시 말씀해 주시겠어요?"

def stt_processing_thread():
    print("OASIS 챗봇 가동 중... 말씀하시면 즉시 인식합니다.")
    check_alerts()
    buffer = np.zeros((0, 1), dtype=np.float32)
    THRESHOLD = 0.0044

    while True:
        try:
            if is_speaking:
                while not audio_queue.empty():
                    audio_queue.get()
                buffer = np.zeros((0, 1), dtype=np.float32)
                time.sleep(0.1)
                continue

            try:
                data = audio_queue.get(timeout=1)
                buffer = np.concatenate((buffer, data), axis=0)
            except queue.Empty:
                continue

            if len(buffer) >= SAMPLERATE * 2.5:
                rms = np.sqrt(np.mean(buffer**2))

                if rms < THRESHOLD:
                    buffer = np.zeros((0, 1), dtype=np.float32)
                    continue

                temp_wav = "/dev/shm/temp_segment.wav"
                sf.write(temp_wav, buffer, SAMPLERATE)
                text = ""

                with open(temp_wav, "rb") as file:
                    transcription = client_groq.audio.transcriptions.create(
                        file=(temp_wav, file.read()),
                        model="whisper-large-v3",
                        language="ko"
                    )
                    text = transcription.text.strip()

                if text and len(text) > 2:
                    print(f"\n나: {text} (음량: {rms:.4f})")
                    save_message("user", text)
                    buffer = np.zeros((0, 1), dtype=np.float32)
                    ai_answer = get_ai_response(text)
                    print(f"AI: {ai_answer}")
                    save_message("assistant", ai_answer)
                    speak(ai_answer)
                    while not audio_queue.empty():
                        audio_queue.get()
                else:
                    buffer = buffer[int(SAMPLERATE * 1.0):]

                if os.path.exists(temp_wav):
                    os.remove(temp_wav)

            audio_queue.task_done()

        except Exception as e:
            print(f"Groq 처리 에러: {e}")

def audio_callback(indata, frames, time, status):
    if status: print(status, file=sys.stderr)
    audio_queue.put(indata.copy())

def main():
    try:
        gas_thread = threading.Thread(target=gas_detection_thread)
        gas_thread.daemon = True
        gas_thread.start()

        alert_thread = threading.Thread(target=alert_check_thread)
        alert_thread.daemon = True
        alert_thread.start()

        with sd.InputStream(samplerate=SAMPLERATE, channels=1,
                          callback=audio_callback, blocksize=BLOCK_SIZE):
            stt_thread = threading.Thread(target=stt_processing_thread)
            stt_thread.daemon = True
            stt_thread.start()
            while True:
                time.sleep(1)
    except KeyboardInterrupt:
        print("\n🛑 프로그램 종료")
    finally:
        spi.close()
        buzzer.value = 0.0
        buzzer.close()

if __name__ == "__main__":
    main()
