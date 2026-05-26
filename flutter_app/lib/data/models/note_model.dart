// lib/data/models/note_model.dart

class NoteModel {
  final String id;
  final String title;
  final String content;
  final String userId;
  final String? fileUrl;
  final String? fileType;   // 'pdf' | 'image'
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  NoteModel({
    required this.id,
    required this.title,
    required this.content,
    required this.userId,
    this.fileUrl,
    this.fileType,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      userId: json['user_id'] ?? '',
      fileUrl: json['file_url'],
      fileType: json['file_type'],
      tags: json['tags'] != null
          ? List<String>.from(json['tags'])
          : [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'user_id': userId,
        'file_url': fileUrl,
        'file_type': fileType,
        'tags': tags,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  Map<String, dynamic> toInsertJson() => {
        'title': title,
        'content': content,
        'user_id': userId,
        'file_url': fileUrl,
        'file_type': fileType,
        'tags': tags,
      };

  NoteModel copyWith({
    String? title,
    String? content,
    String? fileUrl,
    String? fileType,
    List<String>? tags,
  }) {
    return NoteModel(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      userId: userId,
      fileUrl: fileUrl ?? this.fileUrl,
      fileType: fileType ?? this.fileType,
      tags: tags ?? this.tags,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  // Preview of content (first 100 chars)
  String get preview =>
      content.length > 100 ? '${content.substring(0, 100)}...' : content;

  // Word count
  int get wordCount =>
      content.trim().isEmpty ? 0 : content.trim().split(RegExp(r'\s+')).length;
}
