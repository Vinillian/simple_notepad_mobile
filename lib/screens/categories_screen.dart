import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../providers/categories_provider.dart';
import '../providers/notes_provider.dart';
import '../widgets/loading_indicator.dart';
import '../utils/helpers.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  Color _selectedColor = Colors.green;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createCategory() async {
    if (!_formKey.currentState!.validate()) return;

    final colorHex = colorToHex(_selectedColor);

    final newCategory = Category(
      id: 'cat_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      color: colorHex,
      custom: 1,
    );

    try {
      await ref
          .read(categoriesNotifierProvider.notifier)
          .addCategory(newCategory);
      if (mounted) {
        _nameController.clear();
        setState(() => _selectedColor = Colors.green);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Категория создана')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  /// Whether another category already has this name (ignoring case).
  bool _isNameTaken(String name, {String? exceptId}) {
    final categories =
        ref.read(categoriesNotifierProvider).valueOrNull ?? const <Category>[];
    final lower = name.trim().toLowerCase();
    return categories
        .any((c) => c.id != exceptId && c.name.toLowerCase() == lower);
  }

  Future<void> _editCategory(Category category) async {
    final edited = await showDialog<Category>(
      context: context,
      builder: (ctx) => EditCategoryDialog(
        category: category,
        isNameTaken: (name) => _isNameTaken(name, exceptId: category.id),
      ),
    );
    if (edited == null) return;

    try {
      await ref
          .read(categoriesNotifierProvider.notifier)
          .updateCategory(edited);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Категория сохранена')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  Future<void> _deleteCategory(Category category) async {
    if (category.id == 'all') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Нельзя удалить системную категорию')),
        );
      }
      return;
    }

    final notes = await ref
        .read(notesNotifierProvider(category: category.id, sort: 'new').future);

    if (notes.isNotEmpty) {
      // Проверяем, что виджет ещё существует перед показом диалога
      if (!mounted) return;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Удаление категории'),
          content: Text(
            'В категории "${category.name}" есть ${notes.length} заметок. '
                'При удалении категории они тоже будут удалены. Продолжить?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Удалить'),
            ),
          ],
        ),
      );
      if (confirm != true) return;

      for (final note in notes) {
        await ref
            .read(notesNotifierProvider(category: category.id).notifier)
            .deleteNote(note.id);
      }
    }

    try {
      await ref
          .read(categoriesNotifierProvider.notifier)
          .deleteCategory(category.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Категория "${category.name}" удалена')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление категориями'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Новая категория',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Название',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Введите название';
                          }
                          if (_isNameTaken(value)) {
                            return 'Категория с таким названием уже существует';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text('Цвет: '),
                          const SizedBox(width: 8),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _selectedColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final color = await showDialog<Color>(
                                  context: context,
                                  builder: (ctx) => SimpleColorPicker(
                                      initialColor: _selectedColor),
                                );
                                if (color != null) {
                                  setState(() => _selectedColor = color);
                                }
                              },
                              child: Container(
                                padding:
                                const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child:
                                const Center(child: Text('Выбрать цвет')),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _createCategory,
                          child: const Text('Создать категорию'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Существующие категории',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: categoriesAsync.when(
                data: (categories) {
                  return ListView.builder(
                    itemCount: categories.length,
                    itemBuilder: (ctx, i) {
                      final cat = categories[i];
                      return ListTile(
                        leading: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: hexToColor(cat.color),
                            shape: BoxShape.circle,
                          ),
                        ),
                        title: Text(cat.name),
                        subtitle: Text(
                            cat.custom == 1 ? 'Пользовательская' : 'Системная'),
                        onTap: cat.custom == 1 ? () => _editCategory(cat) : null,
                        trailing: cat.custom == 1
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Изменить',
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _editCategory(cat),
                                  ),
                                  IconButton(
                                    tooltip: 'Удалить',
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () => _deleteCategory(cat),
                                  ),
                                ],
                              )
                            : null,
                      );
                    },
                  );
                },
                error: (e, s) => Center(child: Text('Ошибка: $e')),
                loading: () => const LoadingIndicator(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SimpleColorPicker extends StatelessWidget {
  final Color initialColor;
  const SimpleColorPicker({super.key, required this.initialColor});

  final List<Color> colors = const [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
    Colors.black,
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Выберите цвет'),
      content: SizedBox(
        width: 300,
        height: 400,
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: colors.length,
          itemBuilder: (ctx, i) {
            final color = colors[i];
            return GestureDetector(
              onTap: () => Navigator.pop(context, color),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: color == initialColor
                      ? Border.all(color: Colors.black, width: 3)
                      : null,
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
      ],
    );
  }
}

/// `#RRGGBB` for a color, the way categories store it.
String colorToHex(Color color) =>
    '#${color.toARGB32().toRadixString(16).substring(2, 8).toUpperCase()}';

/// Dialog to rename a category and change its color. Closes with the changed
/// copy of the category, or with null when nothing was changed or the dialog
/// was cancelled.
class EditCategoryDialog extends StatefulWidget {
  final Category category;

  /// Tells whether another category already has the given name.
  final bool Function(String name) isNameTaken;

  const EditCategoryDialog({
    super.key,
    required this.category,
    required this.isNameTaken,
  });

  @override
  State<EditCategoryDialog> createState() => _EditCategoryDialogState();
}

class _EditCategoryDialogState extends State<EditCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController =
      TextEditingController(text: widget.category.name);
  late Color _color = hexToColor(widget.category.color);

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickColor() async {
    final color = await showDialog<Color>(
      context: context,
      builder: (ctx) => SimpleColorPicker(initialColor: _color),
    );
    if (color != null) setState(() => _color = color);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();
    final colorHex = colorToHex(_color);
    final unchanged = name == widget.category.name &&
        colorHex == widget.category.color.toUpperCase();
    if (unchanged) {
      Navigator.pop(context);
      return;
    }
    Navigator.pop(
      context,
      Category(
        id: widget.category.id,
        name: name,
        color: colorHex,
        custom: widget.category.custom,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Редактировать категорию'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Название',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите название';
                  }
                  if (widget.isNameTaken(value)) {
                    return 'Категория с таким названием уже существует';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _pickColor,
                      child: const Text('Выбрать цвет'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        TextButton(
          onPressed: _save,
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}
