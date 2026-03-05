// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Note _$NoteFromJson(Map<String, dynamic> json) => Note(
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
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$NoteToJson(Note instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'content': instance.content,
      'category_id': instance.categoryId,
      'date': instance.date,
      'created_timestamp': instance.createdTimestamp,
      'updated_timestamp': instance.updatedTimestamp,
      'expanded': instance.expanded,
      'edit_mode': instance.editMode,
      'type': instance.type,
      'metadata': instance.metadata,
    };
