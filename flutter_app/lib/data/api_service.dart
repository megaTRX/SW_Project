import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

final String apiKey = dotenv.env['WEATHER_API_KEY'] ?? "";
final String url = "https://api.openweathermap.org/data/2.5/weather?q=Seoul&appid=$apiKey&units=metric";

const String baseUrl = 'http://172.27.177.208:8000';

class ApiService {

  // ===== 대화 분류 =====
  static String _classifyChat(String content) {
    final c = content;
    if (c.contains('약') || c.contains('복약') || c.contains('약품') || c.contains('먹을') || c.contains('복용')) {
      return '복약';
    } else if (c.contains('일정') || c.contains('예약') || c.contains('병원') || c.contains('약속') || c.contains('방문')) {
      return '일정';
    } else if (c.contains('살려') || c.contains('도와줘') || c.contains('긴급') || c.contains('응급') || c.contains('아파') || c.contains('쓰러')) {
      return '긴급';
    }
    return '생활정보';
  }

  // ===== 복약 =====
  static Future<List<Map>> getMedications() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/medicine/'));
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.map((e) => {
          "name": e["name"] ?? '',
          "time": e["alarm_times"] ?? '',
          "taken": e["taken"] == 1 || e["taken"] == true,
          "id": e["id"],
        }).toList();
      }
    } catch (e) {
      print('복약 조회 오류: $e');
    }
    return [];
  }

  static Future<bool> addMedication(String name, String time) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/medicine/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "name": name,
          "dose": "1정",
          "alarm_times": time,
          "start_date": DateTime.now().toString().split(' ')[0],
          "end_date": DateTime.now().add(const Duration(days: 30)).toString().split(' ')[0],
        }),
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      print('복약 추가 오류: $e');
      return false;
    }
  }

  static Future<bool> takeMedication(int id) async {
    try {
      final res = await http.patch(
        Uri.parse('$baseUrl/medicine/$id/take'),
        headers: {'Content-Type': 'application/json'},
      );
      return res.statusCode == 200;
    } catch (e) {
      print('복약 완료 오류: $e');
      return false;
    }
  }

  static Future<bool> untakeMedication(int id) async {
    try {
      final res = await http.patch(
        Uri.parse('$baseUrl/medicine/$id/untake'),
        headers: {'Content-Type': 'application/json'},
      );
      return res.statusCode == 200;
    } catch (e) {
      print('복약 취소 오류: $e');
      return false;
    }
  }

  static Future<bool> deleteMedication(int id) async {
    try {
      final res = await http.delete(Uri.parse('$baseUrl/medicine/$id'));
      return res.statusCode == 200;
    } catch (e) {
      print('복약 삭제 오류: $e');
      return false;
    }
  }

  // ===== 일정 =====
  static Future<List<Map>> getSchedules() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/schedule/'));
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.map((e) => {
          "title": e["title"] ?? '',
          "time": e["datetime"] ?? '',
          "status": e["is_completed"] == true ? "완료" : "",
          "id": e["id"],
        }).toList();
      }
    } catch (e) {
      print('일정 조회 오류: $e');
    }
    return [];
  }

  static Future<bool> addSchedule(String title, String time) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/schedule/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "title": title,
          "datetime": time,
          "memo": "",
          "is_completed": false,
        }),
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      print('일정 추가 오류: $e');
      return false;
    }
  }

  static Future<bool> completeSchedule(int id) async {
    try {
      final res = await http.patch(
        Uri.parse('$baseUrl/schedule/$id/complete'),
        headers: {'Content-Type': 'application/json'},
      );
      return res.statusCode == 200;
    } catch (e) {
      print('일정 완료 오류: $e');
      return false;
    }
  }

  static Future<bool> uncompleteSchedule(int id) async {
    try {
      final res = await http.patch(
        Uri.parse('$baseUrl/schedule/$id/uncomplete'),
        headers: {'Content-Type': 'application/json'},
      );
      return res.statusCode == 200;
    } catch (e) {
      print('일정 취소 오류: $e');
      return false;
    }
  }

  static Future<bool> deleteSchedule(int id) async {
    try {
      final res = await http.delete(Uri.parse('$baseUrl/schedule/$id'));
      return res.statusCode == 200;
    } catch (e) {
      print('일정 삭제 오류: $e');
      return false;
    }
  }

  // ===== 대화 로그 =====
  static Future<List<Map>> getChatLogs() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/chat/'));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final List data = decoded is List ? decoded : (decoded['items'] ?? []);

        // 오래된 순으로 정렬해서 user→bot 쌍 맞추기
        final List reversed = data.reversed.toList();

        final List<Map> result = [];
        Map? currentPair;

        for (final e in reversed) {
          final role = e["role"]?.toString() ?? '';
          final content = e["content"]?.toString() ?? '';
          final time = e["created_at"]?.toString() ?? '';

          if (role == "user") {
            currentPair = {
              "user": content,
              "bot": "",
              "time": time,
              "type": _classifyChat(content),
            };
          } else if (role == "assistant" && currentPair != null) {
            currentPair["bot"] = content;
            result.add(currentPair);
            currentPair = null;
          }
        }
        if (currentPair != null) result.add(currentPair!);
        return result.reversed.toList();
      }
    } catch (e) {
      print('대화 로그 조회 오류: $e');
    }
    return [];
  }

  // ===== 알림 =====
  static Future<List<Map>> getAlerts() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/alert/'));
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.map((e) => {
          "time": e["created_at"] ?? '',
          "content": e["message"] ?? '',
          "status": e["is_resolved"] == true ? "처리 완료" : "처리 중",
          "type": e["type"] ?? "비활동",
          "id": e["id"],
        }).toList();
      }
    } catch (e) {
      print('알림 조회 오류: $e');
    }
    return [];
  }

  static Future<bool> resolveAlert(int id) async {
    try {
      final res = await http.patch(
        Uri.parse('$baseUrl/alert/$id/resolve'),
        headers: {'Content-Type': 'application/json'},
      );
      return res.statusCode == 200;
    } catch (e) {
      print('알림 해결 오류: $e');
      return false;
    }
  }
}