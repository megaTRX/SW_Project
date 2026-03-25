import 'package:flutter/material.dart';

class LogCard extends StatelessWidget {
  final Map log;
  const LogCard({super.key, required this.log});

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

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(log["time"] as String,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
                child: Text(log["type"] as String,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('👴 ${log["user"]}',
              style: const TextStyle(fontSize: 13, color: Color(0xFF3B82F6))),
          const SizedBox(height: 4),
          Text('🤖 ${log["bot"]}',
              style: const TextStyle(fontSize: 13, color: Color(0xFF10B981))),
        ],
      ),
    );
  }
}