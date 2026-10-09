import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_notepad_mobile/screens/settings_screen.dart';
import 'package:simple_notepad_mobile/services/local_app_state_service.dart';

class FakeServerUrlStorage implements ServerUrlStorage {
  String? value;

  FakeServerUrlStorage([this.value]);

  @override
  Future<String?> getServerUrl() async => value;

  @override
  Future<void> setServerUrl(String? url) async => value = url;
}

Future<void> pumpSettings(
  WidgetTester tester,
  FakeServerUrlStorage storage,
) async {
  await tester.pumpWidget(
    MaterialApp(home: SettingsScreen(storage: storage)),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the privacy note', (tester) async {
    await pumpSettings(tester, FakeServerUrlStorage());
    expect(find.text('Настройки'), findsOneWidget);
    expect(find.text('Приватность'), findsOneWidget);
  });

  testWidgets('has no link previews switch any more', (tester) async {
    await pumpSettings(tester, FakeServerUrlStorage());
    expect(find.byType(SwitchListTile), findsNothing);
    expect(find.byType(Switch), findsNothing);
  });

  testWidgets('shows the saved server address', (tester) async {
    await pumpSettings(
        tester, FakeServerUrlStorage('https://notes.example.com/api'));
    expect(find.text('https://notes.example.com/api'), findsOneWidget);
  });

  testWidgets('saves a valid address without trailing slash', (tester) async {
    final storage = FakeServerUrlStorage();
    await pumpSettings(tester, storage);

    await tester.enterText(find.byType(TextField), ' https://example.com/api/ ');
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();

    expect(storage.value, 'https://example.com/api');
    expect(find.text('Адрес сервера сохранён'), findsOneWidget);
  });

  testWidgets('rejects an invalid address and keeps the old one',
      (tester) async {
    final storage = FakeServerUrlStorage('https://old.example.com/api');
    await pumpSettings(tester, storage);

    await tester.enterText(find.byType(TextField), 'not a url');
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();

    expect(storage.value, 'https://old.example.com/api');
    expect(find.textContaining('Введите адрес вида'), findsOneWidget);
  });

  testWidgets('reset removes the saved address', (tester) async {
    final storage = FakeServerUrlStorage('https://example.com/api');
    await pumpSettings(tester, storage);

    await tester.tap(find.text('Сбросить'));
    await tester.pumpAndSettle();

    expect(storage.value, isNull);
  });

  testWidgets('warns about http for hosts blocked by Android', (tester) async {
    await pumpSettings(
        tester, FakeServerUrlStorage('http://192.168.1.135:3000/api'));
    expect(find.textContaining('Android блокирует http'), findsOneWidget);
  });
}
