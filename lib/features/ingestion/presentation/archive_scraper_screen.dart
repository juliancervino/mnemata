import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:metadata_fetch/metadata_fetch.dart';
import 'package:mnemata/features/ingestion/presentation/ingestion_summary_screen.dart';

class ArchiveScraperScreen extends StatefulWidget {
  final String url;

  const ArchiveScraperScreen({super.key, required this.url});

  @override
  State<ArchiveScraperScreen> createState() => _ArchiveScraperScreenState();
}

class _ArchiveScraperScreenState extends State<ArchiveScraperScreen> {
  late final WebViewController _controller;
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
      final title = metadata?.title ?? 'Archive.ph Content';
      final thumbnailUrl = metadata?.image;

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

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => IngestionSummaryScreen(
              type: 'url',
              url: widget.url,
              title: title,
              content: content,
              thumbnailUrl: thumbnailUrl,
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
