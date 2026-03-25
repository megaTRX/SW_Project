import 'package:flutter/material.dart';
import '../data/api_service.dart';

class MedPage extends StatefulWidget {
  const MedPage({super.key});

  @override
  State<MedPage> createState() => _MedPageState();
}

class _MedPageState extends State<MedPage> {
  List<Map> _meds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMeds();
  }

  Future<void> _loadMeds() async {
    setState(() => _isLoading = true);
    final data = await ApiService.getMedications();
    setState(() {
      _meds = data.isEmpty ? [
        {"name": "혈압약", "time": "10:00", "taken": false},
        {"name": "당뇨약", "time": "18:00", "taken": false},
        {"name": "비타민", "time": "20:00", "taken": true},
      ] : data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final taken = _meds.where((m) => m["taken"] == true).length;
    final total = _meds.length;
    final progress = total > 0 ? taken / total : 0.0;

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
                const Text('오늘의 복약',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 6),
                Text('$taken / $total 완료',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  progress == 1.0 ? '🎉 오늘 복약을 모두 완료했어요!' : '${total - taken}개 복약이 남아있어요',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
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

                  // 복약 미완료
                  if (_meds.any((m) => m["taken"] == false)) ...[
                    const Text('⏰ 복약 전',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                    const SizedBox(height: 10),
                    ..._meds.where((m) => m["taken"] == false).map((med) {
                      final i = _meds.indexOf(med);
                      return _MedCard(
                        med: med,
                        onTaken: () async {
                          if (med["id"] != null) {
                            await ApiService.takeMedication(med["id"]);
                          }
                          setState(() => _meds[i]["taken"] = true);
                        },
                      );
                    }),
                    const SizedBox(height: 20),
                  ],

                  // 복약 완료
                  if (_meds.any((m) => m["taken"] == true)) ...[
                    const Text('✅ 복약 완료',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                    const SizedBox(height: 10),
                    ..._meds.where((m) => m["taken"] == true).map((med) {
                      return _MedCard(med: med, onTaken: null);
                    }),
                    const SizedBox(height: 20),
                  ],

                  // 복약 추가
                  const Text('💊 복약 추가',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                  const SizedBox(height: 10),
                  _AddMedCard(onAdd: (name, time) async {
                    await ApiService.addMedication(name, time);
                    _loadMeds();
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
                        Icon(Icons.info_rounded, color: Color(0xFF6366F1), size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '복약 시간이 되면 챗봇이 음성으로 알려드립니다.',
                            style: TextStyle(fontSize: 13, color: Color(0xFF3730A3)),
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

// ===== 복약 카드 =====
class _MedCard extends StatelessWidget {
  final Map med;
  final VoidCallback? onTaken;

  const _MedCard({required this.med, required this.onTaken});

  @override
  Widget build(BuildContext context) {
    final taken = med["taken"] as bool;
    final color = taken ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: taken ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: taken ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              taken ? Icons.check_rounded : Icons.medication_rounded,
              color: color, size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(med["name"] as String,
                    style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600,
                      color: taken
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF1E293B),
                      decoration:
                          taken ? TextDecoration.lineThrough : null,
                    )),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded,
                        size: 13, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Text(med["time"] as String,
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF94A3B8))),
                  ],
                ),
              ],
            ),
          ),
          if (!taken && onTaken != null)
            GestureDetector(
              onTap: onTaken,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('복용 완료',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            )
          else
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('완료 ✓',
                  style: TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }
}

// ===== 복약 추가 카드 =====
class _AddMedCard extends StatefulWidget {
  final Function(String name, String time) onAdd;
  const _AddMedCard({required this.onAdd});

  @override
  State<_AddMedCard> createState() => _AddMedCardState();
}

class _AddMedCardState extends State<_AddMedCard> {
  final _nameController = TextEditingController();
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
                    child: const Icon(Icons.add_rounded,
                        color: Color(0xFF6366F1), size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('새 복약 추가',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1E293B))),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
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
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: '약 이름',
                      prefixIcon: const Icon(Icons.medication_rounded,
                          color: Color(0xFF6366F1)),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: Color(0xFF6366F1), width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _timeController,
                    decoration: InputDecoration(
                      labelText: '복용 시간 (예: 10:00)',
                      prefixIcon: const Icon(Icons.access_time_rounded,
                          color: Color(0xFF6366F1)),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: Color(0xFF6366F1), width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_nameController.text.isNotEmpty &&
                            _timeController.text.isNotEmpty) {
                          widget.onAdd(
                              _nameController.text, _timeController.text);
                          _nameController.clear();
                          _timeController.clear();
                          setState(() => _expanded = false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: const Text('추가하기',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
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