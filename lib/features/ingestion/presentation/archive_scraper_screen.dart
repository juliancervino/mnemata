import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:metadata_fetch/metadata_fetch.dart';
import 'package:mnemata/features/ingestion/presentation/ingestion_summary_screen.dart';
import 'package:mnemata/features/ingestion/services/extraction_service.dart';

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

class ArchiveScraperScreen extends StatefulWidget {
  final String url;

  const ArchiveScraperScreen({super.key, required this.url});

  @override
  State<ArchiveScraperScreen> createState() => _ArchiveScraperScreenState();
}

class _ArchiveScraperScreenState extends State<ArchiveScraperScreen> {
  late final WebViewController _controller;
  final ReadabilityWrapper _readabilityWrapper = ReadabilityWrapper();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
          "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
      ..loadRequest(Uri.parse(widget.url));
  }

  Future<void> _extractAndContinue() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final Object result = await _controller.runJavaScriptReturningResult(
        "document.documentElement.outerHTML;"
      );

      // runJavaScriptReturningResult can return a JSON-encoded string
      String rawHtml;
      if (result is String) {
        if ((result.startsWith('"') && result.endsWith('"')) ||
            result.startsWith('{') ||
            result.startsWith('[')) {
          try {
            rawHtml = jsonDecode(result) as String;
          } catch (_) {
            rawHtml = result;
          }
        } else {
          rawHtml = result;
        }
      } else {
        rawHtml = result.toString();
      }

      debugPrint('ArchiveScraper: Captured HTML length: ${rawHtml.length}');

      final document = html_parser.parse(rawHtml);

      // Use MetadataParser to get clean metadata from the document
      final metadata = MetadataParser.parse(document, url: widget.url);
      final title = metadata.title ?? 'Archive.ph Content';
      final thumbnailUrl = metadata.image;

      // Select content
      var contentElement = document.querySelector('#CONTENT') ?? 
                           document.querySelector('#content') ??
                           document.body;
      
      if (contentElement != null) {
        // CLEANUP: Remove tags that break mobile layout or add noise
        contentElement.querySelectorAll('script, style, link, meta, noscript, iframe, .ads').toList().forEach((e) => e.remove());

        // FIX: Remove all inline style attributes to prevent absolute positioning/off-screen content
        // Remove from the container itself
        contentElement.attributes.remove('style');
        // And from all its descendants
        contentElement.querySelectorAll('*').forEach((element) {
          element.attributes.remove('style');
        });
      }

      final content = contentElement?.innerHtml ?? "HTML Source empty or null";
      debugPrint('ArchiveScraper: Extracted content length: ${content.length}');

      String finalTitle = title;
      String finalContent = content;
      String? finalThumbnailUrl = thumbnailUrl;

      if (content.isNotEmpty && content != 'HTML Source empty or null') {
        final cleanedForReadability = _prepareContentForReadability(content);
        final candidates = _rankArticleCandidates(cleanedForReadability);

        String? bestContent;
        String? bestTitle;
        var bestScore = -1 << 30;

        for (final candidate in candidates.take(4)) {
          final article = await _readabilityWrapper.parseHtml(
            _buildReadableArchiveHtml(
              content: candidate.html,
              fallbackTitle: title,
            ),
          );

          final parsedTitle = article?.title?.trim() ?? '';
          final parsedContent = article?.content?.trim() ?? '';

          final candidateContent = parsedContent.isNotEmpty
              ? parsedContent
              : candidate.html;
          final sanitized = _sanitizeFinalContent(candidateContent);
          final score = _scoreFinalContent(
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
          final heading = html_parser.parse(finalContent).querySelector('h1')?.text.trim();
          if (heading != null && heading.isNotEmpty) {
            finalTitle = heading;
          }
        }

        final subtitleRoot = contentElement ?? html_parser.parse(content).body;
        if (subtitleRoot != null) {
          final subtitle = _extractSubtitleCandidate(
            document: document,
            root: subtitleRoot,
            title: finalTitle,
            metadataDescription: metadata.description,
          );
          if (subtitle != null && subtitle.isNotEmpty && !finalContent.contains(subtitle)) {
            final escapedSubtitle = htmlEscape.convert(subtitle);
            finalContent = '<h2>$escapedSubtitle</h2>\n$finalContent';
          }
        }

        if (finalThumbnailUrl == null || finalThumbnailUrl.isEmpty) {
          finalThumbnailUrl = _extractFirstImageUrl(finalContent) ?? _extractFirstImageUrl(content);
        }

        debugPrint('ArchiveScraper: Final title: $finalTitle');
        debugPrint('ArchiveScraper: Final content length: ${finalContent.length}');
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => IngestionSummaryScreen(
              type: 'url',
              url: widget.url,
              title: finalTitle,
              content: finalContent,
              thumbnailUrl: finalThumbnailUrl,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Extraction failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  String? _extractFirstImageUrl(String htmlContent) {
    final parsed = html_parser.parse(htmlContent);
    final src = parsed.querySelector('img[src]')?.attributes['src']?.trim();
    if (src == null || src.isEmpty) return null;

    try {
      return Uri.parse(widget.url).resolve(src).toString();
    } catch (_) {
      return src;
    }
  }

  String? _extractSubtitleCandidate({
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
      if (_noiseKeywordHits(text) > 0) return false;
      return true;
    }

    final titleElement = document.querySelector('h1.entry-title, h1.post-title, h1.article-title, h1');
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

  String _buildReadableArchiveHtml({required String content, required String fallbackTitle}) {
    final escapedTitle = htmlEscape.convert(fallbackTitle);
    return '<!doctype html><html><head><meta charset="utf-8"><title>$escapedTitle</title><base href="${widget.url}"></head><body><article id="archive-content">$content</article></body></html>';
  }

  String _prepareContentForReadability(String htmlContent) {
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

      final hash = Object.hash(html.length, textLength, text.substring(0, min(80, text.length)));
      if (seen.contains(hash)) {
        continue;
      }
      seen.add(hash);

      final paragraphs = node.querySelectorAll('p').length;
      final headings = node.querySelectorAll('h1, h2, h3').length;
      final images = node.querySelectorAll('img, figure').length;
      final links = node.querySelectorAll('a').length;
      final formLike = node.querySelectorAll('form, button, input, textarea').length;
      final noiseHits = _noiseKeywordHits(text);

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
          textLength: html_parser.parse(htmlContent).body?.text.trim().length ?? htmlContent.length,
          score: 0,
        ),
      ];
    }

    return candidates;
  }

  String _sanitizeFinalContent(String htmlContent) {
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
      final heading = node.querySelector('h1, h2, h3, h4, h5, h6')?.text.toLowerCase().trim() ?? '';
      if (heading.isNotEmpty && headingNoise.any(heading.contains)) {
        node.remove();
      }
    }

    return parsed.body?.innerHtml.trim() ?? htmlContent;
  }

  int _scoreFinalContent(String htmlContent, {required int sourceLength}) {
    final parsed = html_parser.parse(htmlContent);
    final text = parsed.body?.text.replaceAll(RegExp(r'\s+'), ' ').trim() ?? '';
    final textLength = text.length;
    if (textLength < 200) {
      return -100000;
    }

    final paragraphs = parsed.querySelectorAll('p').length;
    final links = parsed.querySelectorAll('a').length;
    final images = parsed.querySelectorAll('img, figure').length;
    final noiseHits = _noiseKeywordHits(text);

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

  int _noiseKeywordHits(String text) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Archive Content Extraction'),
        actions: [
          if (_isProcessing)
            const Center(
                child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            ))
          else
            TextButton(
              onPressed: _extractAndContinue,
              child: const Text('EXTRACT',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'If a captcha appears, solve it before tapping EXTRACT.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          Expanded(
            child: WebViewWidget(controller: _controller),
          ),
        ],
      ),
    );
  }
}
