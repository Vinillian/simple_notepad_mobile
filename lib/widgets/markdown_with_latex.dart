import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md; // необходим для md.Element

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
    final processed = _preprocess(data);
    return MarkdownBody(
      data: processed.text,
      styleSheet: styleSheet,
      softLineBreak: softLineBreak,
      builders: {
        'latex': LatexBuilder(styleSheet: styleSheet),
      },
    );
  }

  _ProcessedText _preprocess(String input) {
    // Блочные формулы $$...$$
    final blockRegex = RegExp(r'\$\$(.*?)\$\$', dotAll: true);
    String text = input;
    int counter = 0;
    Map<int, String> blocks = {};
    text = text.replaceAllMapped(blockRegex, (match) {
      final formula = match.group(1)!.trim();
      final key = counter++;
      blocks[key] = formula;
      return '<latex block="$key"/>';
    });

    // Строчные формулы $...$
    final inlineRegex = RegExp(r'\$(.*?)\$');
    Map<int, String> inlines = {};
    text = text.replaceAllMapped(inlineRegex, (match) {
      final formula = match.group(1)!.trim();
      if (formula.isEmpty) return match.group(0)!;
      final key = counter++;
      inlines[key] = formula;
      return '<latex inline="$key"/>';
    });

    return _ProcessedText(text, blocks: blocks, inlines: inlines);
  }
}

class _ProcessedText {
  final String text;
  final Map<int, String> blocks;
  final Map<int, String> inlines;

  _ProcessedText(this.text, {required this.blocks, required this.inlines});
}

class LatexBuilder extends MarkdownElementBuilder {
  final MarkdownStyleSheet? styleSheet;

  LatexBuilder({this.styleSheet});

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final attrs = element.attributes;
    if (attrs['block'] != null) {
      final formula = attrs['block']!;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Math.tex(
          formula,
          mathStyle: MathStyle.display,
          textStyle: styleSheet?.p?.copyWith(fontSize: 16),
        ),
      );
    } else if (attrs['inline'] != null) {
      final formula = attrs['inline']!;
      return Math.tex(
        formula,
        mathStyle: MathStyle.text,
        textStyle: preferredStyle,
      );
    }
    return null;
  }
}