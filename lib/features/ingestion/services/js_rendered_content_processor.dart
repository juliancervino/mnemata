import 'dart:convert';

import 'package:html/parser.dart' as html_parser;
import 'package:metadata_fetch/metadata_fetch.dart';
import 'package:mnemata/features/ingestion/services/extraction_service.dart';

class JsRenderedExtractionResult {
  final String title;
  final String content;
  final String? thumbnailUrl;

  const JsRenderedExtractionResult({
    required this.title,
    required this.content,
    required this.thumbnailUrl,
  });
}

class JsRenderedContentProcessor {
  final ReadabilityWrapper _readabilityWrapper;

  JsRenderedContentProcessor([ReadabilityWrapper? readabilityWrapper])
      : _readabilityWrapper = readabilityWrapper ?? ReadabilityWrapper();

  Future<JsRenderedExtractionResult> extractFromCapturedHtml({
    required String sourceUrl,
    required String rawHtml,
  }) async {
    final document = html_parser.parse(rawHtml);
    final metadata = MetadataParser.parse(document, url: sourceUrl);

    final root = document.querySelector('article') ??
        document.querySelector('main') ??
        document.body;

    if (root != null) {
      root
          .querySelectorAll('script, style, noscript, iframe')
          .toList()
          .forEach((e) => e.remove());
      root.querySelectorAll('*').forEach((e) {
        e.attributes.remove('style');
      });
    }

    final fallbackHtml = root?.innerHtml ?? rawHtml;
    final cleanedFallbackHtml = _removeBlockingMessageSections(fallbackHtml);

    String finalTitle = metadata.title?.trim() ?? '';
    String finalContent = cleanedFallbackHtml;

    try {
      final article = await _readabilityWrapper.parseHtml(
        _buildReadableHtml(
          sourceUrl: sourceUrl,
          fallbackTitle: finalTitle.isNotEmpty ? finalTitle : sourceUrl,
          content: cleanedFallbackHtml,
        ),
      );

      final parsedTitle = article?.title?.trim() ?? '';
      final parsedContent = article?.content?.trim() ?? '';

      if (parsedTitle.isNotEmpty) {
        finalTitle = parsedTitle;
      }
      if (parsedContent.isNotEmpty) {
        finalContent = _removeBlockingMessageSections(parsedContent);
      }
    } catch (_) {
      // Keep best-effort fallback if readability native layer is unavailable.
    }

    if (finalTitle.isEmpty) {
      finalTitle =
          document.querySelector('h1')?.text.trim() ?? metadata.title ?? sourceUrl;
    }

    final thumb = metadata.image ?? _extractFirstImage(finalContent, sourceUrl);

    return JsRenderedExtractionResult(
      title: finalTitle,
      content: finalContent,
      thumbnailUrl: thumb,
    );
  }

  String _buildReadableHtml({
    required String sourceUrl,
    required String fallbackTitle,
    required String content,
  }) {
    final escapedTitle = htmlEscape.convert(fallbackTitle);
    return '<!doctype html><html><head><meta charset="utf-8"><title>$escapedTitle</title><base href="$sourceUrl"></head><body><article>$content</article></body></html>';
  }

  String _removeBlockingMessageSections(String htmlContent) {
    final doc = html_parser.parse(htmlContent);
    final blockers = [
      'please enable js',
      'enable javascript',
      'disable any ad blocker',
      'disable your ad blocker',
      'javascript is disabled',
    ];

    final nodes = doc.querySelectorAll('div, section, p, article, main');
    for (final node in nodes) {
      final text = node.text.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
      if (text.isEmpty) continue;
      if (blockers.any(text.contains)) {
        node.remove();
      }
    }

    return doc.body?.innerHtml.trim() ?? htmlContent;
  }

  String? _extractFirstImage(String htmlContent, String baseUrl) {
    final doc = html_parser.parse(htmlContent);
    final src = doc.querySelector('img[src]')?.attributes['src']?.trim();
    if (src == null || src.isEmpty) return null;

    try {
      return Uri.parse(baseUrl).resolve(src).toString();
    } catch (_) {
      return src;
    }
  }
}
