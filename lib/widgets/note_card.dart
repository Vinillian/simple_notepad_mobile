import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/note.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const NoteCard({
    super.key,
    required this.note,
    this.onTap,
    this.onDelete,
  });

  // Функция для открытия ссылки
  Future<void> _launchUrl() async {
    final url = Uri.parse(note.content);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Не удалось открыть ссылку: $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLink = note.type == 'link';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isLink
            ? null
            : onTap, // если ссылка, отключаем редактирование по нажатию на всю карточку
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Строка с заголовком и датой
              Row(
                children: [
                  if (isLink) ...[
                    Icon(Icons.link,
                        size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                    child: isLink
                        ? GestureDetector(
                            onTap: _launchUrl,
                            child: Text(
                              note.title ?? 'Открыть ссылку',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                                decoration: TextDecoration.underline,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          )
                        : Text(
                            note.title ?? 'Без заголовка',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                  ),
                  Text(
                    note.date,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Содержимое заметки
              if (isLink) ...[
                // Для ссылок показываем URL и короткое описание (если есть)
                GestureDetector(
                  onTap: _launchUrl,
                  child: Text(
                    note.content,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (note.metadata != null &&
                    note.metadata!.containsKey('description'))
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      note.metadata!['description'] as String,
                      style: theme.textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ] else ...[
                // Обычные заметки
                Text(
                  note.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ],

              // Кнопка удаления
              if (onDelete != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.bottomRight,
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    color: theme.colorScheme.error,
                    onPressed: onDelete,
                    iconSize: 20,
                    splashRadius: 20,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
