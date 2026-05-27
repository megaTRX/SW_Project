import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../main.dart';
import 'login_screen.dart';

const _guardianApiBase = 'http://172.27.153.182:8000';

class SeniorSelectScreen extends StatefulWidget {
  final int guardianId;
  const SeniorSelectScreen({super.key, required this.guardianId});

  @override
  State<SeniorSelectScreen> createState() => _SeniorSelectScreenState();
}

class _SeniorSelectScreenState extends State<SeniorSelectScreen> {
  List<Map<String, dynamic>> _seniors = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await http.get(
        Uri.parse('$_guardianApiBase/guardian/seniors?guardian_id=${widget.guardianId}'),
        headers: {
          if (AppState.accessToken != null) 'Authorization': 'Bearer ${AppState.accessToken}',
        },
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _seniors = data.cast<Map<String, dynamic>>();
            _loading = false;
          });
        }
      } else {
        if (mounted) setState(() { _error = '데이터를 불러올 수 없습니다'; _loading = false; });
      }
    } catch (_) {
      if (mounted) setState(() { _error = '서버에 연결할 수 없어요'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShaderMask(
                        shaderCallback: (b) => const LinearGradient(colors: [Color(0xFF4FC3F7), Color(0xFF6366F1)]).createShader(b),
                        child: const Text('OASIS', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${AppState.nickname ?? AppState.username ?? '보호자'}님, 어르신을 선택해주세요',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: Color(0xFF94A3B8)),
                    onPressed: _load,
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, color: Color(0xFF94A3B8)),
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
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.wifi_off_rounded, size: 52, color: Color(0xFFCBD5E1)),
                              const SizedBox(height: 12),
                              Text(_error!, style: const TextStyle(fontSize: 16, color: Color(0xFF64748B))),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _load,
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white),
                                child: const Text('다시 시도'),
                              ),
                            ],
                          ),
                        )
                      : _seniors.isEmpty
                          ? _buildEmpty()
                          : RefreshIndicator(
                              onRefresh: _load,
                              color: const Color(0xFF6366F1),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                                child: GridView.builder(
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 14,
                                    mainAxisSpacing: 14,
                                    childAspectRatio: 0.80,
                                  ),
                                  itemCount: _seniors.length,
                                  itemBuilder: (ctx, i) => _SeniorCard(
                                    data: _seniors[i],
                                    onTap: () => Navigator.of(ctx).push(
                                      MaterialPageRoute(builder: (_) => GuardianSeniorDetailPage(data: _seniors[i])),
                                    ).then((_) => _load()),
                                  ),
                                ),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88, height: 88,
            decoration: const BoxDecoration(color: Color(0xFFEEF2FF), shape: BoxShape.circle),
            child: const Icon(Icons.people_outline_rounded, size: 44, color: Color(0xFF6366F1)),
          ),
          const SizedBox(height: 16),
          const Text('연결된 어르신이 없습니다', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
          const SizedBox(height: 8),
          const Text('관리자에게 어르신 연결을 요청하세요', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
        ],
      ),
    );
  }
}

// ── 어르신 카드 ───────────────────────────────────────────────────

class _SeniorCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const _SeniorCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = data['status'] as String? ?? 'ok';
    final Color stripColor = _statusColor(status);
    final String statusEmoji = _statusEmoji(status);
    final String statusLabel = _statusLabel(status);

    final name = data['nickname'] as String? ?? '어르신';
    final label = data['label'] as String? ?? '';
    final medDone = (data['med_done'] as num?)?.toInt() ?? 0;
    final medTotal = (data['med_total'] as num?)?.toInt() ?? 0;
    final alertCount = (data['unresolved_alerts'] as num?)?.toInt() ?? 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 14, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            // Colored status strip
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: stripColor,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Avatar + name
                    Column(
                      children: [
                        Container(
                          width: 68, height: 68,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            shape: BoxShape.circle,
                            border: Border.all(color: stripColor.withOpacity(0.4), width: 2.5),
                          ),
                          child: Center(
                            child: Text(
                              name.isNotEmpty ? name[0] : '?',
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF6366F1)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                        if (label.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                        ],
                      ],
                    ),
                    // Med progress + status badge
                    Column(
                      children: [
                        if (medTotal > 0) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: medDone / medTotal,
                              backgroundColor: const Color(0xFFE2E8F0),
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                              minHeight: 5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('복약 $medDone/$medTotal', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                          const SizedBox(height: 6),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: stripColor.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            alertCount > 0 ? '$statusEmoji 알림 ${alertCount}건' : '$statusEmoji $statusLabel',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: stripColor),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String s) {
    if (s == 'danger') return const Color(0xFFEF4444);
    if (s == 'warning') return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  String _statusEmoji(String s) {
    if (s == 'danger') return '🔴';
    if (s == 'warning') return '🟡';
    return '🟢';
  }

  String _statusLabel(String s) {
    if (s == 'danger') return '위험';
    if (s == 'warning') return '주의';
    return '정상';
  }
}

// ── 보호자 어르신 상세 페이지 ────────────────────────────────────

class GuardianSeniorDetailPage extends StatelessWidget {
  final Map<String, dynamic> data;
  const GuardianSeniorDetailPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final status = data['status'] as String? ?? 'ok';
    final Color statusColor = _statusColor(status);
    final String statusLabel = _statusLabel(status);

    final name = data['nickname'] as String? ?? '어르신';
    final label = data['label'] as String? ?? '';
    final medDone = (data['med_done'] as num?)?.toInt() ?? 0;
    final medTotal = (data['med_total'] as num?)?.toInt() ?? 0;
    final alertCount = (data['unresolved_alerts'] as num?)?.toInt() ?? 0;
    final latestAlertType = data['latest_alert_type'] as String?;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar
              Container(
                color: Colors.white,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF1E293B)),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                          if (label.isNotEmpty)
                            Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(right: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(statusLabel, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: statusColor)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Avatar hero
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 92, height: 92,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        shape: BoxShape.circle,
                        border: Border.all(color: statusColor.withOpacity(0.5), width: 3),
                      ),
                      child: Center(
                        child: Text(
                          name.isNotEmpty ? name[0] : '?',
                          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Color(0xFF6366F1)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 10, height: 10, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text(statusLabel, style: TextStyle(fontSize: 15, color: statusColor, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Detail cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Medication card
                    _DetailCard(
                      icon: Icons.medication_rounded,
                      color: const Color(0xFF6366F1),
                      bg: const Color(0xFFEEF2FF),
                      title: '오늘의 복약',
                      content: medTotal == 0
                          ? const Text('오늘 복약 정보 없음', style: TextStyle(fontSize: 16, color: Color(0xFF64748B)))
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('$medDone / $medTotal 완료',
                                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF6366F1))),
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: medDone / medTotal,
                                    backgroundColor: const Color(0xFFE2E8F0),
                                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                                    minHeight: 10,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  medDone == medTotal ? '모든 복약 완료! 🎉' : '${medTotal - medDone}개 복약이 남았어요',
                                  style: const TextStyle(fontSize: 15, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 12),
                    // Alert card
                    _DetailCard(
                      icon: Icons.notifications_rounded,
                      color: alertCount > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                      bg: alertCount > 0 ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
                      title: '미해결 알림',
                      content: alertCount == 0
                          ? const Row(
                              children: [
                                Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 24),
                                SizedBox(width: 8),
                                Text('미해결 알림 없음', style: TextStyle(fontSize: 17, color: Color(0xFF10B981), fontWeight: FontWeight.w600)),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('$alertCount건', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Color(0xFFEF4444))),
                                if (latestAlertType != null) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF4444).withOpacity(0.10),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text('최근 알림: $latestAlertType',
                                        style: const TextStyle(fontSize: 15, color: Color(0xFFEF4444), fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ],
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String s) {
    if (s == 'danger') return const Color(0xFFEF4444);
    if (s == 'warning') return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  String _statusLabel(String s) {
    if (s == 'danger') return '위험 상태';
    if (s == 'warning') return '주의 필요';
    return '정상';
  }
}

class _DetailCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final String title;
  final Widget content;

  const _DetailCard({required this.icon, required this.color, required this.bg, required this.title, required this.content});

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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
            ],
          ),
          const SizedBox(height: 18),
          content,
        ],
      ),
    );
  }
}
