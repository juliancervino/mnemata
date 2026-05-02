import 'dart:convert';

class MarkdownConverter {
  static String convertToHtml(String markdown) {
    var html = markdown.trim();
    // Remove frontmatter if present
    if (html.startsWith('---')) {
      final parts = html.split('---');
      if (parts.length >= 3) {
        html = parts.sublist(2).join('---').trim();
      }
    }

    // Escape HTML characters to prevent injection/rendering issues
    html = htmlEscape.convert(html);

    // Standardize newlines
    html = html.replaceAll('\r\n', '\n');

    // Headers
    html = html.replaceAllMapped(RegExp(r'^(#+)\s+(.+)$', multiLine: true), (Match match) {
      final level = match.group(1)!.length;
      final text = match.group(2)!;
      return '\n\n<h$level>$text</h$level>\n\n';
    });

    // Bold
    html = html.replaceAllMapped(RegExp(r'\*\*(.+?)\*\*'), (Match match) {
      return '<strong>${match.group(1)}</strong>';
    });

    // Italic
    html = html.replaceAllMapped(RegExp(r'\*(.+?)\*'), (Match match) {
      return '<em>${match.group(1)}</em>';
    });

    // Lists
    html = html.replaceAllMapped(RegExp(r'^[*-]\s+(.+)$', multiLine: true), (Match match) {
      return '<li>${match.group(1)}</li>';
    });
    // Wrap consecutive <li> in <ul> (simple approximation)
    html = html.replaceAllMapped(RegExp(r'(<li>.*?</li>)+', dotAll: true), (Match match) {
      return '\n\n<ul>${match.group(0)}</ul>\n\n';
    });

    // Paragraphs (double newlines)
    // We split by double newlines and wrap each non-empty, non-block segment in <p>
    final blocks = html.split(RegExp(r'\n\n+'));
    html = blocks.map((block) {
      final trimmed = block.trim();
      if (trimmed.isEmpty) return '';
      // List of block-level tags that should NOT be wrapped in <p>
      final isBlock = RegExp(r'^<(h\d|ul|ol|li|blockquote|pre|p|div|hr)\b', caseSensitive: false).hasMatch(trimmed);
      if (isBlock) return trimmed;
      return '<p>${trimmed.replaceAll('\n', '<br>')}</p>';
    }).join('\n');

    return html;
  }
}
