import 'package:flutter_test/flutter_test.dart';
import 'package:cliphold/models/enums.dart';
import 'package:cliphold/utils/category_detector.dart';

void main() {
  group('CategoryDetector.detect', () {
    test('detects plain text', () {
      expect(CategoryDetector.detect('Just a normal sentence.'), ClipCategory.text);
    });

    test('detects a bare URL', () {
      expect(CategoryDetector.detect('https://example.com/path?x=1'), ClipCategory.link);
    });

    test('detects a www URL without scheme', () {
      expect(CategoryDetector.detect('www.example.com'), ClipCategory.link);
    });

    test('detects a bare domain', () {
      expect(CategoryDetector.detect('example.com'), ClipCategory.link);
    });

    test('does not classify a sentence containing a dot as a link', () {
      expect(CategoryDetector.detect('This is a sentence. It has periods.'),
          isNot(ClipCategory.link));
    });

    test('detects Dart/JS-like code', () {
      const code = '''
function add(a, b) {
  return a + b;
}
''';
      expect(CategoryDetector.detect(code), ClipCategory.code);
    });

    test('detects Python-like code', () {
      const code = 'def add(a, b):\n    return a + b\n';
      expect(CategoryDetector.detect(code), ClipCategory.code);
    });

    test('detects SQL', () {
      const sql = 'SELECT id, name FROM users WHERE active = 1';
      expect(CategoryDetector.detect(sql), ClipCategory.code);
    });

    test('empty content defaults to text', () {
      expect(CategoryDetector.detect(''), ClipCategory.text);
    });
  });

  group('CategoryDetector.hash / normalize', () {
    test('identical content produces identical hash', () {
      final h1 = CategoryDetector.hash('hello world');
      final h2 = CategoryDetector.hash('hello world');
      expect(h1, h2);
    });

    test('surrounding whitespace does not change the hash', () {
      final h1 = CategoryDetector.hash('hello world');
      final h2 = CategoryDetector.hash('  hello world  \n');
      expect(h1, h2);
    });

    test('different content produces different hash', () {
      final h1 = CategoryDetector.hash('hello world');
      final h2 = CategoryDetector.hash('hello there');
      expect(h1, isNot(h2));
    });

    test('normalize trims but preserves internal formatting', () {
      expect(CategoryDetector.normalize('  line1\nline2  '), 'line1\nline2');
    });
  });
}
