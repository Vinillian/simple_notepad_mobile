import 'package:flutter_test/flutter_test.dart';
import 'package:simple_notepad_mobile/utils/latex_preprocessor.dart';

void main() {
  group('cleanEscapedLetters', () {
    test('removes the backslash before a single Latin letter', () {
      expect(cleanEscapedLetters(r'\g and \S'), 'g and S');
    });

    test('keeps LaTeX commands intact', () {
      expect(
        cleanEscapedLetters(r'\frac{1}{2} + \sqrt{x}'),
        r'\frac{1}{2} + \sqrt{x}',
      );
    });

    test('leaves text without backslashes unchanged', () {
      expect(cleanEscapedLetters('plain text'), 'plain text');
    });
  });

  group('convertOldLatexSyntax', () {
    test(r'converts \[ ... \] to $$ ... $$', () {
      expect(convertOldLatexSyntax(r'\[x^2\]'), r'$$x^2$$');
    });

    test(r'converts \( ... \) to $ ... $ and trims spaces', () {
      expect(convertOldLatexSyntax(r'\( a+b \)'), r'$a+b$');
    });

    test('handles multi-line display formulas', () {
      expect(convertOldLatexSyntax('\\[\n  x^2\n\\]'), r'$$x^2$$');
    });

    test('converts several formulas in one text', () {
      expect(
        convertOldLatexSyntax(r'Inline \(x\) and display \[y\]'),
        r'Inline $x$ and display $$y$$',
      );
    });

    test('leaves text without old-style formulas unchanged', () {
      expect(convertOldLatexSyntax(r'Already $x$ here'), r'Already $x$ here');
    });
  });

  group('fixPunctuationAfterDollar', () {
    test('inserts a space between a formula and a following period', () {
      expect(fixPunctuationAfterDollar(r'Value $x$.'), r'Value $x$ .');
    });

    test('handles a closing parenthesis after a formula', () {
      expect(fixPunctuationAfterDollar(r'($a$)'), r'($a$ )');
    });

    test('handles several formulas followed by punctuation', () {
      expect(
        fixPunctuationAfterDollar(r'$a$, $b$;'),
        r'$a$ , $b$ ;',
      );
    });

    test('leaves a formula followed by a space unchanged', () {
      expect(fixPunctuationAfterDollar(r'$x$ is here'), r'$x$ is here');
    });

    test('leaves text without formulas unchanged', () {
      expect(
        fixPunctuationAfterDollar('no formulas, just text.'),
        'no formulas, just text.',
      );
    });
  });

  group('preprocessLatex', () {
    test('applies all steps in order', () {
      expect(
        preprocessLatex(r'Formula \(a+b\), done'),
        r'Formula $a+b$ , done',
      );
    });

    test('cleans escaped letters but keeps LaTeX commands', () {
      expect(
        preprocessLatex(r'\g and \frac{1}{2}'),
        r'g and \frac{1}{2}',
      );
    });

    test('leaves plain text unchanged', () {
      expect(preprocessLatex('Just a note.'), 'Just a note.');
    });
  });
}
