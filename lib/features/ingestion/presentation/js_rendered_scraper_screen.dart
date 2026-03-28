import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mnemata/features/ingestion/presentation/ingestion_summary_screen.dart';
import 'package:mnemata/features/ingestion/services/extraction_service.dart';
import 'package:mnemata/features/ingestion/services/js_rendered_content_processor.dart';
import 'package:webview_flutter/webview_flutter.dart';

class JsRenderedScraperScreen extends StatefulWidget {
  final String url;

  const JsRenderedScraperScreen({super.key, required this.url});

  @override
  State<JsRenderedScraperScreen> createState() => _JsRenderedScraperScreenState();
}

class _JsRenderedScraperScreenState extends State<JsRenderedScraperScreen> {
  late final WebViewController _controller;
  final ReadabilityWrapper _readabilityWrapper = ReadabilityWrapper();
  late final JsRenderedContentProcessor _processor;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _processor = JsRenderedContentProcessor(_readabilityWrapper);
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36')
      ..loadRequest(Uri.parse(widget.url));
  }

  Future<void> _extractAndContinue() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final Object result = await _controller.runJavaScriptReturningResult(
        'document.documentElement.outerHTML;',
      );

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

      final extraction = await _processor.extractFromCapturedHtml(
        sourceUrl: widget.url,
        rawHtml: rawHtml,
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => IngestionSummaryScreen(
            type: 'url',
            url: widget.url,
            title: extraction.title,
            content: extraction.content,
            thumbnailUrl: extraction.thumbnailUrl,
          ),
        ),
      );
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
        title: const Text('Rendered Content Extraction'),
        actions: [
          if (_isProcessing)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _extractAndContinue,
              child: const Text(
                'EXTRACT',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Wait until the article is fully rendered, then tap EXTRACT.',
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
