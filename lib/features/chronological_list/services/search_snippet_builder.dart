import 'package:mnemata/core/database/app_database.dart';

class SearchSnippetSegment {
  const SearchSnippetSegment({required this.text, required this.highlighted});

  final String text;
  final bool highlighted;
}

class SearchSnippet {
  const SearchSnippet({required this.text, required this.segments});

  final String text;
  final List<SearchSnippetSegment> segments;
}

class SearchSnippetBuilder {
  const SearchSnippetBuilder({
    this.contextWindow = 64,
    this.maxSnippetLength = 180,
  });

  final int contextWindow;
  final int maxSnippetLength;

  SearchSnippet build({required MnemataItem item, required String query}) {
    final tokens = _queryTokens(query);
    final source = _sourceText(item);

    if (source.isEmpty) {
      return const SearchSnippet(text: '', segments: <SearchSnippetSegment>[]);
    }

    final normalized = source.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.isEmpty) {
      return const SearchSnippet(text: '', segments: <SearchSnippetSegment>[]);
    }

    if (tokens.isEmpty) {
      final plain = _truncate(normalized, maxSnippetLength);
      return SearchSnippet(
        text: plain,
        segments: <SearchSnippetSegment>[
          SearchSnippetSegment(text: plain, highlighted: false),
        ],
      );
    }

    final lower = normalized.toLowerCase();
    int hitStart = -1;
    int hitLength = 0;

    for (final token in tokens) {
      final idx = lower.indexOf(token);
      if (idx == -1) {
        continue;
      }
      if (hitStart == -1 || idx < hitStart) {
        hitStart = idx;
        hitLength = token.length;
      }
    }

    if (hitStart == -1) {
      final plain = _truncate(normalized, maxSnippetLength);
      return SearchSnippet(
        text: plain,
        segments: <SearchSnippetSegment>[
          SearchSnippetSegment(text: plain, highlighted: false),
        ],
      );
    }

    var start = hitStart - contextWindow;
    if (start < 0) {
      start = 0;
    }

    var end = hitStart + hitLength + contextWindow;
    if (end > normalized.length) {
      end = normalized.length;
    }

    if (end - start > maxSnippetLength) {
      end = (start + maxSnippetLength).clamp(0, normalized.length);
    }

    var snippet = normalized.substring(start, end).trim();
    if (start > 0) {
      snippet = '...$snippet';
    }
    if (end < normalized.length) {
      snippet = '$snippet...';
    }

    return SearchSnippet(
      text: snippet,
      segments: _highlightSegments(snippet, tokens),
    );
  }

  List<String> _queryTokens(String query) {
    final tokens = query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .map((token) => token.trim())
        .where((token) => token.length >= 2)
        .toList(growable: false);
    return tokens.toSet().toList(growable: false);
  }

  String _sourceText(MnemataItem item) {
    final content = item.content?.trim();
    if (content != null && content.isNotEmpty) {
      return content;
    }

    final title = item.title?.trim();
    if (title != null && title.isNotEmpty) {
      return title;
    }

    final url = item.url?.trim();
    if (url != null && url.isNotEmpty) {
      return url;
    }

    return item.filePath?.split('/').last.trim() ?? '';
  }

  String _truncate(String text, int maxChars) {
    if (text.length <= maxChars) {
      return text;
    }
    return '${text.substring(0, maxChars - 3).trimRight()}...';
  }

  List<SearchSnippetSegment> _highlightSegments(
    String snippet,
    List<String> tokens,
  ) {
    if (snippet.isEmpty) {
      return const <SearchSnippetSegment>[];
    }

    final escaped = tokens.map(RegExp.escape).join('|');
    final regexp = RegExp('($escaped)', caseSensitive: false);
    final matches = regexp.allMatches(snippet).toList(growable: false);

    if (matches.isEmpty) {
      return <SearchSnippetSegment>[
        SearchSnippetSegment(text: snippet, highlighted: false),
      ];
    }

    final segments = <SearchSnippetSegment>[];
    var cursor = 0;

    for (final match in matches) {
      if (match.start > cursor) {
        segments.add(
          SearchSnippetSegment(
            text: snippet.substring(cursor, match.start),
            highlighted: false,
          ),
        );
      }
      segments.add(
        SearchSnippetSegment(
          text: snippet.substring(match.start, match.end),
          highlighted: true,
        ),
      );
      cursor = match.end;
    }

    if (cursor < snippet.length) {
      segments.add(
        SearchSnippetSegment(
          text: snippet.substring(cursor),
          highlighted: false,
        ),
      );
    }

    return segments;
  }
}
