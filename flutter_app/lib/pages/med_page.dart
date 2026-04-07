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
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getMedications();
      if (mounted) {
        setState(() {
          _meds = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final takenList = _meds.where((m) => m["taken"] == true || m["taken"] == 1).toList();
    final remainingList = _meds.where((m) => m["taken"] == false || m["taken"] == 0).toList();
    final taken = takenList.length;
    final total = _meds.length;
    final progress = total > 0 ? taken / total : 0.0;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                const Text('오늘의 복약', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 6),
                Text('$taken / $total 완료',
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
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
            const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: Color(0xFF6366F1))))
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (remainingList.isNotEmpty) ...[
                    const Text('⏰ 복약 전', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                    const SizedBox(height: 10),
                    ...remainingList.map((med) => _MedCard(
                      med: med,
                      isTaken: false,
                      onTap: () async {
                        if (med["id"] != null) {
                          await ApiService.takeMedication(med["id"]);
                          await _loadMeds();
                        }
                      },
                      onDelete: () async {
                        if (med["id"] != null) {
                          await ApiService.deleteMedication(med["id"]);
                          await _loadMeds();
                        }
                      },
                    )),
                    const SizedBox(height: 20),
                  ],
                  if (takenList.isNotEmpty) ...[
                    const Text('✅ 복약 완료', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                    const SizedBox(height: 10),
                    ...takenList.map((med) => _MedCard(
                      med: med,
                      isTaken: true,
                      onTap: () async {
                        if (med["id"] != null) {
                          await ApiService.untakeMedication(med["id"]);
                          await _loadMeds();
                        }
                      },
                      onDelete: () async {
                        if (med["id"] != null) {
                          await ApiService.deleteMedication(med["id"]);
                          await _loadMeds();
                        }
                      },
                    )),
                    const SizedBox(height: 20),
                  ],
                  const Text('💊 복약 추가', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                  const SizedBox(height: 10),
                  _AddMedCard(onAdd: (name, time) async {
                    await ApiService.addMedication(name, time);
                    await _loadMeds();
                  }),
                  const SizedBox(height: 20),
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
                          child: Text('복약 시간이 되면 챗봇이 음성으로 알려드립니다.',
                              style: TextStyle(fontSize: 13, color: Color(0xFF3730A3))),
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

class _MedCard extends StatelessWidget {
  final Map med;
  final bool isTaken;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _MedCard({required this.med, required this.isTaken, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final color = isTaken ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isTaken ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: isTaken ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(isTaken ? Icons.check_rounded : Icons.medication_rounded, color: color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(med["name"] ?? "약 이름 없음",
                    style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600,
                      color: isTaken ? const Color(0xFF94A3B8) : const Color(0xFF1E293B),
                      decoration: isTaken ? TextDecoration.lineThrough : null,
                    )),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 4),
                  Text(med["time"] ?? "시간 미설정", style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
                ]),
              ],
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isTaken ? const Color(0xFFF0FDF4) : const Color(0xFF6366F1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isTaken ? '완료' : '복용 완료',
                style: TextStyle(
                    color: isTaken ? const Color(0xFF10B981) : Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: const Text('복약 삭제', style: TextStyle(fontWeight: FontWeight.w700)),
                  content: Text('${med["name"]}을(를) 삭제할까요?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false),
                        child: const Text('취소', style: TextStyle(color: Color(0xFF94A3B8)))),
                    TextButton(onPressed: () => Navigator.pop(context, true),
                        child: const Text('삭제', style: TextStyle(color: Color(0xFFEF4444)))),
                  ],
                ),
              );
              if (confirm == true) onDelete();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddMedCard extends StatefulWidget {
  final Function(String name, String time) onAdd;
  const _AddMedCard({required this.onAdd});

  @override
  State<_AddMedCard> createState() => _AddMedCardState();
}

class _AddMedCardState extends State<_AddMedCard> {
  final _nameController = TextEditingController();
  bool _expanded = false;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  String _formatDateTime() {
    if (_selectedDate != null && _selectedTime != null) {
      final y = _selectedDate!.year;
      final mo = _selectedDate!.month.toString().padLeft(2, '0');
      final d = _selectedDate!.day.toString().padLeft(2, '0');
      final h = _selectedTime!.hour.toString().padLeft(2, '0');
      final mi = _selectedTime!.minute.toString().padLeft(2, '0');
      return '$y-$mo-$d $h:$mi';
    } else if (_selectedTime != null) {
      final h = _selectedTime!.hour.toString().padLeft(2, '0');
      final mi = _selectedTime!.minute.toString().padLeft(2, '0');
      return '$h:$mi';
    }
    return '';
  }

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
                    child: Text('새 복약 추가', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF1E293B))),
                  ),
                  Icon(_expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      color: const Color(0xFF94A3B8)),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: '약 이름',
                      prefixIcon: const Icon(Icons.medication_rounded, color: Color(0xFF6366F1)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2030),
                            );
                            if (d != null) setState(() => _selectedDate = d);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF6366F1)),
                                const SizedBox(width: 8),
                                Text(
                                  _selectedDate == null
                                      ? '날짜 선택'
                                      : '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _selectedDate == null ? const Color(0xFF94A3B8) : const Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final t = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (t != null) setState(() => _selectedTime = t);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF6366F1)),
                                const SizedBox(width: 8),
                                Text(
                                  _selectedTime == null
                                      ? '시간 선택'
                                      : '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _selectedTime == null ? const Color(0xFF94A3B8) : const Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        final time = _formatDateTime();
                        if (_nameController.text.isNotEmpty && _selectedTime != null) {
                          widget.onAdd(_nameController.text, time);
                          _nameController.clear();
                          setState(() {
                            _expanded = false;
                            _selectedDate = null;
                            _selectedTime = null;
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('추가하기', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
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