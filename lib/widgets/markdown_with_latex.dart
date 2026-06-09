import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_markdown_latex/flutter_markdown_latex.dart';
// Импортируем основной пакет markdown для работы с ExtensionSet
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

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: data,
      styleSheet: styleSheet,
      softLineBreak: softLineBreak,
      builders: {
        // 1. Указываем строитель для тега 'latex'
        'latex': LatexElementBuilder(),
      },
      // 2. Указываем расширение для парсера, чтобы он понимал LaTeX
      extensionSet: md.ExtensionSet(
        [LatexBlockSyntax()],   // для блочных формул
        [LatexInlineSyntax()],  // для строчных формул
      ),
    );
  }
}