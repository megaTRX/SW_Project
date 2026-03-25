import 'package:flutter/material.dart';
import '../data/api_service.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  List<Map> _scheds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadScheds();
  }

  Future<void> _loadScheds() async {
    setState(() => _isLoading = true);
    final data = await ApiService.getSchedules();
    setState(() {
      _scheds = data.isEmpty ? [
        {"title": "복지관 방문", "time": "15:00", "status": "예정"},
        {"title": "딸과 통화", "time": "19:00", "status": "예정"},
        {"title": "병원 예약", "time": "2026-03-12 11:00", "status": "예정"},
      ] : data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final today = _scheds.where((s) => !s["time"].toString().contains('-')).toList();
    final upcoming = _scheds.where((s) => s["time"].toString().contains('-')).toList();
    final done = _scheds.where((s) => s["status"] == "완료").length;

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
                Text(
                  '${DateTime.now().year}년 ${DateTime.now().month}월 ${DateTime.now().day}일',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  '오늘 일정 ${today.length}개',
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _StatBadge(label: '예정', count: today.where((s) => s["status"] == "예정").length, color: Colors.white.withOpacity(0.2)),
                    const SizedBox(width: 8),
                    _StatBadge(label: '완료', count: done, color: Colors.white.withOpacity(0.2)),
                    const SizedBox(width: 8),
                    _StatBadge(label: '취소', count: today.where((s) => s["status"] == "취소").length, color: Colors.white.withOpacity(0.2)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          if (_isLoading)
            const Center(child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: Color(0xFF6366F1)),
            ))
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // 오늘 일정
                  if (today.isNotEmpty) ...[
                    const Text('📅 오늘 일정',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                    const SizedBox(height: 10),
                    ...today.map((s) {
                      final i = _scheds.indexOf(s);
                      return _SchedCard(
                        sched: s,
                        onStatusChange: (status) async {
                          if (status == "완료" && s["id"] != null) {
                            await ApiService.completeSchedule(s["id"]);
                          }
                          setState(() => _scheds[i]["status"] = status);
                        },
                      );
                    }),
                    const SizedBox(height: 20),
                  ],

                  // 예정 일정
                  if (upcoming.isNotEmpty) ...[
                    const Text('🗓 예정 일정',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                    const SizedBox(height: 10),
                    ...upcoming.map((s) {
                      final i = _scheds.indexOf(s);
                      return _SchedCard(
                        sched: s,
                        onStatusChange: (status) async {
                          if (status == "완료" && s["id"] != null) {
                            await ApiService.completeSchedule(s["id"]);
                          }
                          setState(() => _scheds[i]["status"] = status);
                        },
                      );
                    }),
                    const SizedBox(height: 20),
                  ],

                  // 일정 추가
                  const Text('➕ 일정 추가',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                  const SizedBox(height: 10),
                  _AddSchedCard(onAdd: (title, time) async {
                    await ApiService.addSchedule(title, time);
                    _loadScheds();
                  }),

                  const SizedBox(height: 20),

                  // 안내
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_rounded, color: Color(0xFF0EA5E9), size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '일정 시간이 되면 챗봇이 음성으로 알려드립니다.',
                            style: TextStyle(fontSize: 13, color: Color(0xFF0369A1)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SchedCard extends StatelessWidget {
  final Map sched;
  final Function(String) onStatusChange;

  const _SchedCard({required this.sched, required this.onStatusChange});

  @override
  Widget build(BuildContext context) {
    final status = sched["status"] as String;
    final isDone = status == "완료";
    final isCancelled = status == "취소";

    Color borderColor = const Color(0xFFE2E8F0);
    Color iconBg = const Color(0xFFEFF6FF);
    Color iconColor = const Color(0xFF6366F1);

    if (isDone) {
      borderColor = const Color(0xFFBBF7D0);
      iconBg = const Color(0xFFF0FDF4);
      iconColor = const Color(0xFF10B981);
    } else if (isCancelled) {
      borderColor = const Color(0xFFE2E8F0);
      iconBg = const Color(0xFFF8FAFC);
      iconColor = const Color(0xFF94A3B8);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(14)),
            child: Icon(
              isDone ? Icons.check_rounded : isCancelled ? Icons.close_rounded : Icons.calendar_today_rounded,
              color: iconColor, size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sched["title"] as String,
                  style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600,
                    color: isCancelled ? const Color(0xFF94A3B8) : const Color(0xFF1E293B),
                    decoration: isCancelled ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Text(sched["time"] as String,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
                  ],
                ),
              ],
            ),
          ),
          if (!isDone && !isCancelled)
            Row(
              children: [
                GestureDetector(
                  onTap: () => onStatusChange("완료"),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('완료',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => onStatusChange("취소"),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('취소',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isDone ? const Color(0xFFF0FDF4) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(status,
                  style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: isDone ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                  )),
            ),
        ],
      ),
    );
  }
}

class _AddSchedCard extends StatefulWidget {
  final Function(String title, String time) onAdd;
  const _AddSchedCard({required this.onAdd});

  @override
  State<_AddSchedCard> createState() => _AddSchedCardState();
}

class _AddSchedCardState extends State<_AddSchedCard> {
  final _titleController = TextEditingController();
  final _timeController = TextEditingController();
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.add_rounded, color: Color(0xFF6366F1), size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('새 일정 추가',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF1E293B))),
                  ),
                  Icon(
                    _expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF94A3B8),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  const Divider(color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: '일정명',
                      prefixIcon: const Icon(Icons.event_rounded, color: Color(0xFF6366F1)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _timeController,
                    decoration: InputDecoration(
                      labelText: '시간 (예: 15:00)',
                      prefixIcon: const Icon(Icons.access_time_rounded, color: Color(0xFF6366F1)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_titleController.text.isNotEmpty && _timeController.text.isNotEmpty) {
                          widget.onAdd(_titleController.text, _timeController.text);
                          _titleController.clear();
                          _timeController.clear();
                          setState(() => _expanded = false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: const Text('추가하기',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatBadge({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text('$label $count',
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}