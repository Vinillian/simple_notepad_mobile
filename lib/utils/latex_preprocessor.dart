/// Text pre-processing applied to a note before it is rendered as Markdown
/// with LaTeX formulas.

/// Удаляет экранирование перед одиночными латинскими буквами
String cleanEscapedLetters(String input) {
  return input.replaceAllMapped(
    RegExp(r'\\([A-Za-z])(?![A-Za-z])'),
        (match) => match.group(1)!,
  );
}

/// Преобразует устаревший синтаксис LaTeX
String convertOldLatexSyntax(String input) {
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
String fixPunctuationAfterDollar(String input) {
  return input.replaceAllMapped(
    RegExp(r'(\$[^\$]*\$)([;,.\)\]\}])'),
        (match) => '${match.group(1)} ${match.group(2)}',
  );
}

/// Runs all pre-processing steps in the order used by `MarkdownWithLatex`.
String preprocessLatex(String input) {
  var result = cleanEscapedLetters(input);
  result = convertOldLatexSyntax(result);
  result = fixPunctuationAfterDollar(result);
  return result;
}
