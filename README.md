# 🤖 SW_Project (라즈베리파이 5 챗봇 & LCD 드라이버)

[![Python 3.11+](https://img.shields.io/badge/python-3.11+-blue.svg)](https://www.python.org/)
[![Platform](https://img.shields.io/badge/platform-Raspberry%20Pi%205-red.svg)](https://www.raspberrypi.com/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](https://opensource.org/licenses/MIT)

**SW_Project** 저장소에 오신 것을 환영합니다! 이 저장소는 **라즈베리파이 5(Raspberry Pi 5)** 기반의 스마트 챗봇 및 AI 음성 비서 시스템과, 휴대용 모니터 설정을 위한 **LCDWiki 디스플레이 드라이버** 모듈을 통합한 프로젝트입니다.

---

## 📂 저장소 디렉토리 구조

프로젝트 소스 코드와 LCD 드라이버 유틸리티 스크립트를 명확히 구분하기 위해 다음과 같이 폴더 구조를 격리 및 정리했습니다.

```
SW_Project/
├── oasis/                     # 가스 센서 및 챗봇 메인 프로젝트
│   ├── mq5.py                 # MQ5 가스 센서 연동 스크립트
│   └── temporaryMain.py       # 메인 챗봇 제어 루프 및 프로그램
├── my_ai_project/             # AI 음성 비서 및 카메라 프로젝트
│   ├── main.py                # Gemini/Groq 음성 비서 & 카메라 스트림 메인 스크립트
│   ├── camera_stream.py       # 카메라 스트리밍 유틸리티
│   └── launcher.py            # 자동 실행 도우미
├── LCD-show/                  # 독립 격리된 LCDWiki 디스플레이 드라이버
│   ├── boot/, etc/, usr/      # 시스템 설정 및 디바이스 트리 오버레이 (.dtb)
│   ├── *.deb                  # 로컬 설치 의존성 패키지
│   ├── *show                  # 디스플레이 모델별 드라이버 설치 스크립트 (예: LCD35-show)
│   └── rotate.sh              # 화면 회전(각도) 제어 스크립트
├── rpi-fbcp/                  # 프레임버퍼 복사 라이브러리
├── requirements_env.txt       # 챗봇 및 센서 환경(env) 의존성 패키지 목록
├── requirements_myenv.txt     # AI 비서 및 카메라 환경(myenv) 의존성 패키지 목록
└── README.md                  # 프로젝트 설명 문서 (본 파일)
```

---

## 🚀 시작하기

### 1. 파이썬 가상환경 설정
실행하려는 모듈에 따라 두 가지 가상환경 중 하나를 선택하여 설정합니다. 프로젝트 루트 디렉토리에서 아래 명령어를 실행하세요.

#### 옵션 A: 챗봇 및 센서 환경 (`env`)
GenAI, Groq, Pygame, 하드웨어 바인딩(CircuitPython 등)이 포함된 환경입니다.
```bash
python -m venv env
source env/bin/activate
pip install -r requirements_env.txt
```

#### 옵션 B: AI 음성 비서 및 카메라 환경 (`myenv`)
Edge-TTS, Flask 서버, OpenCV, Scipy 및 각종 미디어 인터페이스 패키지가 포함된 환경입니다.
```bash
python -m venv myenv
source myenv/bin/activate
pip install -r requirements_myenv.txt
```

---

### 2. API 키 설정 (보안)
챗봇과 음성 비서 기능은 원격 AI 모델(Gemini, Groq)과 통신하기 때문에 API 키 설정이 필요합니다. **보안을 위해 소스 코드에 키를 직접 입력(하드코딩)하지 마시고**, 실행하기 전에 터미널에 환경 변수로 등록하여 사용하세요.

```bash
export GEMINI_API_KEY="본인의_Gemini_API_키"
export GROQ_API_KEY="본인의_Groq_API_키"
```

---

### 3. 프로젝트 실행 방법

#### 챗봇 실행 (`oasis`)
`env` 가상환경이 활성화되어 있는지 확인한 후 실행합니다:
```bash
python oasis/temporaryMain.py
```

#### AI 음성 비서 실행 (`my_ai_project`)
`myenv` 가상환경이 활성화되어 있는지 확인한 후 실행합니다:
```bash
python my_ai_project/main.py
```

---

## 🖥️ LCD 드라이버 설정 (`LCD-show/`)

라즈베리파이용 확장 LCD 디스플레이 실드를 사용하는 경우, `LCD-show/` 폴더 내에 있는 모델명에 맞는 설치 스크립트를 실행합니다.

> [!IMPORTANT]
> **반드시 `LCD-show/` 디렉토리 내부로 이동한 후 설치 스크립트를 실행해야 합니다.** 스크립트 내부에서 설정 리소스 폴더(boot, etc, usr 등)를 상대 경로로 참조하여 설치를 진행하기 때문입니다.

### 드라이버 설치 단계
1. 저장소를 클론한 후 드라이버 폴더로 이동하여 실행 권한을 부여합니다:
   ```bash
   git clone https://github.com/megaTRX/SW_Project.git
   cd SW_Project/LCD-show/
   chmod -R 755 .
   ```
2. 본인이 소지한 LCD 모델명에 대응하는 스크립트를 실행합니다:
   * **3.5" RPi Display (MPI3501):**
     ```bash
     sudo ./LCD35-show
     ```
   * **MHS-3.5" RPi Display (MHS3528):**
     ```bash
     sudo ./MHS35-show
     ```
   * **5.0" HDMI Display (감압식 터치 - MPI5008):**
     ```bash
     sudo ./LCD5-show
     ```

*(기타 디스플레이 모델은 [LCD-show/](file:///d:/새%20폴더/SW_Project/LCD-show) 디렉토리 내부에 있는 `*show` 파일명들을 확인하고 동일한 방식으로 실행해 주시면 됩니다.)*

### 🔄 화면 회전 방법
드라이버 설치가 완료되어 재부팅된 후, 화면과 터치 좌표를 회전(0°, 90°, 180°, 270°)하고 싶다면 드라이버 폴더 안으로 이동해 회전 스크립트를 실행합니다.

```bash
cd SW_Project/LCD-show/
sudo ./rotate.sh 90
```
*(위의 `90` 부분을 필요에 따라 `0`, `180`, `270`으로 변경하여 화면 각도를 제어할 수 있습니다).*
