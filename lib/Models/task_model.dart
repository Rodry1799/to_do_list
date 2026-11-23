class TaskModel {
  final int id;
  final int? userId;
  final String title;
  final String description;
  final String category;
  final bool isCompleted;
  final bool isArchived;
  final String? deletedAt;
  final String? createdAt;

  TaskModel({
    required this.id,
    this.userId,
    required this.title,
    required this.description,
    this.category = 'General',
    required this.isCompleted,
    this.isArchived = false,
    this.deletedAt,
    this.createdAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: int.parse(json['id'].toString()),
      userId: json['user_id'] != null ? int.parse(json['user_id'].toString()) : null,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? 'General',
      isCompleted: json['is_completed'] == 1 || json['is_completed'] == '1',
      isArchived: json['is_archived'] == 1 || json['is_archived'] == '1',
      deletedAt: json['deleted_at'],
      createdAt: json['created_at'],
    );
  }

  /// نسخة معدّلة مع حقول اختيارية محدودة
  TaskModel copyWith({
    String? title,
    String? description,
    String? category,
    bool? isCompleted,
    bool? isArchived,
    String? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return TaskModel(
      id: id,
      userId: userId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      isArchived: isArchived ?? this.isArchived,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      createdAt: createdAt,
    );
  }
}
