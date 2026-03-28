import 'dart:convert';
import 'package:http/http.dart' as http;

const String baseUrl = 'http://127.0.0.1:8000';

class ApiService {

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

  static Future<bool> deleteMedication(int id) async {
    try {
      final res = await http.delete(Uri.parse('$baseUrl/medicine/$id'));
      return res.statusCode == 200;
    } catch (e) {
      print('복약 삭제 오류: $e');
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
        final List data = jsonDecode(res.body);
        return data.map((e) => {
          "time": e["created_at"] ?? '',
          "user": e["content"] ?? '',
          "bot": '',
          "type": '생활정보',
        }).toList();
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
}
