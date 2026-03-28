import 'dart:convert';
import 'dart:math';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:metadata_fetch/metadata_fetch.dart';
import 'package:mnemata/features/ingestion/services/extraction_service.dart';

class ArchiveExtractionResult {
  final String title;
  final String content;
  final String? thumbnailUrl;
  final String? originalUrl;

  const ArchiveExtractionResult({
    required this.title,
    required this.content,
    required this.thumbnailUrl,
    this.originalUrl,
  });
}

class _ArchiveCandidate {
  final String html;
  final int textLength;
  final int score;

  const _ArchiveCandidate({
    required this.html,
    required this.textLength,
    required this.score,
  });
}

class ArchiveContentProcessor {
  final ReadabilityWrapper _readabilityWrapper;

  ArchiveContentProcessor([ReadabilityWrapper? readabilityWrapper])
      : _readabilityWrapper = readabilityWrapper ?? ReadabilityWrapper();

  Future<ArchiveExtractionResult> extractFromCapturedHtml({
    required String sourceUrl,
    required String rawHtml,
  }) async {
    final document = html_parser.parse(rawHtml);
    final metadata = MetadataParser.parse(document, url: sourceUrl);
    final title = metadata.title ?? 'Archive.ph Content';
    final thumbnailUrl = metadata.image;
    
    // Extract the original URL from the input field with name="q"
    final originalUrl = document.querySelector('input[name="q"]')?.attributes['value'];

    var contentElement = document.querySelector('#CONTENT') ??
        document.querySelector('#content') ??
        document.body;

    if (contentElement != null) {
      contentElement
          .querySelectorAll('script, style, link, meta, noscript, iframe, .ads')
          .toList()
          .forEach((e) => e.remove());

      contentElement.attributes.remove('style');
      contentElement.querySelectorAll('*').forEach((element) {
        element.attributes.remove('style');
      });
    }

    final content = contentElement?.innerHtml ?? 'HTML Source empty or null';

    var finalTitle = title;
    var finalContent = content;
    String? finalThumbnailUrl = thumbnailUrl;

    if (content.isNotEmpty && content != 'HTML Source empty or null') {
      final cleanedForReadability = prepareContentForReadability(content);
      final candidates = _rankArticleCandidates(cleanedForReadability);

      String? bestContent;
      String? bestTitle;
      var bestScore = -1 << 30;

      for (final candidate in candidates.take(4)) {
        String parsedTitle = '';
        String parsedContent = '';
        try {
          final article = await _readabilityWrapper.parseHtml(
            buildReadableArchiveHtml(
              sourceUrl: sourceUrl,
              content: candidate.html,
              fallbackTitle: title,
            ),
          );
          parsedTitle = article?.title?.trim() ?? '';
          parsedContent = article?.content?.trim() ?? '';
        } catch (_) {
          // Keep fallback path based on sanitized candidate HTML.
        }

        final candidateContent =
            parsedContent.isNotEmpty ? parsedContent : candidate.html;
        final sanitized = sanitizeFinalContent(candidateContent);
        final score = scoreFinalContent(
          sanitized,
          sourceLength: candidate.textLength,
        );

        if (score > bestScore && sanitized.trim().isNotEmpty) {
          bestScore = score;
          bestContent = sanitized;
          bestTitle = parsedTitle;
        }
      }

      if (bestContent != null && bestContent.isNotEmpty) {
        finalContent = bestContent;
      }

      if (bestTitle != null && bestTitle.isNotEmpty) {
        finalTitle = bestTitle;
      }

      if (finalTitle.trim().isEmpty || finalTitle == 'Archive.ph Content') {
        final heading =
            html_parser.parse(finalContent).querySelector('h1')?.text.trim();
        if (heading != null && heading.isNotEmpty) {
          finalTitle = heading;
        }
      }

      final subtitleRoot = contentElement ?? html_parser.parse(content).body;
      if (subtitleRoot != null) {
        final subtitle = extractSubtitleCandidate(
          document: document,
          root: subtitleRoot,
          title: finalTitle,
          metadataDescription: metadata.description,
        );
        if (subtitle != null &&
            subtitle.isNotEmpty &&
            !finalContent.contains(subtitle)) {
          final escapedSubtitle = htmlEscape.convert(subtitle);
          finalContent = '<h2>$escapedSubtitle</h2>\n$finalContent';
        }
      }

      if (finalThumbnailUrl == null || finalThumbnailUrl.isEmpty) {
        finalThumbnailUrl = extractFirstImageUrl(
              finalContent,
              baseUrl: sourceUrl,
            ) ??
            extractFirstImageUrl(content, baseUrl: sourceUrl);
      }
    }

    return ArchiveExtractionResult(
      title: finalTitle,
      content: finalContent,
      thumbnailUrl: finalThumbnailUrl,
      originalUrl: originalUrl,
    );
  }

  String buildReadableArchiveHtml({
    required String sourceUrl,
    required String content,
    required String fallbackTitle,
  }) {
    final escapedTitle = htmlEscape.convert(fallbackTitle);
    return '<!doctype html><html><head><meta charset="utf-8"><title>$escapedTitle</title><base href="$sourceUrl"></head><body><article id="archive-content">$content</article></body></html>';
  }

  String prepareContentForReadability(String htmlContent) {
    final parsed = html_parser.parse(htmlContent);
    const selectorsToRemove = [
      'script',
      'style',
      'noscript',
      'iframe',
      'nav',
      'header',
      'footer',
      'aside',
      '[role="navigation"]',
      '[aria-label*="Most Popular"]',
      '[class*="most-popular"]',
      '[class*="recommended"]',
      '[id*="recommended"]',
      '[id*="navigation"]',
      '[class*="navigation"]',
    ];

    for (final selector in selectorsToRemove) {
      parsed.querySelectorAll(selector).toList().forEach((e) => e.remove());
    }

    return parsed.body?.innerHtml ?? htmlContent;
  }

  List<_ArchiveCandidate> _rankArticleCandidates(String htmlContent) {
    final parsed = html_parser.parse(htmlContent);
    final candidates = <_ArchiveCandidate>[];
    final seen = <int>{};

    for (final node in parsed.querySelectorAll('article, main, section, div')) {
      final text = node.text.replaceAll(RegExp(r'\s+'), ' ').trim();
      final textLength = text.length;
      if (textLength < 280) {
        continue;
      }

      final html = node.innerHtml.trim();
      if (html.isEmpty) {
        continue;
      }

      final hash =
          Object.hash(html.length, textLength, text.substring(0, min(80, text.length)));
      if (seen.contains(hash)) {
        continue;
      }
      seen.add(hash);

      final paragraphs = node.querySelectorAll('p').length;
      final headings = node.querySelectorAll('h1, h2, h3').length;
      final images = node.querySelectorAll('img, figure').length;
      final links = node.querySelectorAll('a').length;
      final formLike = node.querySelectorAll('form, button, input, textarea').length;
      final noiseHits = countNoiseKeywordHits(text);

      var score = 0;
      score += textLength ~/ 45;
      score += paragraphs * 14;
      score += headings * 22;
      score += images * 6;
      score -= links * 2;
      score -= formLike * 18;
      score -= noiseHits * 30;

      final lowerHtml = html.toLowerCase();
      if (lowerHtml.contains('id="__next"')) {
        score -= 120;
      }

      candidates.add(_ArchiveCandidate(
        html: html,
        textLength: textLength,
        score: score,
      ));
    }

    candidates.sort((a, b) => b.score.compareTo(a.score));

    if (candidates.isEmpty) {
      return [
        _ArchiveCandidate(
          html: htmlContent,
          textLength: html_parser.parse(htmlContent).body?.text.trim().length ??
              htmlContent.length,
          score: 0,
        ),
      ];
    }

    return candidates;
  }

  String sanitizeFinalContent(String htmlContent) {
    final parsed = html_parser.parse(htmlContent);
    const directSelectors = [
      'script',
      'style',
      'noscript',
      'iframe',
      'form',
      '[class*="newsletter"]',
      '[id*="newsletter"]',
      '[class*="recommended"]',
      '[id*="recommended"]',
      '[class*="most-popular"]',
      '[id*="most-popular"]',
      '[class*="comments"]',
      '[id*="comments"]',
      '[class*="conversation"]',
      '[id*="conversation"]',
      '[class*="related"]',
      '[id*="related"]',
      '[class*="footer"]',
      '[id*="footer"]',
      '[class*="header"]',
      '[id*="header"]',
      '[class*="navigation"]',
      '[id*="navigation"]',
      '[class*="subscribe"]',
      '[id*="subscribe"]',
      '[class*="share"]',
      '[id*="share"]',
    ];

    for (final selector in directSelectors) {
      parsed.querySelectorAll(selector).toList().forEach((e) => e.remove());
    }

    const headingNoise = [
      'conversation',
      'comentarios',
      'join the conversation',
      'most popular',
      'recommended',
      'more stories',
      'more from',
      'additional links',
      'explore more',
      'further reading',
      'videos',
      'otras webs',
      'related topics',
      'powered by',
    ];

    for (final node in parsed.querySelectorAll('section, div, aside, nav, footer')) {
      final heading =
          node.querySelector('h1, h2, h3, h4, h5, h6')?.text.toLowerCase().trim() ??
              '';
      if (heading.isNotEmpty && headingNoise.any(heading.contains)) {
        node.remove();
      }
    }

    return parsed.body?.innerHtml.trim() ?? htmlContent;
  }

  int scoreFinalContent(String htmlContent, {required int sourceLength}) {
    final parsed = html_parser.parse(htmlContent);
    final text = parsed.body?.text.replaceAll(RegExp(r'\s+'), ' ').trim() ?? '';
    final textLength = text.length;
    if (textLength < 200) {
      return -100000;
    }

    final paragraphs = parsed.querySelectorAll('p').length;
    final links = parsed.querySelectorAll('a').length;
    final images = parsed.querySelectorAll('img, figure').length;
    final noiseHits = countNoiseKeywordHits(text);

    var score = 0;
    score += textLength ~/ 50;
    score += paragraphs * 16;
    score += images * 6;
    score -= links * 2;
    score -= noiseHits * 35;

    if (htmlContent.length >= (sourceLength * 0.95)) {
      score -= 120;
    }

    return score;
  }

  int countNoiseKeywordHits(String text) {
    final lower = text.toLowerCase();
    const keywords = [
      'skip to main content',
      'what to read next',
      'most popular',
      'recommended videos',
      'join the conversation',
      'conversation',
      'comentarios',
      'show comments',
      'additional links',
      'explore more',
      'more stories',
      'newsletter',
      'subscribe',
      'back to top',
      'powered by',
      'terms of use',
      'privacy policy',
      'copyright',
      'cookies',
      'all snapshots',
      'download .zip',
      'report bug or abuse',
      'buy me a coffee',
    ];

    var hits = 0;
    for (final keyword in keywords) {
      if (lower.contains(keyword)) {
        hits++;
      }
    }
    return hits;
  }

  String? extractFirstImageUrl(String htmlContent, {required String baseUrl}) {
    final parsed = html_parser.parse(htmlContent);
    final src = parsed.querySelector('img[src]')?.attributes['src']?.trim();
    if (src == null || src.isEmpty) return null;

    try {
      return Uri.parse(baseUrl).resolve(src).toString();
    } catch (_) {
      return src;
    }
  }

  String? extractSubtitleCandidate({
    required dom.Document document,
    required dom.Element root,
    required String title,
    required String? metadataDescription,
  }) {
    final normalizedTitle = title.trim().toLowerCase();

    bool isGoodCandidate(String value) {
      final text = value.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (text.length < 20 || text.length > 260) return false;
      if (text.toLowerCase() == normalizedTitle) return false;
      if (countNoiseKeywordHits(text) > 0) return false;
      return true;
    }

    final titleElement =
        document.querySelector('h1.entry-title, h1.post-title, h1.article-title, h1');
    if (titleElement != null) {
      dom.Element? sibling = titleElement.nextElementSibling;
      var checked = 0;
      while (sibling != null && checked < 6) {
        final tag = sibling.localName;
        final text = sibling.text;
        if ((tag == 'h2' || tag == 'h3' || tag == 'p') && isGoodCandidate(text)) {
          return text.replaceAll(RegExp(r'\s+'), ' ').trim();
        }
        sibling = sibling.nextElementSibling;
        checked++;
      }
    }

    for (final selector in const ['h2', 'h3', 'p']) {
      for (final node in root.querySelectorAll(selector).take(12)) {
        final text = node.text;
        if (isGoodCandidate(text)) {
          return text.replaceAll(RegExp(r'\s+'), ' ').trim();
        }
      }
    }

    if (metadataDescription != null && isGoodCandidate(metadataDescription)) {
      return metadataDescription.replaceAll(RegExp(r'\s+'), ' ').trim();
    }

    return null;
  }
}
