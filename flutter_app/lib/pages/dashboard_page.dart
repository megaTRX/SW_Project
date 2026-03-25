import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../widgets/banner_widget.dart';
import '../widgets/log_card.dart';

class DashboardPage extends StatelessWidget {
  final Function(int) onTabChange;
  const DashboardPage({super.key, required this.onTabChange});

  @override
  Widget build(BuildContext context) {
    final emergencies = mockEmergencies.where((e) => e["status"] == "처리 중").toList();
    final missedMeds = mockMeds.where((m) => m["taken"] == false).toList();
    final now = DateTime.now();
    final greeting = now.hour < 12 ? '좋은 아침이에요 ☀️' : now.hour < 18 ? '좋은 오후예요 🌤' : '좋은 저녁이에요 🌙';

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // 상단 헤더
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0EA5E9), Color(0xFF6366F1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 6),
                const Text('관리자님, 환영해요 👋',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('${now.year}년 ${now.month}월 ${now.day}일',
                    style: const TextStyle(color: Colors.white60, fontSize: 13)),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // 주요 알림
                if (emergencies.isNotEmpty || missedMeds.isNotEmpty) ...[
                  const Text('🔔 주요 알림',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                  const SizedBox(height: 10),
                  if (emergencies.isNotEmpty)
                    GestureDetector(
                      onTap: () => onTabChange(4),
                      child: BannerWidget(
                        color: const Color(0xFFFEF2F2),
                        borderColor: const Color(0xFFEF4444),
                        icon: Icons.emergency_rounded,
                        iconColor: const Color(0xFFEF4444),
                        text: '긴급상황 발생 — ${emergencies.first["content"]}',
                        textColor: const Color(0xFF991B1B),
                      ),
                    ),
                  if (missedMeds.isNotEmpty)
                    GestureDetector(
                      onTap: () => onTabChange(1),
                      child: BannerWidget(
                        color: const Color(0xFFFFFBEB),
                        borderColor: const Color(0xFFF59E0B),
                        icon: Icons.warning_rounded,
                        iconColor: const Color(0xFFF59E0B),
                        text: '복약 미완료 — ${missedMeds.map((m) => m["name"]).join(", ")}',
                        textColor: const Color(0xFF92400E),
                      ),
                    ),
                  const SizedBox(height: 20),
                ],

                // 메트릭 카드
                IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => onTabChange(2),
                          child: _MetricCard(
                            label: '오늘 일정',
                            value: '${mockScheds.length}건',
                            sub: '예정',
                            color: const Color(0xFF6366F1),
                            icon: Icons.calendar_today_rounded,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => onTabChange(1),
                          child: _MetricCard(
                            label: '복약 미완료',
                            value: '${missedMeds.length}건',
                            sub: '확인 필요',
                            color: const Color(0xFFEF4444),
                            icon: Icons.medication_rounded,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => onTabChange(4),
                          child: _MetricCard(
                            label: '긴급 알림',
                            value: '${emergencies.length}건',
                            sub: '처리 중',
                            color: const Color(0xFFF59E0B),
                            icon: Icons.emergency_rounded,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 복약 현황
                GestureDetector(
                  onTap: () => onTabChange(1),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.medication_rounded, color: Color(0xFF6366F1), size: 16),
                                SizedBox(width: 6),
                                Text('💊 복약 현황',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                              ],
                            ),
                            Text(
                              '${mockMeds.where((m) => m["taken"] == true).length} / ${mockMeds.length} 완료',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF6366F1)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        LinearProgressIndicator(
                          value: mockMeds.isEmpty ? 0 : mockMeds.where((m) => m["taken"] == true).length / mockMeds.length,
                          backgroundColor: const Color(0xFFE2E8F0),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                          borderRadius: BorderRadius.circular(4),
                          minHeight: 8,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 날씨 + 장치 상태
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.wb_sunny_rounded, color: Colors.white, size: 28),
                                const SizedBox(width: 8),
                                const Text('22°C',
                                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text('맑음 · 부산',
                                style: TextStyle(color: Colors.white70, fontSize: 12)),
                            const SizedBox(height: 4),
                            const Text('산책하기 좋은 날씨예요 😊',
                                style: TextStyle(color: Colors.white60, fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('장치 상태',
                                style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                            const SizedBox(height: 10),
                            ...["mic", "speaker", "network"].map((key) {
                              final labels = {"mic": "마이크", "speaker": "스피커", "network": "네트워크"};
                              final icons = {
                                "mic": Icons.mic_rounded,
                                "speaker": Icons.volume_up_rounded,
                                "network": Icons.wifi_rounded
                              };
                              final val = mockStatus[key] as String;
                              final ok = val == "정상" || val == "연결됨";
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Icon(icons[key], size: 14,
                                        color: ok ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(labels[key]!,
                                          style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B))),
                                    ),
                                    Container(
                                      width: 7, height: 7,
                                      decoration: BoxDecoration(
                                        color: ok ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 오늘 일정
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('📅 오늘 일정',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                    GestureDetector(
                      onTap: () => onTabChange(2),
                      child: const Text('전체 보기',
                          style: TextStyle(fontSize: 13, color: Color(0xFF6366F1), fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...mockScheds.map((s) => GestureDetector(
                  onTap: () => onTabChange(2),
                  child: _ListItem(
                    title: s["title"] as String,
                    subtitle: s["time"] as String,
                    icon: Icons.calendar_today_rounded,
                    iconColor: const Color(0xFF6366F1),
                    status: s["status"] as String,
                  ),
                )),

                const SizedBox(height: 24),


              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===== 메트릭 카드 =====
class _MetricCard extends StatelessWidget {
  final String label, value, sub;
  final Color color;
  final IconData icon;

  const _MetricCard({
    required this.label, required this.value,
    required this.sub, required this.color, required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color)),
          Text(sub, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }
}

// ===== 리스트 아이템 =====
class _ListItem extends StatelessWidget {
  final String title, subtitle, status;
  final IconData icon;
  final Color iconColor;

  const _ListItem({
    required this.title, required this.subtitle,
    required this.icon, required this.iconColor, required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: status == "완료" ? const Color(0xFFF0FDF4) : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(status,
                style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600,
                  color: status == "완료" ? const Color(0xFF10B981) : const Color(0xFF6366F1),
                )),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 18),
        ],
      ),
    );
  }
}