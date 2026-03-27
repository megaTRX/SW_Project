import 'package:flutter/material.dart';
import '../models/log_item.dart';

class LogCard extends StatelessWidget {
  final LogItem log;
  const LogCard({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    // 카테고리별 색상 설정 (모델의 title이나 status에 따라 색상을 결정합니다)
    final colors = {
      "복약": const Color(0xFF10B981),
      "일정": const Color(0xFF8B5CF6),
      "긴급": const Color(0xFFEF4444),
      "기타": const Color(0xFF94A3B8),
    };

    final bgColors = {
      "복약": const Color(0xFFF0FDF4),
      "일정": const Color(0xFFF5F3FF),
      "긴급": const Color(0xFFFEF2F2),
      "기타": const Color(0xFFF8FAFC),
    };

    // log.title에 '복약'이라는 글자가 포함되어 있으면 복약 색상을 쓰고, 아니면 일정 색상을 쓰도록 로직 수정
    String category = log.title.contains('복약') ? "복약" : "일정";
    if (log.title == "기타") category = "기타";

    final c = colors[category] ?? const Color(0xFF94A3B8);
    final bg = bgColors[category] ?? const Color(0xFFF8FAFC);

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
              Text(
                log.time.isNotEmpty ? log.time : '-',
                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  category, // 기존 log.type 대신 판별된 category 사용
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: c,
                  ),
                ),
              ),
              const Spacer(),
              // 상태(status) 표시 (예정/완료 등)
              Text(
                log.status,
                style: TextStyle(fontSize: 11, color: c, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 제목 표시 (👴 🤖 아이콘 대신 일정 내용을 큼직하게 표시)
          Row(
            children: [
              const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  log.title, // 기존 log.user/bot 대신 log.title 표시
                  style: const TextStyle(
                    fontSize: 14, 
                    fontWeight: FontWeight.w600, 
                    color: Color(0xFF1E293B)
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}