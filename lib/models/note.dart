import 'dart:convert';

class Note {
  final double id;
  final String? title;
  final String content;
  final String categoryId;
  final String date;
  final int createdTimestamp;
  final int updatedTimestamp;
  final int expanded;
  final int editMode;
  final String type;
  final Map<String, dynamic>? metadata;

  Note({
    required this.id,
    this.title,
    required this.content,
    required this.categoryId,
    required this.date,
    required this.createdTimestamp,
    required this.updatedTimestamp,
    required this.expanded,
    required this.editMode,
    required this.type,
    this.metadata,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? parsedMetadata;
    final raw = json['metadata'];
    if (raw is String) {
      if (raw.isNotEmpty) {
        try {
          parsedMetadata = jsonDecode(raw) as Map<String, dynamic>;
        } catch (e) {
          // Некорректный JSON в metadata, игнорируем
          parsedMetadata = null;
        }
      }
    } else if (raw is Map<String, dynamic>) {
      parsedMetadata = raw;
    }

    return Note(
      id: (json['id'] as num).toDouble(),
      title: json['title'] as String?,
      content: json['content'] as String,
      categoryId: json['category_id'] as String,
      date: json['date'] as String,
      createdTimestamp: (json['created_timestamp'] as num).toInt(),
      updatedTimestamp: (json['updated_timestamp'] as num).toInt(),
      expanded: (json['expanded'] as num).toInt(),
      editMode: (json['edit_mode'] as num).toInt(),
      type: json['type'] as String,
      metadata: parsedMetadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category_id': categoryId,
      'date': date,
      'created_timestamp': createdTimestamp,
      'updated_timestamp': updatedTimestamp,
      'expanded': expanded,
      'edit_mode': editMode,
      'type': type,
      'metadata': metadata != null ? jsonEncode(metadata) : null,
    };
  }
}
