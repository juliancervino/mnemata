import 'package:flutter_test/flutter_test.dart';
import 'package:mnemata/features/reader/utils/markdown_converter.dart';

void main() {
  group('MarkdownConverter', () {
    test('should separate paragraph from header without blank line', () {
      const markdown = 'Paragraph\n# Header';
      final html = MarkdownConverter.convertToHtml(markdown);
      
      expect(html, contains('<p>Paragraph</p>'));
      expect(html, contains('<h1>Header</h1>'));
      expect(html, isNot(contains('<p>Paragraph<br><h1>Header</h1></p>')));
    });

    test('should separate paragraph from list without blank line', () {
      const markdown = 'Paragraph\n* Item 1';
      final html = MarkdownConverter.convertToHtml(markdown);
      
      expect(html, contains('<p>Paragraph</p>'));
      expect(html, contains('<ul><li>Item 1</li></ul>'));
      expect(html, isNot(contains('<p>Paragraph<br><ul>')));
    });

    test('should handle bold and italic', () {
      const markdown = 'Normal **Bold** and *Italic*';
      final html = MarkdownConverter.convertToHtml(markdown);
      
      expect(html, contains('<strong>Bold</strong>'));
      expect(html, contains('<em>Italic</em>'));
    });

    test('should wrap multiple lines in same block with <br>', () {
      const markdown = 'Line 1\nLine 2';
      final html = MarkdownConverter.convertToHtml(markdown);
      
      expect(html, contains('<p>Line 1<br>Line 2</p>'));
    });

    test('should remove frontmatter', () {
      const markdown = '---\ntitle: test\n---\nContent';
      final html = MarkdownConverter.convertToHtml(markdown);
      
      expect(html, contains('<p>Content</p>'));
      expect(html, isNot(contains('title: test')));
    });
  });
}
