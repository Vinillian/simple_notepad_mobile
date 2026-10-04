import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../widgets/markdown_with_latex.dart';
import '../models/note.dart';
import '../providers/notes_provider.dart';
import '../providers/categories_provider.dart';
import '../utils/note_helper.dart';

class NoteEditScreen extends ConsumerStatefulWidget {
  final Note? note;

  /// Category preselected for a new note (e.g. the filter active on the home screen).
  final String? initialCategoryId;

  const NoteEditScreen({super.key, this.note, this.initialCategoryId});

  @override
  ConsumerState<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends ConsumerState<NoteEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  String? _selectedCategoryId;
  late bool _isPreviewMode;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController =
        TextEditingController(text: widget.note?.content ?? '');
    _selectedCategoryId = widget.note?.categoryId;

    // A new note starts in edit mode; existing notes open in preview mode.
    _isPreviewMode = widget.note != null;

    if (widget.note == null) {
      _selectedCategoryId = widget.initialCategoryId ?? _firstCategoryId();
    }
  }

  String? _firstCategoryId() {
    final categories = ref.read(categoriesNotifierProvider).valueOrNull;
    if (categories == null || categories.isEmpty) return null;
    return categories.first.id;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate()) return;

    // The content field is not in the widget tree in preview mode, so its
    // validator does not run there. Check the content explicitly.
    if (_contentController.text.trim().isEmpty) {
      setState(() => _isPreviewMode = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите текст')),
      );
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите категорию')),
      );
      return;
    }

    final now = DateTime.now();
    final type = _detectType(_contentController.text);

    final note = buildNoteForSave(
      original: widget.note,
      title: _titleController.text,
      content: _contentController.text,
      categoryId: _selectedCategoryId!,
      type: type,
      now: now,
    );

    try {
      if (widget.note == null) {
        await ref
            .read(notesNotifierProvider(category: _selectedCategoryId).notifier)
            .addNote(note);
      } else {
        await ref
            .read(notesNotifierProvider(category: _selectedCategoryId).notifier)
            .updateNote(note.id, note);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сохранения: $e')),
        );
      }
    }
  }

  String _detectType(String content) {
    final trimmed = content.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return 'link';
    }
    return 'note';
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.note == null
              ? 'Новая заметка'
              : (_isPreviewMode ? 'Просмотр' : 'Редактирование'),
        ),
        actions: [
          IconButton(
            icon: Icon(_isPreviewMode ? Icons.edit : Icons.visibility),
            onPressed: () {
              setState(() {
                _isPreviewMode = !_isPreviewMode;
              });
            },
            tooltip: _isPreviewMode ? 'Редактировать' : 'Предпросмотр',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveNote,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Заголовок (необязательно)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              categoriesAsync.when(
                data: (categories) {
                  return DropdownButtonFormField<String>(
                    initialValue: _selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'Категория',
                      border: OutlineInputBorder(),
                    ),
                    items: categories.map((category) {
                      return DropdownMenuItem(
                        value: category.id,
                        child: Text(category.name),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => _selectedCategoryId = value),
                    validator: (value) =>
                    value == null ? 'Выберите категорию' : null,
                  );
                },
                error: (e, s) => Text('Ошибка загрузки категорий: $e'),
                loading: () => const SizedBox(height: 56),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _isPreviewMode
                    ? SingleChildScrollView(
                  child: MarkdownWithLatex(
                    data: _contentController.text,
                    styleSheet: MarkdownStyleSheet.fromTheme(
                      Theme.of(context),
                    ),
                    softLineBreak: true,
                  ),
                )
                    : TextFormField(
                  controller: _contentController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Текст заметки (поддерживается Markdown и LaTeX)',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Введите текст';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}