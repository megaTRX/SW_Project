import 'dart:async';
import 'package:flutter/material.dart';
import '../data/api_service.dart';

class LogPage extends StatefulWidget {
  const LogPage({super.key});

  @override
  State<LogPage> createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ── 대화 기록 ──────────────────────────────────────────────────────────────
  final TextEditingController _searchController = TextEditingController();
  String _keyword = '';
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;

  // ── 감지 알림 ──────────────────────────────────────────────────────────────
  List<Map> _alerts = [];
  bool _alertLoading = true;
  String _alertFilter = '전체'; // 전체 / 비활동 / 가스
  int _unresolvedCount = 0;

  Timer? _chatTimer;
  Timer? _alertTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLogs();
    _loadAlerts();
    _chatTimer = Timer.periodic(const Duration(seconds: 10), (_) => _loadLogs(showLoading: false));
    _alertTimer = Timer.periodic(const Duration(seconds: 15), (_) => _loadAlerts(showLoading: false));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chatTimer?.cancel();
    _alertTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // ── 데이터 로드 ─────────────────────────────────────────────────────────────
  Future<void> _loadLogs({bool showLoading = true}) async {
    if (showLoading && mounted) setState(() => _isLoading = true);
    try {
      final data = await ApiService.getChatLogs();
      if (!mounted) return;
      setState(() {
        _logs = data.map((e) => Map<String, dynamic>.from(e)).toList();
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAlerts({bool showLoading = true}) async {
    if (showLoading && mounted) setState(() => _alertLoading = true);
    try {
      final data = await ApiService.getAlerts();
      if (!mounted) return;
      final filtered = data.where((a) {
        final t = (a["type"] ?? '') as String;
        return t == '비활동' || t == '가스';
      }).toList();
      setState(() {
        _alerts = filtered;
        _unresolvedCount = filtered.where((a) => a["status"] == "처리 중").length;
        _alertLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _alertLoading = false);
    }
  }

  Future<void> _resolveAlert(int id) async {
    final ok = await ApiService.resolveAlert(id);
    if (!ok || !mounted) return;
    setState(() {
      final idx = _alerts.indexWhere((a) => a["id"] == id);
      if (idx != -1) _alerts[idx] = {..._alerts[idx], "status": "처리 완료"};
      _unresolvedCount = _alerts.where((a) => a["status"] == "처리 중").length;
    });
  }

  // ── 필터 ────────────────────────────────────────────────────────────────────
  List<Map> get _filteredAlerts {
    if (_alertFilter == '전체') return _alerts;
    return _alerts.where((a) => a["type"] == _alertFilter).toList();
  }

  Map<String, List<Map<String, dynamic>>> _groupByDate(List<Map<String, dynamic>> logs) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final log in logs) {
      final time = (log["time"] ?? '').toString();
      String dateKey = '날짜 없음';
      if (time.length >= 10) {
        final date = DateTime.tryParse(time);
        dateKey = date != null
            ? '${date.year}년 ${date.month}월 ${date.day}일'
            : time.substring(0, 10);
      }
      grouped.putIfAbsent(dateKey, () => []).add(log);
    }
    return grouped;
  }

  // ── BUILD ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── 헤더 ──────────────────────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
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
              const Text('기록', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Text('활동 로그',
                      style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  if (_unresolvedCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('미해결 $_unresolvedCount건',
                          style: const TextStyle(color: Colors.white, fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              // ── 탭바 ──────────────────────────────────────────────────────
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white54,
                labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                tabs: [
                  const Tab(text: '대화 기록'),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('감지 알림'),
                        if (_unresolvedCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 18, height: 18,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text('$_unresolvedCount',
                                  style: const TextStyle(color: Colors.white,
                                      fontSize: 10, fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── 탭 뷰 ──────────────────────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildChatTab(),
              _buildAlertTab(),
            ],
          ),
        ),
      ],
    );
  }

  // ── 대화 기록 탭 ─────────────────────────────────────────────────────────────
  Widget _buildChatTab() {
    final filtered = _logs.where((l) {
      final userText = (l["user"] ?? '').toString();
      final botText = (l["bot"] ?? '').toString();
      return _keyword.isEmpty || userText.contains(_keyword) || botText.contains(_keyword);
    }).toList();
    final grouped = _groupByDate(filtered);
    final dateKeys = grouped.keys.toList();

    return RefreshIndicator(
      onRefresh: () => _loadLogs(showLoading: false),
      color: const Color(0xFF6366F1),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _keyword = v),
              decoration: InputDecoration(
                hintText: '대화 내용 검색...',
                hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8)),
                suffixIcon: _keyword.isNotEmpty
                    ? GestureDetector(
                        onTap: () { _searchController.clear(); setState(() => _keyword = ''); },
                        child: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2)),
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: Color(0xFF6366F1))))
            else if (filtered.isEmpty)
              const Center(child: Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Column(children: [
                  Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFFCBD5E1), size: 48),
                  SizedBox(height: 12),
                  Text('대화 내용이 없어요', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 15)),
                ]),
              ))
            else
              ...dateKeys.map((dateKey) {
                final dayLogs = grouped[dateKey]!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 10),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(dateKey,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                                  color: Color(0xFF6366F1))),
                        ),
                        const SizedBox(width: 8),
                        Text('${dayLogs.length}개',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                      ]),
                    ),
                    ...dayLogs.map((l) => _ChatBubbleCard(log: l)),
                    const SizedBox(height: 8),
                  ],
                );
              }),
          ],
        ),
      ),
    );
  }

  // ── 감지 알림 탭 ─────────────────────────────────────────────────────────────
  Widget _buildAlertTab() {
    final items = _filteredAlerts;
    final filters = ['전체', '비활동', '가스'];

    return RefreshIndicator(
      onRefresh: () => _loadAlerts(showLoading: false),
      color: const Color(0xFF6366F1),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 필터 칩 ──────────────────────────────────────────────────────
            Row(
              children: filters.map((f) {
                final isSelected = _alertFilter == f;
                final count = f == '전체'
                    ? _alerts.length
                    : _alerts.where((a) => a["type"] == f).length;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _alertFilter = f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF6366F1) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Text('$f ($count)',
                          style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : const Color(0xFF64748B),
                          )),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // ── 요약 카드 ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  _AlertStat(
                    label: '전체',
                    value: _alerts.length,
                    color: const Color(0xFF6366F1),
                  ),
                  _vertDiv(),
                  _AlertStat(
                    label: '비활동',
                    value: _alerts.where((a) => a["type"] == "비활동").length,
                    color: const Color(0xFFEF4444),
                  ),
                  _vertDiv(),
                  _AlertStat(
                    label: '가스',
                    value: _alerts.where((a) => a["type"] == "가스").length,
                    color: const Color(0xFFF97316),
                  ),
                  _vertDiv(),
                  _AlertStat(
                    label: '미해결',
                    value: _unresolvedCount,
                    color: _unresolvedCount > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── 알림 리스트 ────────────────────────────────────────────────
            if (_alertLoading)
              const Center(child: Padding(padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: Color(0xFF6366F1))))
            else if (items.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 48),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Column(children: [
                  Icon(Icons.shield_rounded, color: Color(0xFF10B981), size: 44),
                  SizedBox(height: 10),
                  Text('감지된 이상 없음', style: TextStyle(fontSize: 15,
                      fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                  SizedBox(height: 4),
                  Text('모든 센서 정상 작동 중', style: TextStyle(fontSize: 13,
                      color: Color(0xFF94A3B8))),
                ]),
              )
            else
              ...items.map((alert) => _AlertCard(alert: alert, onResolve: _resolveAlert)),
          ],
        ),
      ),
    );
  }

  Widget _vertDiv() => Container(
      width: 1, height: 32, color: const Color(0xFFE2E8F0),
      margin: const EdgeInsets.symmetric(horizontal: 8));
}

// ── 알림 통계 칩 ────────────────────────────────────────────────────────────
class _AlertStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _AlertStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(children: [
        Text('$value', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
      ]),
    );
  }
}

// ── 알림 카드 ────────────────────────────────────────────────────────────────
class _AlertCard extends StatelessWidget {
  final Map alert;
  final Future<void> Function(int) onResolve;

  const _AlertCard({required this.alert, required this.onResolve});

  @override
  Widget build(BuildContext context) {
    final isUnresolved = alert["status"] == "처리 중";
    final isGas = alert["type"] == "가스";
    final color = isGas ? const Color(0xFFF97316) : const Color(0xFFEF4444);
    final bgColor = isGas ? const Color(0xFFFFF7ED) : const Color(0xFFFEF2F2);
    final icon = isGas ? Icons.local_fire_department_rounded : Icons.accessibility_new_rounded;
    final id = alert["id"] as int?;

    String timeStr = alert["time"] as String? ?? '';
    try {
      final dt = DateTime.parse(timeStr.replaceAll(' ', 'T')).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) timeStr = '방금 전';
      else if (diff.inMinutes < 60) timeStr = '${diff.inMinutes}분 전';
      else if (diff.inHours < 24) timeStr = '${diff.inHours}시간 전';
      else timeStr = '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUnresolved ? color.withOpacity(0.4) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [BoxShadow(
          color: isUnresolved ? color.withOpacity(0.07) : Colors.black.withOpacity(0.03),
          blurRadius: 8, offset: const Offset(0, 2),
        )],
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: isUnresolved ? bgColor : const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isUnresolved ? icon : Icons.check_circle_rounded,
            color: isUnresolved ? color : const Color(0xFF10B981),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isUnresolved ? color.withOpacity(0.1) : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                alert["type"] as String? ?? '',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                    color: isUnresolved ? color : const Color(0xFF10B981)),
              ),
            ),
          ]),
          const SizedBox(height: 6),
          Text(alert["content"] as String? ?? '',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                  color: Color(0xFF1E293B), height: 1.4)),
          const SizedBox(height: 4),
          Text(timeStr, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
        ])),
        const SizedBox(width: 10),
        if (isUnresolved && id != null)
          GestureDetector(
            onTap: () => onResolve(id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('해결', style: TextStyle(fontSize: 12,
                  fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          )
        else
          const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
      ]),
    );
  }
}

// ── 대화 버블 카드 ────────────────────────────────────────────────────────────
class _ChatBubbleCard extends StatelessWidget {
  final Map<String, dynamic> log;
  const _ChatBubbleCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final type = (log["type"] ?? '').toString();
    final time = (log["time"] ?? '').toString();
    final user = (log["user"] ?? '').toString();
    final bot = (log["bot"] ?? '').toString();
    final isEmergency = type == "긴급";

    String timeStr = time;
    if (time.length >= 19) {
      final dt = DateTime.tryParse(time);
      if (dt != null) {
        timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isEmergency ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          child: Row(children: [
            const Spacer(),
            const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF94A3B8)),
            const SizedBox(width: 4),
            Text(timeStr, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
          ]),
        ),
        const Divider(height: 1, color: Color(0xFFF1F5F9)),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(14)),
              child: const Center(child: Text('👴', style: TextStyle(fontSize: 14))),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.only(topRight: Radius.circular(12),
                      bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
                ),
                child: Text(user, style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B))),
              ),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(14)),
              child: const Center(child: Text('🤖', style: TextStyle(fontSize: 14))),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isEmergency ? const Color(0xFFFEF2F2) : const Color(0xFFEFF6FF),
                  borderRadius: const BorderRadius.only(topRight: Radius.circular(12),
                      bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
                ),
                child: Text(bot, style: TextStyle(fontSize: 14,
                    color: isEmergency ? const Color(0xFFDC2626) : const Color(0xFF1E293B))),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
