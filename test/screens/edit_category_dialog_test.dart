import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_notepad_mobile/models/category.dart';
import 'package:simple_notepad_mobile/screens/categories_screen.dart';

Category category() =>
    Category(id: 'c1', name: 'Work', color: '#FF0000', custom: 1);

/// A button that opens the dialog and hands over what the dialog returned.
Widget harness(
  void Function(Category?) onResult, {
  bool Function(String name)? isNameTaken,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: ElevatedButton(
            onPressed: () async {
              final result = await showDialog<Category>(
                context: context,
                builder: (_) => EditCategoryDialog(
                  category: category(),
                  isNameTaken: isNameTaken ?? (_) => false,
                ),
              );
              onResult(result);
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
}

Future<void> openDialog(WidgetTester tester) async {
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the current name', (tester) async {
    await tester.pumpWidget(harness((_) {}));
    await openDialog(tester);

    expect(find.text('Редактировать категорию'), findsOneWidget);
    expect(find.text('Work'), findsOneWidget);
  });

  testWidgets('saving returns the category with the new name', (tester) async {
    var called = false;
    Category? result;
    await tester.pumpWidget(harness((c) {
      called = true;
      result = c;
    }));
    await openDialog(tester);

    await tester.enterText(find.byType(TextFormField), '  Home  ');
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();

    expect(called, isTrue);
    expect(result, isNotNull);
    expect(result!.id, 'c1');
    expect(result!.name, 'Home');
    expect(result!.color, '#FF0000');
    expect(result!.custom, 1);
  });

  testWidgets('refuses an empty name and stays open', (tester) async {
    var called = false;
    await tester.pumpWidget(harness((_) => called = true));
    await openDialog(tester);

    await tester.enterText(find.byType(TextFormField), '   ');
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();

    expect(find.text('Введите название'), findsOneWidget);
    expect(find.text('Редактировать категорию'), findsOneWidget);
    expect(called, isFalse);
  });

  testWidgets('refuses a name another category already has', (tester) async {
    var called = false;
    await tester.pumpWidget(harness(
      (_) => called = true,
      isNameTaken: (name) => name.trim().toLowerCase() == 'home',
    ));
    await openDialog(tester);

    await tester.enterText(find.byType(TextFormField), 'Home');
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();

    expect(
      find.text('Категория с таким названием уже существует'),
      findsOneWidget,
    );
    expect(called, isFalse);
  });

  testWidgets('saving without changes returns null', (tester) async {
    var called = false;
    Category? result = category();
    await tester.pumpWidget(harness((c) {
      called = true;
      result = c;
    }));
    await openDialog(tester);

    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();

    expect(called, isTrue);
    expect(result, isNull);
  });

  testWidgets('cancel returns null', (tester) async {
    var called = false;
    Category? result = category();
    await tester.pumpWidget(harness((c) {
      called = true;
      result = c;
    }));
    await openDialog(tester);

    await tester.enterText(find.byType(TextFormField), 'Other');
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();

    expect(called, isTrue);
    expect(result, isNull);
  });
}
