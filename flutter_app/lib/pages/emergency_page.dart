import 'package:flutter/material.dart';
import '../data/mock_data.dart';

class EmergencyPage extends StatelessWidget {
  const EmergencyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final processing = mockEmergencies.where((e) => e["status"] == "처리 중").toList();
    final done = mockEmergencies.where((e) => e["status"] == "처리 완료").toList();

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🚨 긴급 호출',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
          const SizedBox(height: 16),
          if (processing.isNotEmpty) ...[
            const Text('🔴 처리 중',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFEF4444))),
            const SizedBox(height: 8),
            ...processing.map((e) => _EmergencyCard(item: e, isProcessing: true)),
            const SizedBox(height: 16),
          ],
          if (done.isNotEmpty) ...[
            const Text('🟢 처리 완료',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF10B981))),
            const SizedBox(height: 8),
            ...done.map((e) => _EmergencyCard(item: e, isProcessing: false)),
          ],
        ],
      ),
    );
  }
}

class _EmergencyCard extends StatelessWidget {
  final Map item;
  final bool isProcessing;
  const _EmergencyCard({required this.item, required this.isProcessing});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(
            color: isProcessing ? const Color(0xFFEF4444) : const Color(0xFF10B981),
            width: 4,
          ),
          top: const BorderSide(color: Color(0xFFE2E8F0)),
          right: const BorderSide(color: Color(0xFFE2E8F0)),
          bottom: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item["time"] as String,
                    style: TextStyle(
                        fontSize: 12,
                        color: isProcessing ? const Color(0xFFEF4444) : const Color(0xFF10B981))),
                const SizedBox(height: 4),
                Text(item["content"] as String,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1E293B))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isProcessing ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              item["status"] as String,
              style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: isProcessing ? const Color(0xFFEF4444) : const Color(0xFF10B981),
              ),
            ),
          ),
        ],
      ),
    );
  }
}