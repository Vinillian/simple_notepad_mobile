import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_notepad_mobile/models/category.dart';
import 'package:simple_notepad_mobile/widgets/category_chip.dart';

Category category(String color) =>
    Category(id: 'c1', name: 'Work', color: color, custom: 1);

Widget wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  testWidgets('shows the category name', (tester) async {
    await tester.pumpWidget(wrap(CategoryChip(category: category('#FF0000'))));

    expect(find.text('Work'), findsOneWidget);
  });

  testWidgets('does not throw on a malformed color', (tester) async {
    await tester.pumpWidget(wrap(
      CategoryChip(category: category('not-a-color'), isSelected: true),
    ));

    expect(tester.takeException(), isNull);
    expect(find.text('Work'), findsOneWidget);
  });

  testWidgets('selected chip is filled with the category color',
      (tester) async {
    await tester.pumpWidget(wrap(
      CategoryChip(category: category('#FF0000'), isSelected: true),
    ));

    final container = tester.widget<Container>(find.descendant(
      of: find.byType(CategoryChip),
      matching: find.byType(Container),
    ));
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.color, const Color(0xFFFF0000));
  });

  testWidgets('calls onTap when tapped', (tester) async {
    var taps = 0;
    await tester.pumpWidget(wrap(
      CategoryChip(category: category('#FF0000'), onTap: () => taps++),
    ));

    await tester.tap(find.byType(CategoryChip));

    expect(taps, 1);
  });
}
