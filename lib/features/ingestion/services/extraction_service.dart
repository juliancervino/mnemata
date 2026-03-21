import 'package:readability/readability.dart' as readability;
import 'package:readability/article.dart' as readability;

class ReadabilityWrapper {
  Future<readability.Article?> parse(String url) => readability.parseAsync(url);
}

class ExtractionService {
  final ReadabilityWrapper _wrapper;
  
  ExtractionService([ReadabilityWrapper? wrapper]) : _wrapper = wrapper ?? ReadabilityWrapper();

  Future<({String title, String content})?> extractContent(String url) async {
    try {
      final result = await _wrapper.parse(url);
      if (result == null) return null;
      
      return (
        title: result.title ?? '',
        content: result.content ?? '',
      );
    } catch (e) {
      // In a real app, we'd log this to a crash reporting service
      print('Extraction error for $url: $e');
      return null;
    }
  }
}
