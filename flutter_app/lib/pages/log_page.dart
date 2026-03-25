import 'package:flutter/material.dart';
import '../data/api_service.dart';

class LogPage extends StatefulWidget {
  const LogPage({super.key});

  @override
  State<LogPage> createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> {
  String _selectedCategory = '전체';
  final _searchController = TextEditingController();
  String _keyword = '';
  List<Map> _logs = [];
  bool _isLoading = true;

  final List<String> _categories = ['전체', '생활정보', '복약', '일정', '긴급'];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    final data = await ApiService.getChatLogs();
    setState(() {
      _logs = data.isEmpty ? [
        {"time": "09:10", "user": "오늘 날씨 알려줘", "bot": "오늘은 맑고 따뜻합니다.", "type": "생활정보"},
        {"time": "10:00", "user": "오늘 약 먹을 시간 알려줘", "bot": "오전 10시에 혈압약 드실 시간입니다.", "type": "복약"},
        {"time": "13:00", "user": "내 일정 알려줘", "bot": "오후 3시에 복지관 방문 일정이 있습니다.", "type": "일정"},
        {"time": "15:30", "user": "살려줘", "bot": "긴급 호출이 접수되었습니다.", "type": "긴급"},
      ] : data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _logs.where((l) {
      final matchCategory = _selectedCategory == '전체' || l["type"] == _selectedCategory;
      final matchKeyword = _keyword.isEmpty ||
          l["user"].toString().contains(_keyword) ||
          l["bot"].toString().contains(_keyword);
      return matchCategory && matchKeyword;
    }).toList();

    final Map<String, int> stats = {};
    for (final l in _logs) {
      stats[l["type"] as String] = (stats[l["type"] as String] ?? 0) + 1;
    }

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
                const Text('대화 내용',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 6),
                Text('총 ${_logs.length}개의 대화',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _StatChip(label: '생활정보', count: stats['생활정보'] ?? 0, color: const Color(0xFF3B82F6)),
                    const SizedBox(width: 8),
                    _StatChip(label: '복약', count: stats['복약'] ?? 0, color: const Color(0xFF10B981)),
                    const SizedBox(width: 8),
                    _StatChip(label: '일정', count: stats['일정'] ?? 0, color: const Color(0xFF8B5CF6)),
                    const SizedBox(width: 8),
                    _StatChip(label: '긴급', count: stats['긴급'] ?? 0, color: const Color(0xFFEF4444)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 검색창
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _keyword = v),
                  decoration: InputDecoration(
                    hintText: '대화 내용 검색...',
                    hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8)),
                    suffixIcon: _keyword.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() => _keyword = '');
                            },
                            child: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // 카테고리 필터
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategory = cat),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF6366F1) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Text(cat,
                              style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : const Color(0xFF64748B),
                              )),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 16),

                Text('${filtered.length}개의 대화',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),

                const SizedBox(height: 10),

                if (_isLoading)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: Color(0xFF6366F1)),
                  ))
                else if (filtered.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Column(
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded,
                              color: Color(0xFFCBD5E1), size: 48),
                          SizedBox(height: 12),
                          Text('검색 결과가 없어요',
                              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 15)),
                        ],
                      ),
                    ),
                  )
                else
                  ...filtered.map((l) => _ChatBubbleCard(log: l)),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubbleCard extends StatelessWidget {
  final Map log;
  const _ChatBubbleCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final colors = {
      "생활정보": const Color(0xFF3B82F6),
      "복약": const Color(0xFF10B981),
      "일정": const Color(0xFF8B5CF6),
      "긴급": const Color(0xFFEF4444),
    };
    final bgColors = {
      "생활정보": const Color(0xFFEFF6FF),
      "복약": const Color(0xFFF0FDF4),
      "일정": const Color(0xFFF5F3FF),
      "긴급": const Color(0xFFFEF2F2),
    };

    final c = colors[log["type"]] ?? const Color(0xFF94A3B8);
    final bg = bgColors[log["type"]] ?? const Color(0xFFF8FAFC);
    final isEmergency = log["type"] == "긴급";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isEmergency ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
                  child: Text(log["type"] as String,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c)),
                ),
                const Spacer(),
                const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF94A3B8)),
                const SizedBox(width: 4),
                Text(log["time"] as String,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(14)),
                  child: const Center(child: Text('👴', style: TextStyle(fontSize: 14))),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: Text(log["user"] as String,
                        style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B))),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(14)),
                  child: const Center(child: Text('🤖', style: TextStyle(fontSize: 14))),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isEmergency
                          ? const Color(0xFFFEF2F2)
                          : const Color(0xFFEFF6FF),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: Text(log["bot"] as String,
                        style: TextStyle(
                            fontSize: 14,
                            color: isEmergency
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF1E293B))),
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

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatChip({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
              width: 6, height: 6,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 5),
          Text('$label $count',
              style: const TextStyle(
                  color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}