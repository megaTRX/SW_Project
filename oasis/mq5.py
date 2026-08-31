import spidev
import time
import requests
from gpiozero import PWMOutputDevice

BUZZER_PIN = 18
buzzer = PWMOutputDevice(BUZZER_PIN, frequency=2000)

spi = spidev.SpiDev()
spi.open(0, 0)
spi.max_speed_hz = 1000000

THRESHOLD = 900
BACKEND_URL = "http://172.27.148.134:8000"

def read_adc(channel):
    if channel < 0 or channel > 7:
        return -1
    adc = spi.xfer2([1, (8 + channel) << 4, 0])
    data = ((adc[1] & 3) << 8) + adc[2]
    return data

def send_gas_alert():
    try:
        requests.post(f"{BACKEND_URL}/alert/gas")
        print("✅ 백엔드 가스 감지 알림 전송 완료!")
    except Exception as e:
        print(f"❌ 알림 전송 오류: {e}")

print("="*40)
print("가스 센서 및 부저 테스트를 시작합니다.")
print("="*40)

buzzer.value = 0.5
time.sleep(1)
buzzer.value = 0.0
time.sleep(1)

try:
    while True:
        gas_level = read_adc(0)
        print(f"현재 가스 수치: {gas_level:4d} | 기준치: {THRESHOLD}", end="")
        if gas_level > THRESHOLD:
            print(" ➔ 🚨 가스 감지됨! ")
            buzzer.value = 0.5
            send_gas_alert()
        else:
            buzzer.value = 0.0
        time.sleep(0.5)
except KeyboardInterrupt:
    print("\n프로그램을 종료합니다.")
finally:
    spi.close()
    buzzer.value = 0.0
    buzzer.close()
