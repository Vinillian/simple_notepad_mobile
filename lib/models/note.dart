import 'package:json_annotation/json_annotation.dart';

part 'note.g.dart';

@JsonSerializable()
class Note {
  final int id;
  final String? title;
  final String content;
  @JsonKey(name: 'category_id')
  final String categoryId;
  final String date;
  @JsonKey(name: 'created_timestamp')
  final int createdTimestamp;
  @JsonKey(name: 'updated_timestamp')
  final int updatedTimestamp;
  final int expanded; // изменено с bool на int
  @JsonKey(name: 'edit_mode')
  final int editMode; // изменено с bool на int
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

  factory Note.fromJson(Map<String, dynamic> json) => _$NoteFromJson(json);
  Map<String, dynamic> toJson() => _$NoteToJson(this);
}
