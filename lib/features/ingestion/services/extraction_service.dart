import 'package:favicon/favicon.dart' as fav;
import 'package:http/http.dart' as http;
import 'package:metadata_fetch/metadata_fetch.dart';
import 'package:readability/readability.dart' as readability;
import 'package:readability/article.dart' as readability;

class ReadabilityWrapper {
  Future<readability.Article?> parse(String url) => readability.parseAsync(url);
}

class ExtractionService {
  final ReadabilityWrapper _wrapper;
  static const String _userAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
  
  ExtractionService([ReadabilityWrapper? wrapper]) : _wrapper = wrapper ?? ReadabilityWrapper();

  Future<({String title, String content, String? thumbnailUrl})?> extractContent(String url) async {
    try {
      // 1. Extract metadata (Title and Open Graph Image) using the library's internal fetch
      // We still try to fetch HTML manually for the manual fallback if needed
      final metadata = await MetadataFetch.extract(url);
      String? title = metadata?.title;
      String? thumbnailUrl = metadata?.image;
      String? description = metadata?.description;

      // Filter out common useless titles like "www"
      if (title != null && (title.toLowerCase() == 'www' || title.toLowerCase() == 'www.')) {
        title = null;
      }

      // 2. If no title, try a manual fetch with User-Agent for robustness
      if (title == null || title.isEmpty) {
        final response = await http.get(
          Uri.parse(url),
          headers: {'User-Agent': _userAgent},
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          title = _extractTitleManually(response.body);
        }
      }

      // 3. If no OG image, try fetching a high-res favicon
      if (thumbnailUrl == null || thumbnailUrl.isEmpty) {
        final icon = await fav.FaviconFinder.getBest(url);
        thumbnailUrl = icon?.url;
      }

      // 4. Extract main content using readability
      final result = await _wrapper.parse(url);
      if (result == null && title == null) return null;

      String? finalContent = result?.content;
      if (finalContent == null || finalContent.isEmpty) {
        finalContent = description;
      }
      
      return (
        title: title ?? result?.title ?? '',
        content: finalContent ?? '',
        thumbnailUrl: thumbnailUrl,
      );
    } catch (e) {
      print('Extraction error for $url: $e');
      return null;
    }
  }

  String? _extractTitleManually(String html) {
    try {
      final regExp = RegExp(r'<title[^>]*>(.*?)</title>', caseSensitive: false, dotAll: true);
      final match = regExp.firstMatch(html);
      if (match != null && match.groupCount >= 1) {
        return match.group(1)?.trim();
      }
    } catch (e) {
      print('Manual title extraction error: $e');
    }
    return null;
  }
}
