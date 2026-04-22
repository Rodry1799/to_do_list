import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Models/task_model.dart';

class ApiService {
  // ملاحظة: استبدل localhost بـ 10.0.2.2 إذا كنت تستخدم محاكي أندرويد
  static const String baseUrl = "http://localhost/to_do_list_APIs";

  // دالة جلب البيانات (Read)
  Future<List<TaskModel>> getTasks() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/read.php"));

      if (response.statusCode == 200) {
        List jsonResponse = json.decode(response.body);
        return jsonResponse.map((task) => TaskModel.fromJson(task)).toList();
      } else {
        throw Exception('Failed to load tasks: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // دالة إضافة مهمة جديدة
  Future<bool> addTask(String title, String description) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/add.php"),
        body: {
          'title': title,
          'description': description,
        },
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return result['status'] == 'success';
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // دالة تحديث حالة المهمة
  Future<bool> updateTask(TaskModel task) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/update.php"),
        body: {
          'id': task.id.toString(),
          'title': task.title,
          'description': task.description,
          'is_completed': task.isCompleted ? '1' : '0',
        },
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return result['status'] == 'success';
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // دالة حذف مهمة
  Future<bool> deleteTask(int id) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/delet.php"),
        body: {
          'id': id.toString(),
        },
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return result['status'] == 'success';
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
