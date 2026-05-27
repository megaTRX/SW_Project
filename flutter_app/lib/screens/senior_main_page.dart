import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/api_service.dart';
import '../pages/med_page.dart';
import '../main.dart';
import 'login_screen.dart';

const _seniorBaseUrl = 'http://172.27.153.182:8000';

class SeniorMainPage extends StatefulWidget {
  const SeniorMainPage({super.key});

  @override
  State<SeniorMainPage> createState() => _SeniorMainPageState();
}

class _SeniorMainPageState extends State<SeniorMainPage> {
  int _tab = 0;
  bool _simpleMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: IndexedStack(
        index: _tab,
        children: [
          _SeniorHomeTab(
            simpleMode: _simpleMode,
            onToggleMode: () => setState(() => _simpleMode = !_simpleMode),
          ),
          const _SeniorMedTab(),
          const _EmergencyTab(),
        ],
      ),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _NavBtn(icon: Icons.home_rounded, label: '홈', active: _tab == 0, onTap: () => setState(() => _tab = 0)),
            _NavBtn(icon: Icons.medication_rounded, label: '복약', active: _tab == 1, onTap: () => setState(() => _tab = 1)),
            _NavBtn(icon: Icons.warning_amber_rounded, label: '긴급', active: _tab == 2, onTap: () => setState(() => _tab = 2), danger: true),
          ],
        ),
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final bool danger;

  const _NavBtn({required this.icon, required this.label, required this.active, required this.onTap, this.danger = false});

  @override
  Widget build(BuildContext context) {
    final activeColor = danger ? const Color(0xFFEF4444) : const Color(0xFF6366F1);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 30, color: active ? activeColor : const Color(0xFF94A3B8)),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 14, fontWeight: active ? FontWeight.w700 : FontWeight.w500, color: active ? activeColor : const Color(0xFF94A3B8))),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 홈 탭 ─────────────────────────────────────────────────────────

class _SeniorHomeTab extends StatefulWidget {
  final bool simpleMode;
  final VoidCallback onToggleMode;

  const _SeniorHomeTab({required this.simpleMode, required this.onToggleMode});

  @override
  State<_SeniorHomeTab> createState() => _SeniorHomeTabState();
}

class _SeniorHomeTabState extends State<_SeniorHomeTab> {
  List<Map> _meds = [];
  List<Map> _scheds = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final meds = await ApiService.getMedications();
    final scheds = await ApiService.getSchedules();
    if (mounted) {
      setState(() {
        _meds = meds;
        _scheds = scheds;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final medDone = _meds.where((m) => m['taken'] == true).length;
    final medTotal = _meds.length;
    final todayScheds = _scheds.where((s) {
      final t = s['time']?.toString() ?? '';
      return t.startsWith(todayStr) || (!t.contains('-') && !t.contains('202'));
    }).toList();
    final name = AppState.nickname ?? AppState.username ?? '어르신';

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        color: const Color(0xFF6366F1),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AppBar area
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
                child: Row(
                  children: [
                    ShaderMask(
                      shaderCallback: (b) => const LinearGradient(colors: [Color(0xFF4FC3F7), Color(0xFF6366F1)]).createShader(b),
                      child: const Text('OASIS', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2)),
                    ),
                    const Spacer(),
                    _ModeToggleChip(simpleMode: widget.simpleMode, onToggle: widget.onToggleMode),
                    IconButton(
                      icon: const Icon(Icons.logout_rounded, color: Color(0xFF94A3B8), size: 22),
                      onPressed: () {
                        AppState.accessToken = null;
                        AppState.username = null;
                        AppState.nickname = null;
                        AppState.role = '';
                        AppState.userId = 0;
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (r) => false,
                        );
                      },
                    ),
                  ],
                ),
              ),
              // Greeting section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '안녕하세요,\n$name님!',
                      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Color(0xFF1E293B), height: 1.3),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${now.year}년 ${now.month}월 ${now.day}일 ${_weekdayStr(now.weekday)}',
                      style: const TextStyle(fontSize: 17, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (_loading)
                const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: Color(0xFF6366F1))))
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // Med summary card
                      _SumCard(
                        icon: Icons.medication_rounded,
                        color: const Color(0xFF6366F1),
                        bgColor: const Color(0xFFEEF2FF),
                        title: '오늘의 복약',
                        value: medTotal == 0 ? '등록된 복약 없음' : '$medDone / $medTotal 완료',
                        subtitle: medTotal == 0
                            ? '복약 탭에서 약을 추가하세요'
                            : (medDone == medTotal ? '오늘 복약을 모두 완료했어요! 🎉' : '${medTotal - medDone}개가 남았어요'),
                        progress: medTotal > 0 ? medDone / medTotal : null,
                      ),
                      // Schedule summary (hidden in simple mode)
                      if (!widget.simpleMode) ...[
                        const SizedBox(height: 12),
                        _SumCard(
                          icon: Icons.calendar_today_rounded,
                          color: const Color(0xFF0EA5E9),
                          bgColor: const Color(0xFFEFF6FF),
                          title: '오늘의 일정',
                          value: todayScheds.isEmpty ? '오늘 일정 없음' : '${todayScheds.length}개 예정',
                          subtitle: todayScheds.isEmpty
                              ? '좋은 하루 되세요!'
                              : todayScheds.take(2).map((s) => s['title'] as String? ?? '').join(', '),
                        ),
                      ],
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _weekdayStr(int d) => ['월', '화', '수', '목', '금', '토', '일'][d - 1] + '요일';
}

class _ModeToggleChip extends StatelessWidget {
  final bool simpleMode;
  final VoidCallback onToggle;

  const _ModeToggleChip({required this.simpleMode, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: simpleMode ? const Color(0xFF6366F1) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(simpleMode ? Icons.view_compact_rounded : Icons.view_agenda_rounded,
                size: 14, color: simpleMode ? Colors.white : const Color(0xFF64748B)),
            const SizedBox(width: 4),
            Text(
              simpleMode ? '간편 모드' : '일반 모드',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: simpleMode ? Colors.white : const Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SumCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String title;
  final String value;
  final String subtitle;
  final double? progress;

  const _SumCard({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.title,
    required this.value,
    required this.subtitle,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 15, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
                    const SizedBox(height: 3),
                    Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
                  ],
                ),
              ),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 10,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(subtitle, style: const TextStyle(fontSize: 15, color: Color(0xFF64748B))),
        ],
      ),
    );
  }
}

// ── 복약 탭 ──────────────────────────────────────────────────────

class _SeniorMedTab extends StatelessWidget {
  const _SeniorMedTab();

  @override
  Widget build(BuildContext context) {
    return const SafeArea(bottom: false, child: MedPage());
  }
}

// ── 긴급 탭 ──────────────────────────────────────────────────────

class _EmergencyTab extends StatefulWidget {
  const _EmergencyTab();

  @override
  State<_EmergencyTab> createState() => _EmergencyTabState();
}

class _EmergencyTabState extends State<_EmergencyTab> {
  bool _sending = false;
  List<Map> _alerts = [];

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    final alerts = await ApiService.getAlerts();
    if (mounted) {
      setState(() => _alerts = alerts.where((a) => a['status'] == '처리 중').toList());
    }
  }

  Future<void> _sendSOS() async {
    setState(() => _sending = true);
    try {
      await http.post(
        Uri.parse('$_seniorBaseUrl/alert/'),
        headers: {
          'Content-Type': 'application/json',
          if (AppState.accessToken != null) 'Authorization': 'Bearer ${AppState.accessToken}',
        },
        body: jsonEncode({'type': '긴급', 'message': '어르신이 긴급 도움을 요청했습니다.'}),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('긴급 신호를 보호자에게 전송했습니다.'), backgroundColor: Color(0xFFEF4444)),
        );
        _loadAlerts();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('전송에 실패했습니다. 다시 시도해주세요.'), backgroundColor: Colors.orange),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showConfirmDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('긴급 신호 전송', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        content: const Text('보호자에게 긴급 알림을 전송할까요?', style: TextStyle(fontSize: 17)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소', style: TextStyle(fontSize: 16, color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _sendSOS();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            child: const Text('전송', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('긴급 도움 요청', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                  SizedBox(height: 6),
                  Text('버튼을 누르면 보호자에게 즉시 알림이 전송됩니다.', style: TextStyle(fontSize: 16, color: Color(0xFF64748B))),
                ],
              ),
            ),
            const SizedBox(height: 28),
            // SOS button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 130,
                child: ElevatedButton(
                  onPressed: _sending ? null : _showConfirmDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFEF4444).withOpacity(0.6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    elevation: 6,
                    shadowColor: const Color(0xFFEF4444).withOpacity(0.4),
                  ),
                  child: _sending
                      ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.sos_rounded, size: 52),
                            SizedBox(height: 8),
                            Text('긴급 신호 보내기', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 1)),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Alert type quick buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(child: _AlertTypeCard(icon: Icons.local_fire_department_rounded, label: '가스 위험', color: const Color(0xFFFF9500))),
                  const SizedBox(width: 12),
                  Expanded(child: _AlertTypeCard(icon: Icons.person_off_rounded, label: '낙상 감지', color: const Color(0xFF6366F1))),
                  const SizedBox(width: 12),
                  Expanded(child: _AlertTypeCard(icon: Icons.warning_rounded, label: '재난', color: const Color(0xFFEF4444))),
                ],
              ),
            ),
            if (_alerts.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text('미해결 알림', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
              ),
              const SizedBox(height: 12),
              ..._alerts.take(5).map((a) => Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 22),
                          const SizedBox(width: 10),
                          Expanded(child: Text(a['content'] ?? '', style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B)))),
                          Text(a['type'] ?? '', style: const TextStyle(fontSize: 13, color: Color(0xFFEF4444), fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  )),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _AlertTypeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _AlertTypeCard({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
        ],
      ),
    );
  }
}
