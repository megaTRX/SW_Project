from google import genai

# 본인의 API 키를 입력하세요
GEMINI_API_KEY = "AIzaSyC6Kl2eHXflS9K9mc700-crsWsfKbo_D6s"
client = genai.Client(api_key=GEMINI_API_KEY)

try:
    print("--- 연결 성공! 사용 가능한 모델 목록 ---")
    # 모든 모델의 '이름'만 출력합니다.
    for m in client.models.list():
        print(f"모델명: {m.name}")
    print("\n✅ 키가 정상이며 서버와 통신이 가능합니다.")
except Exception as e:
    print(f"\n❌ 에러 발생: {e}")
