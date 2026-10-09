import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:simple_notepad_mobile/models/settings.dart';
import 'package:simple_notepad_mobile/services/backup_service.dart';

void main() {
  group('BackupService.backupFileName', () {
    test('uses a readable timestamp and the .json extension', () {
      expect(
        BackupService.backupFileName(DateTime(2026, 10, 9, 19, 5, 3)),
        'notebook_backup_2026-10-09T19-05-03.json',
      );
    });

    test('contains no characters that are bad in file names', () {
      final name = BackupService.backupFileName(DateTime(2026, 1, 2, 3, 4, 5));
      expect(name, isNot(contains(':')));
      expect(name, isNot(contains(' ')));
    });
  });

  group('BackupService.encodeBackup', () {
    test('produces JSON that BackupData.fromJson can read back', () {
      final json = BackupService.encodeBackup(
        notes: const [],
        categories: const [],
        settings: Settings(sortOrder: 'old', viewMode: 'grid'),
      );

      final backup =
          BackupData.fromJson(jsonDecode(json) as Map<String, dynamic>);
      expect(backup.notes, isEmpty);
      expect(backup.categories, isEmpty);
      expect(backup.settings.sortOrder, 'old');
      expect(backup.settings.viewMode, 'grid');
    });
  });
}
