import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'note_helper.dart';

/// Opens [url] in the external browser.
///
/// Shows a SnackBar when the URL is not a usable http(s) address or when no
/// app can open it, instead of failing silently.
Future<void> openExternalLink(BuildContext context, String? url) async {
  final messenger = ScaffoldMessenger.of(context);
  final uri = url == null ? null : linkUriFromContent(url);

  var opened = false;
  if (uri != null) {
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
  }

  if (!opened) {
    messenger.showSnackBar(
      SnackBar(content: Text('Не удалось открыть ссылку: ${url ?? ''}')),
    );
  }
}
