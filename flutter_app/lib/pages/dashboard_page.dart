import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io'; // 플랫폼 확인용

// 모델 임포트 (경로가 맞는지 확인해주세요)
import '../models/log_item.dart';
// import '../models/medicine_model.dart'; // 만약 있다면 추가
// import '../models/alert_model.dart';    // 만약 있다면 추가

import '../widgets/banner_widget.dart';
import '../widgets/log_card.dart';

class DashboardPage extends StatefulWidget {
  final Function(int) onTabChange;
  const DashboardPage({super.key, required this.onTabChange});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // --- 상태 변수 ---
  String _temp = '--';
  String _weatherDesc = '불러오는 중...';
  String _weatherCity = '부산';
  IconData _weatherIcon = Icons.wb_sunny_rounded;

  List<Map<String, dynamic>> _alerts = [];
  List<LogItem> _dashboardLogs = [];
  
  // 메트릭 카운트용 (API 연동 전까지 초기값 0)
  int _todaySchedCount = 0;
  int _pendingMedCount = 0;
  double _medProgress = 0.0;
  String _medStatusText = "0 / 0 완료";

  bool _isLoading = true;

  // --- API 설정 ---
  // 에뮬레이터/시뮬레이터 환경에 따른 IP 자동 설정
  static String get _baseUrl {
    if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    return 'http://127.0.0.1:8000';
  }
  static const String _weatherApiKey = '693d75b2a15c1c6158bf4620d05f73e6';

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  // 모든 데이터를 한 번에 새로고침
  Future<void> _fetchAllData() async {
    if (mounted) setState(() => _isLoading = true);
    await Future.wait([
      _fetchWeather(),
      _fetchAlerts(),
      _fetchLogs(),
      _fetchMedicineStatus(),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchWeather() async {
    try {
      final res = await http.get(Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?q=Busan,KR&appid=$_weatherApiKey&units=metric&lang=kr',
      )).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final temp = (data['main']['temp'] as num).round();
        final weatherId = data['weather'][0]['id'] as int;

        IconData icon;
        if (weatherId < 300) icon = Icons.thunderstorm_rounded;
        else if (weatherId < 600) icon = Icons.umbrella_rounded;
        else if (weatherId < 700) icon = Icons.ac_unit_rounded;
        else if (weatherId == 800) icon = Icons.wb_sunny_rounded;
        else icon = Icons.cloud_rounded;

        if (mounted) {
          setState(() {
            _temp = '$temp°C';
            _weatherIcon = icon;
            _weatherDesc = '오늘도 건강한 하루 되세요 😊'; // 커스텀 메시지
          });
        }
      }
    } catch (e) {
      debugPrint('날씨 오류: $e');
    }
  }

  Future<void> _fetchAlerts() async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/alert/'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final List<dynamic> data = json.decode(res.body);
        if (mounted) {
          setState(() {
            _alerts = data
                .where((a) => a['is_resolved'] == false || a['is_resolved'] == 0)
                .map((a) => Map<String, dynamic>.from(a))
                .toList().reversed.take(3).toList();
          });
        }
      }
    } catch (e) {
      debugPrint('알림 오류: $e');
    }
  }

  Future<void> _fetchLogs() async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/schedule/'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final List<dynamic> data = json.decode(res.body);
        if (mounted) {
          setState(() {
            _dashboardLogs = data
                .map((e) => LogItem.fromJson(Map<String, dynamic>.from(e)))
                .toList().take(3).toList();
            _todaySchedCount = data.length;
          });
        }
      }
    } catch (e) {
      debugPrint('로그 오류: $e');
    }
  }

  Future<void> _fetchMedicineStatus() async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/medicine/'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final List<dynamic> data = json.decode(res.body);
        final total = data.length;
        final taken = data.where((m) => m['taken'] == true || m['taken'] == 1).length;
        
        if (mounted) {
          setState(() {
            _pendingMedCount = total - taken;
            _medProgress = total > 0 ? taken / total : 0.0;
            _medStatusText = "$taken / $total 완료";
          });
        }
      }
    } catch (e) {
      debugPrint('복약 오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = now.hour < 12 ? '좋은 아침이에요 ☀️' : now.hour < 18 ? '좋은 오후예요 🌤' : '좋은 저녁이에요 🌙';
    final emergencyAlerts = _alerts.where((a) => a['type'] == '긴급' || a['type'] == '비활동').toList();

    return RefreshIndicator(
      onRefresh: _fetchAllData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 환영 섹션
            _buildHeader(greeting, now),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. 주요 알림 섹션
                  if (_alerts.isNotEmpty) ...[
                    const Text('🔔 주요 알림', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    ..._alerts.map((alert) => _buildAlertBanner(alert)),
                    const SizedBox(height: 20),
                  ],

                  // 2. 메트릭 카드 섹션
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        _buildMetricItem('오늘 일정', '$_todaySchedCount건', '예정', const Color(0xFF6366F1), Icons.calendar_today_rounded, 2),
                        const SizedBox(width: 10),
                        _buildMetricItem('복약 미완료', '$_pendingMedCount건', '확인 필요', const Color(0xFFEF4444), Icons.medication_rounded, 1),
                        const SizedBox(width: 10),
                        _buildMetricItem('긴급 알림', '${emergencyAlerts.length}건', '처리 중', const Color(0xFFF59E0B), Icons.emergency_rounded, 4),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 3. 복약 현황 프로그레스
                  _buildMedicationProgress(),

                  const SizedBox(height: 24),

                  // 4. 날씨 및 장치 상태
                  _buildStatusRow(),

                  const SizedBox(height: 24),

                  // 5. 오늘 일정 리스트
                  _buildScheduleList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 위젯 빌더 함수들 (가독성을 위해 분리) ---

  Widget _buildHeader(String greeting, DateTime now) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0EA5E9), Color(0xFF6366F1)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(greeting, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 6),
          const Text('관리자님, 환영해요 👋', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('${now.year}년 ${now.month}월 ${now.day}일', style: const TextStyle(color: Colors.white60, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildAlertBanner(Map<String, dynamic> alert) {
    final bool isEmergency = alert['type'] == '긴급' || alert['type'] == '비활동';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => widget.onTabChange(isEmergency ? 4 : 1),
        child: BannerWidget(
          color: isEmergency ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB),
          borderColor: isEmergency ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
          icon: isEmergency ? Icons.emergency_rounded : Icons.warning_rounded,
          iconColor: isEmergency ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
          text: alert['message'] ?? '알림 내용 없음',
          textColor: isEmergency ? const Color(0xFF991B1B) : const Color(0xFF92400E),
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, String sub, Color color, IconData icon, int tabIndex) {
    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onTabChange(tabIndex),
        child: _MetricCard(label: label, value: value, sub: sub, color: color, icon: icon),
      ),
    );
  }

  Widget _buildMedicationProgress() {
    return GestureDetector(
      onTap: () => widget.onTabChange(1),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(children: [
                  Icon(Icons.medication_rounded, color: Color(0xFF6366F1), size: 16),
                  SizedBox(width: 6),
                  Text('💊 복약 현황', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                ]),
                Text(_medStatusText, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF6366F1))),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: _medProgress,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
              borderRadius: BorderRadius.circular(4), minHeight: 8,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF38BDF8)]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(_weatherIcon, color: Colors.white, size: 28),
                  const SizedBox(width: 8),
                  Text(_temp, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                ]),
                const SizedBox(height: 6),
                Text('$_weatherCity · 날씨', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                Text(_weatherDesc, style: const TextStyle(color: Colors.white60, fontSize: 11)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: _buildDeviceStatusCard(),
        ),
      ],
    );
  }

  Widget _buildDeviceStatusCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('장치 상태', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          _statusIcon(Icons.mic_rounded, "마이크"),
          _statusIcon(Icons.volume_up_rounded, "스피커"),
          _statusIcon(Icons.wifi_rounded, "네트워크"),
        ],
      ),
    );
  }

  Widget _statusIcon(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFF64748B)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 11)),
          const Spacer(),
          Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle)),
        ],
      ),
    );
  }

  Widget _buildScheduleList() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('📅 오늘 일정', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            GestureDetector(
              onTap: () => widget.onTabChange(2),
              child: const Text('전체 보기', style: TextStyle(fontSize: 13, color: Color(0xFF6366F1), fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_dashboardLogs.isEmpty && !_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text('오늘 예정된 일정이 없습니다.'),
          )
        else
          ..._dashboardLogs.map((e) => LogCard(log: e)),
      ],
    );
  }
}

// _MetricCard 위젯 (기존과 동일하되 가독성 유지)
class _MetricCard extends StatelessWidget {
  final String label, value, sub;
  final Color color;
  final IconData icon;

  const _MetricCard({required this.label, required this.value, required this.sub, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          Text(sub, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }
}