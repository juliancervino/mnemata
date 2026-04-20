import 'dart:convert';
import 'dart:io';

import 'package:readability/article.dart' as readability_article;
import 'package:readability/readability.dart' as readability;

typedef Article = readability_article.Article;

Future<Article?> parseAsync(String url) => readability.parseAsync(url);

Future<Article?> parseHtmlDocument(String html) async {
  final dataUri = 'data:text/html;base64,${base64.encode(utf8.encode(html))}';

  try {
    return await parseAsync(dataUri);
  } catch (_) {
    File? tempFile;
    try {
      final timestamp = DateTime.now().microsecondsSinceEpoch;
      tempFile =
          File('${Directory.systemTemp.path}/mnemata_readability_$timestamp.html');
      await tempFile.writeAsString(html, flush: true);
      return await parseAsync('file://${tempFile.path}');
    } finally {
      if (tempFile != null && await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }
}