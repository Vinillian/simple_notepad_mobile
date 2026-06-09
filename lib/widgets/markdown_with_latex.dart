import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_markdown_latex/flutter_markdown_latex.dart';
import 'package:markdown/markdown.dart' as md;

class MarkdownWithLatex extends StatelessWidget {
  final String data;
  final MarkdownStyleSheet? styleSheet;
  final bool softLineBreak;

  const MarkdownWithLatex({
    super.key,
    required this.data,
    this.styleSheet,
    this.softLineBreak = true,
  });

  /// Преобразует старый синтаксис LaTeX в формат, понятный flutter_markdown_latex.
  /// \( ... \) → $ ... $
  /// \[ ... \] → $$ ... $$
  String _preprocess(String input) {
    // Блочные формулы \[ ... \] → $$ ... $$
    final blockRegex = RegExp(r'\\\[(.*?)\\\]', dotAll: true);
    String result = input.replaceAllMapped(blockRegex, (match) {
      String formula = match.group(1)!.trim();
      return '\$\$$formula\$\$';
    });

    // Строчные формулы \( ... \) → $ ... $
    final inlineRegex = RegExp(r'\\\((.*?)\\\)', dotAll: true);
    result = result.replaceAllMapped(inlineRegex, (match) {
      String formula = match.group(1)!.trim();
      return '\$$formula\$';
    });

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final processedText = _preprocess(data);
    return MarkdownBody(
      data: processedText,
      styleSheet: styleSheet,
      softLineBreak: softLineBreak,
      builders: {
        'latex': LatexElementBuilder(),
      },
      extensionSet: md.ExtensionSet(
        [LatexBlockSyntax()],
        [LatexInlineSyntax()],
      ),
    );
  }
}