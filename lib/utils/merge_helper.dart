import '../models/note.dart';
import '../models/category.dart';
import '../models/settings.dart';

class MergeHelper {
  /// Возвращает категории из списка [imported], которых нет в [current] (сравнение по id).
  static List<Category> findNewCategories({
    required List<Category> current,
    required List<Category> imported,
  }) {
    final currentIds = current.map((c) => c.id).toSet();
    return imported.where((c) => !currentIds.contains(c.id)).toList();
  }

  /// Возвращает заметки из списка [imported], которых нет в [current] (сравнение по id).
  static List<Note> findNewNotes({
    required List<Note> current,
    required List<Note> imported,
  }) {
    final currentIds = current.map((n) => n.id).toSet();
    return imported.where((n) => !currentIds.contains(n.id)).toList();
  }

  /// Проверяет, отличаются ли настройки (можно заменить текущие импортированными).
  static bool isSettingsDifferent(Settings current, Settings imported) {
    return current.sortOrder != imported.sortOrder ||
        current.viewMode != imported.viewMode;
  }
}
