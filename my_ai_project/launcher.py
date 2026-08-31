#!/usr/bin/env python3
import subprocess
import os
from gpiozero import Button
from signal import pause

# 주황색 선이 연결된 GPIO 2번 핀
BUTTON_PIN = 2
button = Button(BUTTON_PIN)

# 실행할 대상 스크립트의 절대 경로
TARGET_SCRIPT = "/home/chatbot/my_ai_project/main.py"
# 실행할 때 기준이 될 작업 디렉토리
WORKING_DIR = "/home/chatbot/my_ai_project"

is_running = False

def run_main_script():
    global is_running

    # 이미 main.py가 실행 중이면 중복 실행 방지
    if is_running:
        print("이미 main.py가 실행 중입니다.")
        return

    print("노란색 버튼이 눌렸습니다. main.py를 실행합니다...")
    is_running = True

    try:
        # main.py가 있는 폴더 위치에서 파이썬 스크립트 실행
        subprocess.run(["python3", TARGET_SCRIPT], cwd=WORKING_DIR, check=True)
    except Exception as e:
        print(f"main.py 실행 중 오류 발생: {e}")
    finally:
        is_running = False
        print("main.py 실행이 종료되었습니다. 버튼 대기 중...")

# 버튼을 눌렀을 때 실행되도록 등록
button.when_pressed = run_main_script

print("백그라운드에서 버튼 입력 대기 중...")
pause()
