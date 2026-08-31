from picamera2 import Picamera2
from flask import Flask, Response
import cv2
import time
import threading

app = Flask(__name__)

picam2 = Picamera2()
config = picam2.create_video_configuration(
    main={"size": (320, 240)},
    controls={"FrameRate": 15}
)
picam2.configure(config)
picam2.start()

frame_lock = threading.Lock()
latest_frame = None

def capture_loop():
    global latest_frame
    while True:
        frame = picam2.capture_array()
        frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        _, buffer = cv2.imencode('.jpg', frame, [cv2.IMWRITE_JPEG_QUALITY, 60])
        with frame_lock:
            latest_frame = buffer.tobytes()
        time.sleep(1/15)

def generate_frames():
    while True:
        with frame_lock:
            if latest_frame is None:
                time.sleep(0.05)
                continue
            frame = latest_frame
        yield (b'--frame\r\nContent-Type: image/jpeg\r\n\r\n' + frame + b'\r\n')
        time.sleep(1/15)

@app.route('/video')
def video_feed():
    return Response(generate_frames(), mimetype='multipart/x-mixed-replace; boundary=frame')

@app.route('/')
def index():
    return '''<!DOCTYPE html>
<html><head>
<meta name="viewport" content="width=device-width,initial-scale=1">
<style>
*{margin:0;padding:0;box-sizing:border-box}
html,body{width:100%;height:100%;overflow:hidden;background:#000}
img{position:fixed;top:0;left:0;width:100%;height:100%;object-fit:fill}
</style></head>
<body><img src="/video"></body></html>'''

if __name__ == '__main__':
    t = threading.Thread(target=capture_loop, daemon=True)
    t.start()
    app.run(host='0.0.0.0', port=5000, debug=False, threaded=True)
