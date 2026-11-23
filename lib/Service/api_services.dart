import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Models/task_model.dart';

class ApiService {
  // ملاحظة: استبدل localhost بـ 10.0.2.2 إذا كنت تستخدم محاكي أندرويد
  static const String baseUrl = "http://localhost/to_do_list_APIs";

  // ─────────────────────────────────────────────────────────────────────────
  // جلب المهام مع دعم الفلترة والبحث والترتيب
  // ─────────────────────────────────────────────────────────────────────────
  Future<List<TaskModel>> getTasks({
    int? userId,
    String? category,   // 'All' أو اسم تصنيف
    String? search,     // نص البحث
    String sort = 'newest', // newest | oldest | completed
    bool archived = false,
    bool trashed = false,
  }) async {
    try {
      final queryParams = <String, String>{
        'sort': sort,
        'archived': archived ? '1' : '0',
        'trashed': trashed ? '1' : '0',
      };
      if (userId != null) queryParams['user_id'] = userId.toString();
      if (category != null && category != 'All') queryParams['category'] = category;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final uri = Uri.parse("$baseUrl/read.php").replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) {
          return decoded.map((task) => TaskModel.fromJson(task)).toList();
        }
        return [];
      } else {
        throw Exception('Failed to load tasks: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // إضافة مهمة جديدة
  // ─────────────────────────────────────────────────────────────────────────
  Future<bool> addTask(
    String title,
    String description,
    int userId, {
    String category = 'General',
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/add.php"),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'title': title,
          'description': description,
          'user_id': userId,
          'category': category,
        }),
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

  // ─────────────────────────────────────────────────────────────────────────
  // تحديث مهمة (شامل)
  // ─────────────────────────────────────────────────────────────────────────
  Future<bool> updateTask(TaskModel task) async {
    try {
      final body = <String, dynamic>{
        'id': task.id.toString(),
        'title': task.title,
        'description': task.description,
        'is_completed': task.isCompleted ? '1' : '0',
        'category': task.category,
        'is_archived': task.isArchived ? '1' : '0',
        'deleted_at': task.deletedAt, // null أو timestamp
      };

      final response = await http.post(
        Uri.parse("$baseUrl/update.php"),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
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

  // ─────────────────────────────────────────────────────────────────────────
  // نقل مهمة إلى سلة المحذوفات (Soft Delete)
  // ─────────────────────────────────────────────────────────────────────────
  Future<bool> trashTask(int id) async {
    try {
      final now = DateTime.now().toIso8601String().replaceFirst('T', ' ').substring(0, 19);
      final response = await http.post(
        Uri.parse("$baseUrl/update.php"),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'id': id.toString(), 'deleted_at': now}),
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

  // ─────────────────────────────────────────────────────────────────────────
  // استعادة مهمة من سلة المحذوفات أو الأرشيف
  // ─────────────────────────────────────────────────────────────────────────
  Future<bool> restoreTask(int id) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/update.php"),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'id': id.toString(),
          'deleted_at': null,
          'is_archived': '0',
        }),
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

  // ─────────────────────────────────────────────────────────────────────────
  // أرشفة / إلغاء أرشفة
  // ─────────────────────────────────────────────────────────────────────────
  Future<bool> archiveTask(int id, {bool archive = true}) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/update.php"),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'id': id.toString(), 'is_archived': archive ? '1' : '0'}),
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

  // ─────────────────────────────────────────────────────────────────────────
  // الحذف الدائم
  // ─────────────────────────────────────────────────────────────────────────
  Future<bool> deleteTask(int id) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/delet.php"),
        body: {'id': id.toString()},
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
