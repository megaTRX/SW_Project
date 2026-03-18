import streamlit as st
import pandas as pd
from datetime import datetime
from mock_data import device_status, chat_logs, medications, schedules, emergency_logs

st.set_page_config(page_title="CareBot Admin", page_icon="🩺", layout="wide")

st.markdown("""
<style>
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap');
* { font-family: 'Inter', sans-serif; }
.block-container { padding: 2rem 3rem !important; max-width: 1400px !important; background: #f8fafc; }

.metric-card { background: white; border: 1px solid #e2e8f0; border-radius: 14px; padding: 20px 22px; margin-bottom: 12px; }
.metric-label { font-size: 12px; font-weight: 500; color: #94a3b8; text-transform: uppercase; letter-spacing: 0.06em; margin-bottom: 8px; }
.metric-value { font-size: 30px; font-weight: 700; color: #0f172a; line-height: 1; }
.metric-sub { font-size: 12px; margin-top: 6px; }
.metric-ok { color: #10b981; }
.metric-warn { color: #f59e0b; }
.metric-bad { color: #ef4444; }

.banner-red { background: #fef2f2; border: 1px solid #fecaca; border-left: 4px solid #ef4444; color: #991b1b; padding: 12px 16px; border-radius: 10px; font-size: 14px; font-weight: 500; margin-bottom: 8px; }
.banner-orange { background: #fffbeb; border: 1px solid #fde68a; border-left: 4px solid #f59e0b; color: #92400e; padding: 12px 16px; border-radius: 10px; font-size: 14px; margin-bottom: 8px; }
.banner-purple { background: #f5f3ff; border: 1px solid #ddd6fe; border-left: 4px solid #8b5cf6; color: #5b21b6; padding: 12px 16px; border-radius: 10px; font-size: 14px; margin-bottom: 8px; }

.sec-title { font-size: 15px; font-weight: 600; color: #0f172a; margin-bottom: 14px; margin-top: 4px; }
.list-item { display: flex; justify-content: space-between; align-items: center; background: white; border: 1px solid #e2e8f0; border-radius: 10px; padding: 13px 16px; margin-bottom: 7px; }
.list-left { font-size: 14px; color: #1e293b; font-weight: 500; }
.list-right { font-size: 13px; color: #64748b; }

.log-card { background: white; border: 1px solid #e2e8f0; border-radius: 12px; padding: 16px; margin-bottom: 8px; }
.log-meta { font-size: 12px; color: #94a3b8; margin-bottom: 8px; }
.log-user { font-size: 14px; color: #3b82f6; margin-bottom: 5px; }
.log-bot { font-size: 14px; color: #10b981; }

.badge { display: inline-block; padding: 3px 10px; border-radius: 20px; font-size: 11px; font-weight: 600; margin-left: 6px; }
.badge-생활정보 { background: #eff6ff; color: #3b82f6; }
.badge-복약 { background: #f0fdf4; color: #16a34a; }
.badge-일정 { background: #f5f3ff; color: #7c3aed; }
.badge-긴급 { background: #fef2f2; color: #dc2626; }

.status-ok { background: #f0fdf4; color: #16a34a; padding: 3px 12px; border-radius: 20px; font-size: 12px; font-weight: 600; }
.status-bad { background: #fef2f2; color: #dc2626; padding: 3px 12px; border-radius: 20px; font-size: 12px; font-weight: 600; }
.white-card { background: white; border: 1px solid #e2e8f0; border-radius: 14px; padding: 20px 22px; margin-bottom: 16px; }

/* 메뉴 버튼 스타일 */
div[data-testid="stHorizontalBlock"] .stButton > button {
    border-radius: 8px !important;
    font-size: 13px !important;
    font-weight: 500 !important;
    border: 1px solid #e2e8f0 !important;
    background: white !important;
    color: #64748b !important;
    padding: 10px 0px !important;
    width: 100% !important;
    transition: all 0.15s !important;
}
div[data-testid="stHorizontalBlock"] .stButton > button:hover {
    border-color: #6366f1 !important;
    color: #6366f1 !important;
    background: #f5f3ff !important;
}

.stProgress > div > div > div > div { background: linear-gradient(90deg, #6366f1, #8b5cf6) !important; }
hr { border-color: #e2e8f0 !important; }
.stDataFrame { border-radius: 12px !important; }
</style>
""", unsafe_allow_html=True)

# ===== 데이터 =====
status = device_status
logs = chat_logs
meds = medications
scheds = schedules
emergencies = emergency_logs

if "menu" not in st.session_state:
    st.session_state.menu = "대시보드"

active_emergencies = [e for e in emergencies if e["status"] == "처리 중"]
missed_meds = [m for m in meds if m["taken"] == "복용 전"]
now_hour = datetime.now().hour
hours_ago = 0
if logs:
    last_time = datetime.strptime(logs[-1]["time"], "%Y-%m-%d %H:%M")
    hours_ago = (datetime.now() - last_time).total_seconds() / 3600

# ===== 헤더 =====
c1, c2 = st.columns([3, 1])
with c1:
    st.markdown("""
        <div style='padding:20px 0 24px 0; border-bottom:1px solid #e2e8f0; margin-bottom:20px;'>
            <span style='font-size:26px;font-weight:800;
            background:linear-gradient(90deg,#4fc3f7,#6366f1);
            -webkit-background-clip:text;-webkit-text-fill-color:transparent;
            letter-spacing:-0.5px;'>🩺 CareBot Admin</span>
            <span style='font-size:13px;color:#94a3b8;margin-left:14px;'>노인 케어 챗봇 관리자 시스템</span>
        </div>
    """, unsafe_allow_html=True)
with c2:
    st.markdown(f"""
        <div style='text-align:right;color:#94a3b8;font-size:13px;padding-top:24px;'>
            🕐 {datetime.now().strftime('%Y-%m-%d %H:%M')}
        </div>
    """, unsafe_allow_html=True)
# ===== 메뉴 =====
menu_list = [
    ("📊", "대시보드"), ("💊", "복약 관리"), ("📅", "일정 관리"),
    ("💬", "대화 로그"), ("🖥", "장치 상태"), ("🚨", "긴급 호출")
]

cols = st.columns(6)
for i, (icon, label) in enumerate(menu_list):
    with cols[i]:
        active = st.session_state.menu == label
        btn_style = f"""
            <style>
            #btn_{i} button {{
                background: {'#6366f1' if active else 'white'} !important;
                color: {'white' if active else '#64748b'} !important;
                border: 1px solid {'#6366f1' if active else '#e2e8f0'} !important;
                font-weight: {'700' if active else '500'} !important;
                border-radius: 8px !important;
                width: 100% !important;
                padding: 10px !important;
                font-size: 13px !important;
                box-shadow: {'0 2px 8px rgba(99,102,241,0.3)' if active else 'none'} !important;
            }}
            </style>
            <div id="btn_{i}">
        """
        st.markdown(btn_style, unsafe_allow_html=True)
        if st.button(f"{icon} {label}", key=f"nav_{i}", use_container_width=True):
            st.session_state.menu = label
            st.rerun()
        st.markdown("</div>", unsafe_allow_html=True)
        
# ===== 주요 알림 + 오늘 일정 =====
alert_col, sched_col = st.columns([3, 2])

with alert_col:
    has_alert = active_emergencies or (missed_meds and now_hour >= 10) or hours_ago >= 3
    if has_alert:
        st.markdown('<div style="font-size:15px;font-weight:600;color:#0f172a;margin-bottom:10px;">🔔 주요 알림</div>', unsafe_allow_html=True)
        for e in active_emergencies:
            st.markdown(f'<div class="banner-red">🚨 <b>긴급상황 발생</b> &nbsp; {e["time"]} — {e["content"]}</div>', unsafe_allow_html=True)
        if missed_meds and now_hour >= 10:
            for m in missed_meds:
                st.markdown(f'<div class="banner-orange">⚠️ <b>복약 미완료</b> &nbsp; {m["name"]} ({m["time"]})</div>', unsafe_allow_html=True)
        if hours_ago >= 3:
            st.markdown(f'<div class="banner-purple">😶 <b>비활동 감지</b> &nbsp; 마지막 대화로부터 {int(hours_ago)}시간 경과</div>', unsafe_allow_html=True)

with sched_col:
    st.markdown('<div style="font-size:15px;font-weight:600;color:#0f172a;margin-bottom:10px;">📅 오늘 일정</div>', unsafe_allow_html=True)
    for item in scheds:
        icon = "✅" if item["status"] == "완료" else ("❌" if item["status"] == "취소" else "📌")
        st.markdown(f'<div class="list-item"><span class="list-left">{icon} {item["title"]}</span><span class="list-right">{item["time"]}</span></div>', unsafe_allow_html=True)

st.markdown("<div style='height:8px'></div>", unsafe_allow_html=True)

st.markdown("---")
menu = st.session_state.menu

# ===== 대시보드 =====
if menu == "대시보드":
    c1, c2, c3, c4, c5 = st.columns(5)
    cards = [
        (c1, "오늘 일정", f"{len(scheds)}건", "예정된 일정", "ok"),
        (c2, "복약 미완료", f"{len(missed_meds)}건", "확인 필요" if missed_meds else "모두 완료", "bad" if missed_meds else "ok"),
        (c3, "긴급 알림", f"{len(active_emergencies)}건", "처리 중" if active_emergencies else "이상 없음", "bad" if active_emergencies else "ok"),
        (c4, "CPU 사용률", f"{status['cpu']}%", "정상" if status['cpu'] < 80 else "높음", "ok" if status['cpu'] < 80 else "bad"),
        (c5, "메모리 사용률", f"{status['memory']}%", "정상" if status['memory'] < 80 else "높음", "ok" if status['memory'] < 80 else "bad"),
    ]
    
    for col, label, val, sub, state in cards:
        with col:
            st.markdown(f"""
                <div class="metric-card">
                    <div class="metric-label">{label}</div>
                    <div class="metric-value">{val}</div>
                    <div class="metric-sub metric-{state}">{sub}</div>
                </div>""", unsafe_allow_html=True)

    
    left, right = st.columns(2)

    with left:
        # 장치 연결 상태
        with st.container():
            st.markdown("""<div style='background:white;border:1px solid #e2e8f0;border-radius:14px;padding:20px 22px;margin-bottom:16px;'>
                <div style='font-size:15px;font-weight:600;color:#0f172a;margin-bottom:14px;'>🖥 장치 연결 상태</div></div>""", unsafe_allow_html=True)
            for label, val in [("마이크", status["mic"]), ("스피커", status["speaker"]), ("네트워크", status["network"])]:
                ok = val in ["정상", "연결됨"]
                badge = f'<span class="status-ok">🟢 {val}</span>' if ok else f'<span class="status-bad">🔴 {val}</span>'
                st.markdown(f'<div class="list-item"><span class="list-left">{label}</span>{badge}</div>', unsafe_allow_html=True)
            st.markdown(f'<div style="font-size:12px;color:#94a3b8;margin-top:10px;">🖥 {status["board"]} | 업데이트: {status["last_update"]}</div>', unsafe_allow_html=True)

        st.markdown("<div style='height:12px'></div>", unsafe_allow_html=True)

        # 복약 현황
        st.markdown(f"""
            <div style='background:white;border:1px solid #e2e8f0;border-radius:14px;padding:20px 22px;'>
                <div style='font-size:15px;font-weight:600;color:#0f172a;margin-bottom:14px;'>💊 복약 현황</div>
            </div>""", unsafe_allow_html=True)
        done_c = len([m for m in meds if m["taken"] == "복용 완료"])
        st.progress(done_c / len(meds) if meds else 0)
        st.markdown(f'<div style="font-size:12px;color:#94a3b8;margin:8px 0 12px;">완료 {done_c} / 전체 {len(meds)}개</div>', unsafe_allow_html=True)
        for m in meds:
            ok = m["taken"] == "복용 완료"
            color = "#10b981" if ok else "#ef4444"
            icon = "✅" if ok else "⏰"
            st.markdown(f'<div style="font-size:13px;color:{color};margin-bottom:6px;">{icon} {m["time"]} {m["name"]} — {m["taken"]}</div>', unsafe_allow_html=True)

    with right:
        # 오늘 일정
        st.markdown("""
            <div style='background:white;border:1px solid #e2e8f0;border-radius:14px;padding:20px 22px;margin-bottom:16px;'>
                <div style='font-size:15px;font-weight:600;color:#0f172a;margin-bottom:14px;'>📅 오늘 일정</div>
            </div>""", unsafe_allow_html=True)
        for item in scheds:
            icon = "✅" if item["status"] == "완료" else ("❌" if item["status"] == "취소" else "📌")
            st.markdown(f'<div class="list-item"><span class="list-left">{icon} {item["title"]}</span><span class="list-right">{item["time"]}</span></div>', unsafe_allow_html=True)

        st.markdown("<div style='height:12px'></div>", unsafe_allow_html=True)

        # 최근 대화
        st.markdown("""
            <div style='background:white;border:1px solid #e2e8f0;border-radius:14px;padding:20px 22px;margin-bottom:12px;'>
                <div style='font-size:15px;font-weight:600;color:#0f172a;margin-bottom:14px;'>💬 최근 대화</div>
            </div>""", unsafe_allow_html=True)
        for log in logs[-3:]:
            bc = f'badge-{log["type"]}'
            st.markdown(f"""
                <div class="log-card">
                    <div class="log-meta">🕐 {log['time']} <span class="badge {bc}">{log['type']}</span></div>
                    <div class="log-user">👴 {log['user']}</div>
                    <div class="log-bot">🤖 {log['bot']}</div>
                </div>""", unsafe_allow_html=True)

# ===== 복약 관리 =====
elif menu == "복약 관리":
    st.markdown('<div class="sec-title">💊 복약 관리</div>', unsafe_allow_html=True)
    done_c = len([m for m in meds if m["taken"] == "복용 완료"])
    st.progress(done_c / len(meds) if meds else 0)
    st.markdown(f'<div style="font-size:13px;color:#94a3b8;margin:6px 0 20px;">완료 {done_c} / 전체 {len(meds)}개</div>', unsafe_allow_html=True)

    with st.form("add_med"):
        st.markdown("**➕ 복약 추가**")
        c1, c2, c3 = st.columns(3)
        new_name = c1.text_input("약 이름")
        new_time = c2.text_input("복용 시간 (예: 10:00)")
        new_status = c3.selectbox("상태", ["복용 전", "복용 완료"])
        if st.form_submit_button("추가", use_container_width=True):
            if new_name and new_time:
                meds.append({"name": new_name, "time": new_time, "taken": new_status})
                st.success(f"'{new_name}' 추가됐어요!")
                st.rerun()

    st.markdown("---")
    st.dataframe(pd.DataFrame(meds), use_container_width=True)
    st.markdown("<br>", unsafe_allow_html=True)

    for i, med in enumerate(meds):
        ok = med["taken"] == "복용 완료"
        border = "#10b981" if ok else "#ef4444"
        icon = "✅" if ok else "⏰"
        c1, c2 = st.columns([5, 1])
        with c1:
            st.markdown(f"""
                <div style='padding:13px 16px;background:white;border:1px solid #e2e8f0;
                border-left:4px solid {border};border-radius:10px;margin-bottom:8px;'>
                    <span style='font-size:14px;color:#1e293b;'>{icon} <b>{med['name']}</b> &nbsp;|&nbsp; {med['time']} &nbsp;|&nbsp; <span style='color:{border};'>{med['taken']}</span></span>
                </div>""", unsafe_allow_html=True)
        with c2:
            if not ok:
                if st.button("✅ 완료", key=f"med_{i}", use_container_width=True):
                    meds[i]["taken"] = "복용 완료"
                    st.rerun()

# ===== 일정 관리 =====
elif menu == "일정 관리":
    st.markdown('<div class="sec-title">📅 일정 관리</div>', unsafe_allow_html=True)

    with st.form("add_sched"):
        st.markdown("**➕ 일정 추가**")
        c1, c2, c3 = st.columns(3)
        new_title = c1.text_input("일정명")
        new_time = c2.text_input("시간 (예: 15:00)")
        new_status = c3.selectbox("상태", ["예정", "완료", "취소"])
        if st.form_submit_button("추가", use_container_width=True):
            if new_title and new_time:
                scheds.append({"title": new_title, "time": new_time, "status": new_status})
                st.success(f"'{new_title}' 추가됐어요!")
                st.rerun()

    st.markdown("---")
    st.dataframe(pd.DataFrame(scheds), use_container_width=True)
    st.markdown("<br>", unsafe_allow_html=True)

    for item in scheds:
        icon = "✅" if item["status"] == "완료" else ("❌" if item["status"] == "취소" else "📌")
        border = "#10b981" if item["status"] == "완료" else ("#ef4444" if item["status"] == "취소" else "#6366f1")
        st.markdown(f"""
            <div style='padding:13px 16px;background:white;border:1px solid #e2e8f0;
            border-left:4px solid {border};border-radius:10px;margin-bottom:8px;'>
                <span style='font-size:14px;color:#1e293b;'>{icon} <b>{item['title']}</b> &nbsp;|&nbsp; {item['time']} &nbsp;|&nbsp; {item['status']}</span>
            </div>""", unsafe_allow_html=True)

# ===== 대화 로그 =====
elif menu == "대화 로그":
    st.markdown('<div class="sec-title">💬 대화 로그</div>', unsafe_allow_html=True)

    type_counts = {}
    for l in logs:
        type_counts[l["type"]] = type_counts.get(l["type"], 0) + 1
    colors = {"생활정보": "#3b82f6", "복약": "#10b981", "일정": "#8b5cf6", "긴급": "#ef4444"}

    cols = st.columns(len(type_counts))
    for i, (k, v) in enumerate(type_counts.items()):
        c = colors.get(k, "#94a3b8")
        with cols[i]:
            st.markdown(f"""
                <div style='background:white;border:1px solid #e2e8f0;border-top:3px solid {c};
                border-radius:10px;padding:14px 16px;text-align:center;margin-bottom:16px;'>
                    <div style='font-size:22px;font-weight:700;color:{c};'>{v}건</div>
                    <div style='font-size:12px;color:#94a3b8;margin-top:3px;'>{k}</div>
                </div>""", unsafe_allow_html=True)

    c1, c2 = st.columns(2)
    keyword = c1.text_input("🔍 검색어", placeholder="예: 약, 일정, 긴급")
    category = c2.selectbox("분류", ["전체", "생활정보", "복약", "일정", "긴급"])

    filtered = logs
    if keyword:
        filtered = [l for l in filtered if keyword in l["user"] or keyword in l["bot"]]
    if category != "전체":
        filtered = [l for l in filtered if l["type"] == category]

    st.markdown(f'<div style="font-size:13px;color:#94a3b8;margin-bottom:12px;">조회 결과: {len(filtered)}건</div>', unsafe_allow_html=True)

    for log in filtered:
        bc = f'badge-{log["type"]}'
        st.markdown(f"""
            <div class="log-card">
                <div class="log-meta">🕐 {log['time']} <span class="badge {bc}">{log['type']}</span></div>
                <div class="log-user">👴 {log['user']}</div>
                <div class="log-bot">🤖 {log['bot']}</div>
            </div>""", unsafe_allow_html=True)

# ===== 장치 상태 =====
elif menu == "장치 상태":
    st.markdown('<div class="sec-title">🖥 장치 상태 모니터링</div>', unsafe_allow_html=True)

    c1, c2 = st.columns(2)
    with c1:
        st.markdown('<div class="white-card">', unsafe_allow_html=True)
        st.markdown('<div class="sec-title">시스템 리소스</div>', unsafe_allow_html=True)
        for label, val in [("CPU 사용률", status["cpu"]), ("메모리 사용률", status["memory"])]:
            color = "#10b981" if val < 70 else ("#f59e0b" if val < 85 else "#ef4444")
            st.markdown(f"""
                <div style='margin-bottom:16px;'>
                    <div style='display:flex;justify-content:space-between;margin-bottom:6px;'>
                        <span style='font-size:13px;color:#64748b;'>{label}</span>
                        <span style='font-size:13px;font-weight:600;color:{color};'>{val}%</span>
                    </div>
                </div>""", unsafe_allow_html=True)
            st.progress(val / 100)
        st.markdown('</div>', unsafe_allow_html=True)

    with c2:
        st.markdown('<div class="white-card">', unsafe_allow_html=True)
        st.markdown('<div class="sec-title">장치 연결 상태</div>', unsafe_allow_html=True)
        for label, val in [("마이크", status["mic"]), ("스피커", status["speaker"]), ("네트워크", status["network"])]:
            ok = val in ["정상", "연결됨"]
            badge = f'<span class="status-ok">🟢 {val}</span>' if ok else f'<span class="status-bad">🔴 {val}</span>'
            st.markdown(f'<div class="list-item"><span class="list-left">{label}</span>{badge}</div>', unsafe_allow_html=True)
        st.markdown(f'<div style="font-size:12px;color:#94a3b8;margin-top:10px;">🖥 {status["board"]}<br>🕐 {status["last_update"]}</div>', unsafe_allow_html=True)
        st.markdown('</div>', unsafe_allow_html=True)

# ===== 긴급 호출 =====
elif menu == "긴급 호출":
    st.markdown('<div class="sec-title">🚨 긴급 호출 현황</div>', unsafe_allow_html=True)

    processing = [e for e in emergencies if e["status"] == "처리 중"]
    done_list = [e for e in emergencies if e["status"] == "처리 완료"]

    c1, c2 = st.columns(2)
    with c1:
        st.markdown(f"""
            <div style='background:white;border:1px solid #fecaca;border-top:3px solid #ef4444;
            border-radius:12px;padding:20px;text-align:center;margin-bottom:16px;'>
                <div style='font-size:28px;font-weight:700;color:#ef4444;'>{len(processing)}건</div>
                <div style='font-size:12px;color:#94a3b8;margin-top:4px;'>처리 중</div>
            </div>""", unsafe_allow_html=True)
    with c2:
        st.markdown(f"""
            <div style='background:white;border:1px solid #bbf7d0;border-top:3px solid #10b981;
            border-radius:12px;padding:20px;text-align:center;margin-bottom:16px;'>
                <div style='font-size:28px;font-weight:700;color:#10b981;'>{len(done_list)}건</div>
                <div style='font-size:12px;color:#94a3b8;margin-top:4px;'>처리 완료</div>
            </div>""", unsafe_allow_html=True)

    if processing:
        st.markdown("**🔴 처리 중인 긴급 상황**")
        for item in processing:
            c1, c2 = st.columns([5, 1])
            with c1:
                st.markdown(f"""
                    <div style='padding:14px 16px;background:white;border:1px solid #fecaca;
                    border-left:4px solid #ef4444;border-radius:10px;margin-bottom:8px;'>
                        <div style='font-size:12px;color:#ef4444;margin-bottom:4px;'>🚨 {item['time']}</div>
                        <div style='font-size:14px;color:#1e293b;font-weight:500;'>{item['content']}</div>
                    </div>""", unsafe_allow_html=True)
            with c2:
                if st.button("✅ 완료", key=f"done_{item['time']}", use_container_width=True):
                    item["status"] = "처리 완료"
                    st.rerun()

    if done_list:
        st.markdown("**🟢 처리 완료**")
        for item in done_list:
            st.markdown(f"""
                <div style='padding:13px 16px;background:white;border:1px solid #bbf7d0;
                border-left:4px solid #10b981;border-radius:10px;margin-bottom:8px;'>
                    <div style='font-size:12px;color:#10b981;margin-bottom:3px;'>✅ {item['time']}</div>
                    <div style='font-size:14px;color:#1e293b;'>{item['content']}</div>
                </div>""", unsafe_allow_html=True)