import 'package:flutter/material.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  bool _isConnected = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 카메라 화면
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: 260,
                color: const Color(0xFF0F172A),
                child: _isConnected
                    ? const Center(
                        child: Text('📷 실시간 영상 스트리밍',
                            style: TextStyle(color: Colors.white54, fontSize: 14)),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 64, height: 64,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(32),
                            ),
                            child: const Icon(Icons.videocam_off_rounded, color: Colors.white24, size: 32),
                          ),
                          const SizedBox(height: 14),
                          const Text('카메라 미연결',
                              style: TextStyle(color: Colors.white60, fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          const Text('임베디드 장치 연결 후 사용 가능합니다',
                              style: TextStyle(color: Colors.white30, fontSize: 12)),
                          const SizedBox(height: 20),
                          GestureDetector(
                            onTap: () => setState(() => _isConnected = !_isConnected),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('연결 테스트',
                                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      ),
              ),

              // 상단 상태 뱃지
              Positioned(
                top: 12, left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 7, height: 7,
                        decoration: BoxDecoration(
                          color: _isConnected ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isConnected ? 'LIVE' : 'OFFLINE',
                        style: TextStyle(
                          color: _isConnected ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 우상단 시간
              Positioned(
                top: 12, right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              // 하단 장치 정보
              Positioned(
                bottom: 12, left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('OASIS CAM · Raspberry Pi',
                      style: TextStyle(color: Colors.white54, fontSize: 11)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // 감지 현황 카드
                const Text('감지 현황',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(child: _DetectCard(
                      icon: Icons.accessibility_new_rounded,
                      iconBg: const Color(0xFFEFF6FF),
                      iconColor: const Color(0xFF6366F1),
                      label: '노인 감지',
                      value: '감지됨',
                      valueColor: const Color(0xFF10B981),
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: _DetectCard(
                      icon: Icons.directions_walk_rounded,
                      iconBg: const Color(0xFFEFF6FF),
                      iconColor: const Color(0xFF4FC3F7),
                      label: '움직임',
                      value: '정상',
                      valueColor: const Color(0xFF10B981),
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: _DetectCard(
                      icon: Icons.warning_amber_rounded,
                      iconBg: const Color(0xFFFFFBEB),
                      iconColor: const Color(0xFFF59E0B),
                      label: '낙상 감지',
                      value: '없음',
                      valueColor: const Color(0xFF94A3B8),
                    )),
                  ],
                ),

                const SizedBox(height: 24),

                // AI 분석 결과
                const Text('AI 분석 결과',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      _AIRow(label: '마지막 움직임 감지', value: '3분 전', icon: Icons.timer_rounded, color: const Color(0xFF10B981)),
                  const Divider(height: 20, color: Color(0xFFE2E8F0)),
                  _AIRow(label: '낙상 감지', value: '없음', icon: Icons.check_circle_rounded, color: const Color(0xFF10B981)),
                  const Divider(height: 20, color: Color(0xFFE2E8F0)),
                  _AIRow(label: '비활동 감지', value: '정상', icon: Icons.accessibility_new_rounded, color: const Color(0xFF10B981)),
                  const Divider(height: 20, color: Color(0xFFE2E8F0)),
                  _AIRow(label: '재난 감지', value: '정상', icon: Icons.local_fire_department_rounded, color: const Color(0xFF10B981)),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 최근 감지 기록
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('최근 감지 기록',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                    Text('전체 보기',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF6366F1), fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 12),

                ...[
                  {"time": "어제 22:15", "event": "비활동 감지", "detail": "1시간 이상 움직임 없음", "type": "warning"},
                  {"time": "3일 전 03:12", "event": "야간 이상 움직임", "detail": "새벽 3시 이상 움직임 감지", "type": "warning"},
                  {"time": "5일 전 14:20", "event": "낙상 감지", "detail": "안방에서 낙상 감지 — 즉시 확인됨", "type": "danger"},
                ].map((log) {

                  final isWarning = log["type"] == "warning";
                    final isDanger = log["type"] == "danger";
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDanger
                              ? const Color(0xFFFECACA)
                              : isWarning
                                  ? const Color(0xFFFDE68A)
                                  : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38, height: 38,
                            decoration: BoxDecoration(
                              color: isDanger
                                  ? const Color(0xFFFEF2F2)
                                  : isWarning
                                      ? const Color(0xFFFFFBEB)
                                      : const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isDanger
                                  ? Icons.emergency_rounded
                                  : isWarning
                                      ? Icons.warning_rounded
                                      : Icons.check_circle_rounded,
                              color: isDanger
                                  ? const Color(0xFFEF4444)
                                  : isWarning
                                      ? const Color(0xFFF59E0B)
                                      : const Color(0xFF6366F1),
                              size: 20,
                            ),
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(log["event"]!,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                              const SizedBox(height: 2),
                              Text(log["detail"]!,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                            ],
                          ),
                        ),
                        Text(log["time"]!,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===== 감지 카드 =====
class _DetectCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg, iconColor;
  final String label, value;
  final Color valueColor;

  const _DetectCard({
    required this.icon, required this.iconBg, required this.iconColor,
    required this.label, required this.value, required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: valueColor)),
        ],
      ),
    );
  }
}

// ===== AI 분석 행 =====
class _AIRow extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;

  const _AIRow({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
      ],
    );
  }
}