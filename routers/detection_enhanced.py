import cv2
import time
import requests
import logging
import logging.handlers
import numpy as np
from datetime import datetime
from dataclasses import dataclass, field
from typing import Optional


# ──────────────────────────────────────────
# 로깅 설정
# ──────────────────────────────────────────
def setup_logger():
    logger = logging.getLogger(__name__)
    logger.setLevel(logging.INFO)
    formatter = logging.Formatter('%(asctime)s [%(levelname)s] %(message)s')

    console_handler = logging.StreamHandler()
    console_handler.setFormatter(formatter)

    file_handler = logging.handlers.RotatingFileHandler(
        'detection.log', maxBytes=5 * 1024 * 1024, backupCount=3
    )
    file_handler.setFormatter(formatter)

    logger.addHandler(console_handler)
    logger.addHandler(file_handler)
    return logger


logger = setup_logger()


# ──────────────────────────────────────────
# 설정 데이터클래스
# ──────────────────────────────────────────
@dataclass
class DetectionConfig:
    """OASIS 노인 케어 통합 감지 설정"""

    # ── 움직임 / 비활동 ──
    motion_threshold: int = 500
    inactive_alert_seconds: int = 10       # 실사용: 1800 (30분)
    inactive_warning_seconds: int = 5      # 실사용: 600  (10분)
    alert_cooldown: int = 300              # 알림 재전송 대기 (5분)
    reconnect_delay: int = 5

    # ── 낙상 감지 ──
    # 배경 차분으로 얻은 전경 영역의 가로/세로 비율이
    # fall_ratio 이하이면 "넘어진 것"으로 판단
    fall_ratio: float = 0.55               # width/height < 0.55 → 수직 / > 1.8 → 수평(낙상)
    fall_min_area: int = 4000              # 낙상으로 인정할 최소 전경 면적
    fall_confirm_frames: int = 8           # 연속 N 프레임 이상 수평 자세여야 낙상 확정
    fall_cooldown: int = 60                # 낙상 알림 재전송 대기 (1분)

    # ── 재난 감지 (밝기 급변 → 화재/폭발/정전 추정) ──
    disaster_brightness_high: float = 220.0   # 이 이상 → 화재/폭발 의심
    disaster_brightness_low: float = 15.0     # 이 이하 → 정전 의심
    disaster_confirm_frames: int = 6          # 연속 N 프레임 지속 시 확정
    disaster_cooldown: int = 120

    # ── API ──
    api_url: str = "http://localhost:8000"
    camera_index: int = 0

    # ── 이미지 처리 ──
    blur_kernel: int = 5
    min_contour_area: int = 300


# ──────────────────────────────────────────
# 낙상 감지기
# ──────────────────────────────────────────
class FallDetector:
    """
    전경 마스크에서 가장 큰 윤곽의 Bounding Box 비율로 낙상 판단.
    가로 > 세로(수평 자세) 상태가 fall_confirm_frames 이상 지속되면 낙상으로 처리.
    """

    def __init__(self, config: DetectionConfig):
        self.cfg = config
        self._horizontal_count = 0
        self._last_alert_time: Optional[float] = None
        self.is_fallen = False

    def update(self, fgmask: np.ndarray) -> bool:
        """
        fgmask: 이진화된 전경 마스크 (uint8, 0/255)
        반환: 이번 프레임에 낙상 경보 발령 여부
        """
        contours, _ = cv2.findContours(
            fgmask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE
        )

        large = [c for c in contours if cv2.contourArea(c) > self.cfg.fall_min_area]

        if not large:
            self._horizontal_count = 0
            self.is_fallen = False
            return False

        # 가장 큰 전경 덩어리의 bounding box
        biggest = max(large, key=cv2.contourArea)
        x, y, w, h = cv2.boundingRect(biggest)

        if h == 0:
            return False

        ratio = w / h  # > 1.8 → 가로로 누운 자세

        if ratio > (1 / self.cfg.fall_ratio):   # 수평 자세
            self._horizontal_count += 1
        else:
            self._horizontal_count = max(0, self._horizontal_count - 1)
            if self._horizontal_count == 0:
                self.is_fallen = False

        if self._horizontal_count >= self.cfg.fall_confirm_frames:
            if not self.is_fallen:
                self.is_fallen = True
                return True   # 새로운 낙상 이벤트
        return False

    def cooldown_ok(self) -> bool:
        now = time.time()
        if self._last_alert_time is None:
            return True
        return (now - self._last_alert_time) >= self.cfg.fall_cooldown

    def mark_alerted(self):
        self._last_alert_time = time.time()


# ──────────────────────────────────────────
# 재난 감지기
# ──────────────────────────────────────────
class DisasterDetector:
    """
    프레임 평균 밝기를 이용한 화재/폭발(급격한 고밝기) 및 정전(급격한 저밝기) 감지.
    """

    def __init__(self, config: DetectionConfig):
        self.cfg = config
        self._high_count = 0
        self._low_count = 0
        self._last_alert_time: Optional[float] = None
        self.disaster_type: Optional[str] = None   # "화재" | "정전" | None

    def update(self, frame: np.ndarray) -> Optional[str]:
        """
        반환: 새 재난 이벤트 타입 문자열 또는 None
        """
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        mean_brightness = float(np.mean(gray))

        event = None

        # 화재/폭발 — 밝기 급증
        if mean_brightness >= self.cfg.disaster_brightness_high:
            self._high_count += 1
            self._low_count = 0
            if self._high_count >= self.cfg.disaster_confirm_frames:
                if self.disaster_type != "화재":
                    self.disaster_type = "화재"
                    event = "화재"
        # 정전 — 밝기 급감
        elif mean_brightness <= self.cfg.disaster_brightness_low:
            self._low_count += 1
            self._high_count = 0
            if self._low_count >= self.cfg.disaster_confirm_frames:
                if self.disaster_type != "정전":
                    self.disaster_type = "정전"
                    event = "정전"
        else:
            # 정상 범위 복귀
            self._high_count = max(0, self._high_count - 1)
            self._low_count = max(0, self._low_count - 1)
            if self._high_count == 0 and self._low_count == 0:
                self.disaster_type = None

        return event

    def cooldown_ok(self) -> bool:
        now = time.time()
        if self._last_alert_time is None:
            return True
        return (now - self._last_alert_time) >= self.cfg.disaster_cooldown

    def mark_alerted(self):
        self._last_alert_time = time.time()


# ──────────────────────────────────────────
# 노인 존재 감지 (단순 전경 면적 기반)
# ──────────────────────────────────────────
class ElderlyPresenceDetector:
    """
    전경 면적이 일정 임계값 이상이면 '노인 감지됨'으로 표시.
    실제 서비스에서는 YOLOv8/MediaPipe 등 딥러닝 모델로 교체 권장.
    """

    PRESENCE_AREA_THRESHOLD = 3000

    def __init__(self):
        self._present = False
        self._last_seen: Optional[float] = None
        self._absence_timeout = 30.0  # 30초 이상 전경 없으면 '자리 비움'

    def update(self, motion_area: int) -> bool:
        """반환: 현재 노인 존재 여부"""
        now = time.time()
        if motion_area >= self.PRESENCE_AREA_THRESHOLD:
            self._present = True
            self._last_seen = now
        elif self._last_seen is not None:
            if (now - self._last_seen) > self._absence_timeout:
                self._present = False
        return self._present


# ──────────────────────────────────────────
# 통합 감지기
# ──────────────────────────────────────────
class OASISDetector:
    """노인 케어 비활동 + 낙상 + 재난 + 존재 통합 감지 클래스"""

    def __init__(self, config: DetectionConfig):
        self.config = config
        self.cap: Optional[cv2.VideoCapture] = None

        # 배경 차분
        self.backsub = cv2.createBackgroundSubtractorMOG2(
            history=500, varThreshold=50, detectShadows=True
        )

        # 서브 감지기
        self.fall_detector = FallDetector(config)
        self.disaster_detector = DisasterDetector(config)
        self.presence_detector = ElderlyPresenceDetector()

        # 비활동 상태
        self.inactive_start: Optional[float] = None
        self.last_inactivity_alert: Optional[float] = None
        self.is_warning_sent = False
        self.is_alert_sent = False

        self.is_running = True

        # ── UI 상태 캐시 (draw_status 에서 사용) ──
        self._status = {
            "elderly_present": False,
            "motion_area": 0,
            "fall_detected": False,
            "disaster_type": None,
            "inactive_duration": None,
        }

    # ────────────────────────────────────────
    # 카메라
    # ────────────────────────────────────────
    def initialize_camera(self) -> bool:
        self.cap = cv2.VideoCapture(self.config.camera_index)
        if not self.cap.isOpened():
            logger.error("카메라를 열 수 없습니다.")
            return False
        self.cap.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
        self.cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)
        self.cap.set(cv2.CAP_PROP_FPS, 30)
        logger.info("카메라 초기화 완료")
        return True

    # ────────────────────────────────────────
    # 알림 전송
    # ────────────────────────────────────────
    def send_alert(self, alert_type: str, message: str,
                   cooldown_ref: Optional[list] = None,
                   cooldown_sec: int = 300):
        """FastAPI 백엔드에 알림 전송 (cooldown 적용)"""
        now = time.time()
        if cooldown_ref is not None and cooldown_ref[0] is not None:
            if (now - cooldown_ref[0]) < cooldown_sec:
                return
        try:
            payload = {
                "type": alert_type,
                "message": message,
                "is_resolved": False,
                "created_at": datetime.now().isoformat()
            }
            resp = requests.post(
                f"{self.config.api_url}/alert/", json=payload, timeout=5
            )
            if resp.status_code in [200, 201]:
                logger.info(f"[{alert_type}] 알림 전송 성공: {message}")
                if cooldown_ref is not None:
                    cooldown_ref[0] = now
            else:
                logger.error(f"알림 전송 실패: {resp.status_code}")
        except requests.exceptions.RequestException as e:
            logger.error(f"서버 연결 실패: {e}")

    # ────────────────────────────────────────
    # 움직임 감지
    # ────────────────────────────────────────
    def detect_motion(self, frame):
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        gray = cv2.GaussianBlur(
            gray, (self.config.blur_kernel, self.config.blur_kernel), 0
        )
        fgmask = self.backsub.apply(gray)
        _, fgmask = cv2.threshold(fgmask, 200, 255, cv2.THRESH_BINARY)

        kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (5, 5))
        fgmask = cv2.morphologyEx(fgmask, cv2.MORPH_OPEN, kernel)
        fgmask = cv2.morphologyEx(fgmask, cv2.MORPH_CLOSE, kernel)

        contours, _ = cv2.findContours(
            fgmask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE
        )
        valid = [c for c in contours if cv2.contourArea(c) > self.config.min_contour_area]
        motion_area = int(sum(cv2.contourArea(c) for c in valid))
        return motion_area, valid, fgmask

    # ────────────────────────────────────────
    # 비활동 처리
    # ────────────────────────────────────────
    def process_inactivity(self, motion_area: int) -> Optional[float]:
        now = time.time()
        _cooldown = [self.last_inactivity_alert]

        if motion_area < self.config.motion_threshold:
            if self.inactive_start is None:
                self.inactive_start = now
                self.is_warning_sent = False
                self.is_alert_sent = False
                logger.info("비활동 감지 시작")

            duration = now - self.inactive_start

            if duration >= self.config.inactive_warning_seconds and not self.is_warning_sent:
                self.send_alert(
                    "비활동",
                    f"비활동 경고: {int(duration // 60)}분 이상 움직임 없음",
                    _cooldown, self.config.alert_cooldown
                )
                self.is_warning_sent = True
                self.last_inactivity_alert = _cooldown[0]

            if duration >= self.config.inactive_alert_seconds and not self.is_alert_sent:
                self.send_alert(
                    "비활동",
                    f"비활동 경보: {int(duration // 60)}분 이상 — 즉시 확인 필요",
                    _cooldown, self.config.alert_cooldown
                )
                self.is_alert_sent = True
                self.last_inactivity_alert = _cooldown[0]

            return duration
        else:
            if self.inactive_start is not None:
                d = now - self.inactive_start
                logger.info(f"활동 재개 (비활동 시간: {d:.0f}초)")
                self.inactive_start = None
                self.is_warning_sent = False
                self.is_alert_sent = False
            return None

    # ────────────────────────────────────────
    # HUD 오버레이
    # ────────────────────────────────────────
    def draw_status(self, frame, fgmask):
        h, w = frame.shape[:2]
        s = self._status

        # 윤곽선 표시
        contours, _ = cv2.findContours(
            fgmask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE
        )
        cv2.drawContours(frame, contours, -1, (0, 255, 0), 2)

        # 상단 반투명 패널
        overlay = frame.copy()
        cv2.rectangle(overlay, (0, 0), (w, 150), (0, 0, 0), -1)
        cv2.addWeighted(overlay, 0.5, frame, 0.5, 0, frame)

        now_str = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        cv2.putText(frame, now_str, (10, 22),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.55, (200, 200, 200), 1)

        # ── 노인 감지 ──
        e_color = (0, 255, 100) if s["elderly_present"] else (100, 100, 100)
        e_text  = "노인감지: 감지됨" if s["elderly_present"] else "노인감지: 없음"
        cv2.putText(frame, e_text, (10, 50),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.65, e_color, 2)

        # ── 움직임 ──
        m_color = (0, 220, 255) if s["motion_area"] >= self.config.motion_threshold else (150, 150, 150)
        m_text  = f"움직임: {s['motion_area']} ({'정상' if s['motion_area'] >= self.config.motion_threshold else '없음'})"
        cv2.putText(frame, m_text, (10, 80),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.65, m_color, 2)

        # ── 낙상 감지 ──
        if s["fall_detected"]:
            f_color = (0, 0, 255)
            f_text  = "낙상감지: 낙상 확인됨!"
            cv2.rectangle(frame, (0, 0), (w - 1, h - 1), (0, 0, 255), 6)
        else:
            f_color = (0, 255, 150)
            f_text  = "낙상감지: 없음"
        cv2.putText(frame, f_text, (10, 110),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.65, f_color, 2)

        # ── 재난 감지 ──
        if s["disaster_type"]:
            d_color = (0, 100, 255)
            d_text  = f"재난감지: {s['disaster_type']} 의심!"
            cv2.rectangle(frame, (3, 3), (w - 3, h - 3), (0, 100, 255), 4)
        else:
            d_color = (0, 255, 150)
            d_text  = "재난감지: 정상"
        cv2.putText(frame, d_text, (10, 140),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.65, d_color, 2)

        # ── 비활동 경과 (우측 하단) ──
        if s["inactive_duration"] is not None:
            mins = int(s["inactive_duration"] // 60)
            secs = int(s["inactive_duration"] % 60)
            if s["inactive_duration"] >= self.config.inactive_alert_seconds:
                ia_color = (0, 0, 255)
                ia_text  = f"비활동 경보: {mins}m {secs}s"
            elif s["inactive_duration"] >= self.config.inactive_warning_seconds:
                ia_color = (0, 165, 255)
                ia_text  = f"비활동 경고: {mins}m {secs}s"
            else:
                ia_color = (0, 255, 255)
                ia_text  = f"비활동 모니터링: {mins}m {secs}s"
            cv2.putText(frame, ia_text, (10, h - 15),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.6, ia_color, 2)

        return frame

    # ────────────────────────────────────────
    # 메인 루프
    # ────────────────────────────────────────
    def run(self):
        logger.info("OASIS 통합 감지 시작")
        logger.info(f"비활동 경고: {self.config.inactive_warning_seconds}초 | "
                    f"경보: {self.config.inactive_alert_seconds}초")

        while self.is_running:
            if not self.initialize_camera():
                logger.error(f"카메라 재연결 {self.config.reconnect_delay}초 후 재시도...")
                time.sleep(self.config.reconnect_delay)
                continue

            try:
                while self.is_running:
                    ret, frame = self.cap.read()
                    if not ret:
                        logger.error("프레임 읽기 실패 - 재연결 시도")
                        self.cap.release()
                        time.sleep(self.config.reconnect_delay)
                        break

                    # ── 1. 움직임 감지 ──
                    motion_area, contours, fgmask = self.detect_motion(frame)

                    # ── 2. 노인 존재 여부 ──
                    elderly_present = self.presence_detector.update(motion_area)

                    # ── 3. 낙상 감지 ──
                    fall_event = self.fall_detector.update(fgmask)
                    if fall_event and self.fall_detector.cooldown_ok():
                        self.send_alert(
                            "낙상",
                            "낙상 감지됨 — 즉시 확인 필요!",
                        )
                        self.fall_detector.mark_alerted()
                        logger.error("낙상 경보 발송")

                    # ── 4. 재난 감지 ──
                    disaster_event = self.disaster_detector.update(frame)
                    if disaster_event and self.disaster_detector.cooldown_ok():
                        self.send_alert(
                            "재난",
                            f"{disaster_event} 감지됨 — 즉시 확인 필요!",
                        )
                        self.disaster_detector.mark_alerted()
                        logger.error(f"재난({disaster_event}) 경보 발송")

                    # ── 5. 비활동 감지 ──
                    inactive_duration = self.process_inactivity(motion_area)

                    # ── 상태 캐시 업데이트 ──
                    self._status.update({
                        "elderly_present": elderly_present,
                        "motion_area": motion_area,
                        "fall_detected": self.fall_detector.is_fallen,
                        "disaster_type": self.disaster_detector.disaster_type,
                        "inactive_duration": inactive_duration,
                    })

                    # ── 화면 표시 ──
                    display = self.draw_status(frame.copy(), fgmask)
                    cv2.imshow("OASIS - 노인 케어 통합 모니터링", display)
                    cv2.imshow("Motion Mask", fgmask)

                    if cv2.waitKey(1) & 0xFF == 27:
                        logger.info("사용자 종료 요청")
                        self.is_running = False
                        break

            except KeyboardInterrupt:
                logger.info("키보드 인터럽트로 종료")
                self.is_running = False

            except Exception as e:
                logger.error(f"예외 발생: {e} - {self.config.reconnect_delay}초 후 재시작")
                time.sleep(self.config.reconnect_delay)

        self.cleanup()

    def cleanup(self):
        if self.cap:
            self.cap.release()
        cv2.destroyAllWindows()
        logger.info("리소스 정리 완료")


# ──────────────────────────────────────────
# 엔트리포인트
# ──────────────────────────────────────────
if __name__ == "__main__":
    config = DetectionConfig(
        motion_threshold=500,
        inactive_alert_seconds=10,      # 실사용: 1800
        inactive_warning_seconds=5,     # 실사용: 600
        fall_ratio=0.55,
        fall_min_area=4000,
        fall_confirm_frames=8,
        disaster_brightness_high=220.0,
        disaster_brightness_low=15.0,
        disaster_confirm_frames=6,
        api_url="http://localhost:8000",
        camera_index=0
    )

    detector = OASISDetector(config)
    detector.run()
