import 'package:json_annotation/json_annotation.dart';

part 'settings.g.dart';

@JsonSerializable()
class Settings {
  @JsonKey(name: 'sort_order')
  final String sortOrder;
  @JsonKey(name: 'view_mode')
  final String viewMode;

  Settings({required this.sortOrder, required this.viewMode});

  factory Settings.fromJson(Map<String, dynamic> json) => _$SettingsFromJson(json);
  Map<String, dynamic> toJson() => _$SettingsToJson(this);
}