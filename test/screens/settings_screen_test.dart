import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_notepad_mobile/screens/settings_screen.dart';

Future<void> pumpSettings(WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the privacy note', (tester) async {
    await pumpSettings(tester);
    expect(find.text('Настройки'), findsOneWidget);
    expect(find.text('Приватность'), findsOneWidget);
  });

  testWidgets('has no link previews switch any more', (tester) async {
    await pumpSettings(tester);
    expect(find.byType(SwitchListTile), findsNothing);
    expect(find.byType(Switch), findsNothing);
  });
}
