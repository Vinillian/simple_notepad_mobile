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

  /// Удаляет экранирование перед одиночными латинскими буквами
  String _cleanEscapedLetters(String input) {
    return input.replaceAllMapped(
      RegExp(r'\\([A-Za-z])(?![A-Za-z])'),
          (match) => match.group(1)!,
    );
  }

  /// Преобразует устаревший синтаксис LaTeX
  String _convertOldSyntax(String input) {
    String result = input;
    result = result.replaceAllMapped(RegExp(r'\\\[(.*?)\\\]', dotAll: true), (match) {
      return '\$\$${match.group(1)!.trim()}\$\$';
    });
    result = result.replaceAllMapped(RegExp(r'\\\((.*?)\\\)', dotAll: true), (match) {
      return '\$${match.group(1)!.trim()}\$';
    });
    return result;
  }

  /// Вставляет пробел перед знаком препинания после формулы
  String _fixPunctuationAfterDollar(String input) {
    return input.replaceAllMapped(
      RegExp(r'(\$[^\$]*\$)([;,.\)\]\}])'),
          (match) => '${match.group(1)} ${match.group(2)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    String processed = _cleanEscapedLetters(data);
    processed = _convertOldSyntax(processed);
    processed = _fixPunctuationAfterDollar(processed);

    return MarkdownBody(
      data: processed,
      styleSheet: styleSheet,
      softLineBreak: softLineBreak,
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