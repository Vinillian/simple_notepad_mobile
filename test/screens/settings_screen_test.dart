import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_notepad_mobile/screens/settings_screen.dart';
import 'package:simple_notepad_mobile/services/local_app_state_service.dart';

class FakeAppState extends LocalAppStateService {
  FakeAppState(this.enabled);

  bool enabled;

  @override
  Future<bool> isLinkPreviewEnabled() async => enabled;

  @override
  Future<void> setLinkPreviewEnabled(bool value) async {
    enabled = value;
  }
}

Future<void> pumpSettings(WidgetTester tester, FakeAppState appState) async {
  await tester.pumpWidget(
    MaterialApp(home: SettingsScreen(appState: appState)),
  );
  await tester.pumpAndSettle();
}

SwitchListTile previewSwitch(WidgetTester tester) =>
    tester.widget<SwitchListTile>(find.byType(SwitchListTile));

void main() {
  testWidgets('shows the stored state of the link previews switch',
      (tester) async {
    await pumpSettings(tester, FakeAppState(true));
    expect(previewSwitch(tester).value, isTrue);
  });

  testWidgets('shows the switch as off when previews are disabled',
      (tester) async {
    await pumpSettings(tester, FakeAppState(false));
    expect(previewSwitch(tester).value, isFalse);
  });

  testWidgets('saves the new value when the switch is tapped', (tester) async {
    final appState = FakeAppState(true);
    await pumpSettings(tester, appState);

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    expect(appState.enabled, isFalse);
    expect(previewSwitch(tester).value, isFalse);
  });
}
