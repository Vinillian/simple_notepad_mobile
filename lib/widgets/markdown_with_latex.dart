import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_markdown_latex/flutter_markdown_latex.dart';
import 'package:markdown/markdown.dart' as md;
import '../utils/latex_preprocessor.dart';
import '../utils/link_launcher.dart';

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

  @override
  Widget build(BuildContext context) {
    final processed = preprocessLatex(data);

    return MarkdownBody(
      data: processed,
      styleSheet: styleSheet,
      softLineBreak: softLineBreak,
      onTapLink: (text, href, title) => openExternalLink(context, href),
      builders: {
        'latex': LatexElementBuilder(),
      },
      // Объединяем стандартный GFM (таблицы, зачёркивание) с LaTeX-синтаксисами
      extensionSet: md.ExtensionSet(
        [
          ...md.ExtensionSet.gitHubFlavored.blockSyntaxes,
          LatexBlockSyntax(),
        ],
        [
          ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
          LatexInlineSyntax(),
        ],
      ),
    );
  }
}