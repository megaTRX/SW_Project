# 🤖 SW_Project (Raspberry Pi 5 Chatbot & LCD Drivers)

[![Python 3.11+](https://img.shields.io/badge/python-3.11+-blue.svg)](https://www.python.org/)
[![Platform](https://img.shields.io/badge/platform-Raspberry%20Pi%205-red.svg)](https://www.raspberrypi.com/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](https://opensource.org/licenses/MIT)

Welcome to **SW_Project**! This repository integrates a smart chatbot and AI voice assistant system built for the **Raspberry Pi 5** alongside pre-configured **LCDWiki Display Drivers** to enable modular portable monitor setup.

---

## 📂 Repository Structure

The workspace has been organized as follows to separate the primary software projects from the driver utility scripts:

```
SW_Project/
├── oasis/                     # Chatbot & Gas Sensor Project
│   ├── mq5.py                 # MQ5 Gas Sensor integration script
│   └── temporaryMain.py       # Main chatbot launcher and logic
├── my_ai_project/             # AI Voice & Camera Project
│   ├── main.py                # Main Gemini/Groq Voice Assistant & Camera Stream
│   ├── camera_stream.py       # Camera streaming utility
│   └── launcher.py            # Startup helper
├── LCD-show/                  # Isolated LCD Wiki Display Drivers
│   ├── boot/, etc/, usr/      # Configurations and device tree overlays (.dtb)
│   ├── *.deb                  # Local dependency packages
│   ├── *show                  # Model-specific setup scripts (e.g. LCD35-show)
│   └── rotate.sh              # Screen rotation controller
├── rpi-fbcp/                  # Frame Buffer Copy Library
├── requirements_env.txt       # Dependencies for sensor/chatbot environment
├── requirements_myenv.txt     # Dependencies for AI/camera assistant environment
└── README.md                  # Project documentation (This file)
```

---

## 🚀 Getting Started

### 1. Python Environment Setup
We maintain two virtual environments depending on the module you want to run. Navigate to the project root and choose one of the following setups:

#### Option A: Chatbot & Sensor Environment (`env`)
This environment contains dependencies for General GenAI, Groq, Pygame, and hardware interface bindings like CircuitPython.
```bash
python -m venv env
source env/bin/activate
pip install -r requirements_env.txt
```

#### Option B: AI Voice Assistant & Camera Environment (`myenv`)
This environment contains dependencies for Edge-TTS, Flask server, OpenCV, Scipy, and media interfaces.
```bash
python -m venv myenv
source myenv/bin/activate
pip install -r requirements_myenv.txt
```

---

### 2. API Key Configuration
Both project environments require API Keys to communicate with LLM models. For security reasons, do not hardcode your keys inside the scripts. Instead, export them as environment variables before running:

```bash
export GEMINI_API_KEY="your_gemini_api_key_here"
export GROQ_API_KEY="your_groq_api_key_here"
```

---

### 3. Running the Projects

#### Running the Chatbot (`oasis`)
Ensure you are in the `env` virtual environment:
```bash
python oasis/temporaryMain.py
```

#### Running the Voice Assistant (`my_ai_project`)
Ensure you are in the `myenv` virtual environment:
```bash
python my_ai_project/main.py
```

---

## 🖥️ LCD Driver Setup (`LCD-show/`)

If you are using a portable Raspberry Pi display shield, install the corresponding display driver script located inside the `LCD-show/` folder.

> [!IMPORTANT]
> Always execute the installer scripts from **inside** the `LCD-show/` directory, as they rely on local relative paths for setting up system overlays.

### Driver Installation Steps
1. Clone the repository and navigate to the driver folder:
   ```bash
   git clone https://github.com/megaTRX/SW_Project.git
   cd SW_Project/LCD-show/
   chmod -R 755 .
   ```
2. Execute the driver installer matching your display module:
   * **For 3.5" RPi Display (MPI3501):**
     ```bash
     sudo ./LCD35-show
     ```
   * **For MHS-3.5" RPi Display (MHS3528):**
     ```bash
     sudo ./MHS35-show
     ```
   * **For 5.0" HDMI Display (Resistive Touch - MPI5008):**
     ```bash
     sudo ./LCD5-show
     ```

*(For other display models, check the script names matching `*show` inside [LCD-show/](file:///d:/새%20폴더/SW_Project/LCD-show) and run them in a similar fashion).*

### 🔄 Screen Rotation Guide
Once the driver has been successfully installed and the system reboots, you can rotate the display coordinates (0°, 90°, 180°, 270°) by entering the driver folder and running the rotation tool:

```bash
cd SW_Project/LCD-show/
sudo ./rotate.sh 90
```
*(Replace `90` with `0`, `180`, or `270` based on your desired orientation).*
