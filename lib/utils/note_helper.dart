import '../models/note.dart';
import 'helpers.dart';
import 'note_id.dart';

/// Builds the note to save from the edit form.
///
/// When [original] is given, the fields the form does not edit (`expanded`,
/// `editMode`, link `metadata`, `previewText`) are carried over from it.
/// Metadata and preview text describe the content, so they are dropped only
/// when the content really changed; a null metadata makes the notes provider
/// fetch it again for the new link.
///
/// A new note gets [newId], or a generated UUID when it is not given.
Note buildNoteForSave({
  Note? original,
  required String title,
  required String content,
  required String categoryId,
  required String type,
  required DateTime now,
  String? newId,
}) {
  final timestamp = now.millisecondsSinceEpoch;
  final contentChanged =
      original == null || original.content.trim() != content.trim();

  return Note(
    id: original?.id ?? newId ?? generateNoteId(),
    title: title.isEmpty ? null : title,
    content: content,
    categoryId: categoryId,
    date: original?.date ?? formatTimestamp(timestamp),
    createdTimestamp: original?.createdTimestamp ?? timestamp,
    updatedTimestamp: timestamp,
    expanded: original?.expanded ?? 0,
    editMode: original?.editMode ?? 0,
    type: type,
    metadata: contentChanged ? null : original.metadata,
    previewText: contentChanged ? null : original.previewText,
  );
}

/// Title shown in the header of a link card: the note's own title, then the
/// page title from the fetched metadata, then the domain of [url].
String linkCardTitle({
  String? title,
  Map<String, dynamic>? metadata,
  required String url,
}) {
  final own = title?.trim();
  if (own != null && own.isNotEmpty) return own;

  final fetched = metadata?['title'];
  if (fetched is String && fetched.trim().isNotEmpty) return fetched.trim();

  final domain = extractDomain(url);
  if (domain != null && domain.isNotEmpty) return domain;

  return 'Открыть ссылку';
}

/// The URL to open for a link note, or null when the content is not a usable
/// http(s) URL. Surrounding whitespace, such as a trailing newline typed in the
/// editor, is ignored.
Uri? linkUriFromContent(String content) {
  final uri = Uri.tryParse(content.trim());
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;
  if (uri.scheme != 'http' && uri.scheme != 'https') return null;
  return uri;
}
