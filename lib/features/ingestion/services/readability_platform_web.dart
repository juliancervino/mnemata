import 'dart:js_interop';
import 'package:web/web.dart' as web;

@JS()
extension type ReadabilityOptions._(JSObject _) implements JSObject {
  external factory ReadabilityOptions({
    bool? debug,
    int? maxElemsToParse,
    int? nbTopCandidates,
    int? charThreshold,
    JSArray<JSString>? classesToPreserve,
    bool? keepClasses,
  });
}

@JS()
extension type ReadabilityResult._(JSObject _) implements JSObject {
  external String? get title;
  external String? get content;
  external String? get textContent;
  external String? get length;
  external String? get excerpt;
  external String? get byline;
  external String? get dir;
  external String? get siteName;
  external String? get lang;
  external String? get publishedTime;
}

@JS('Readability')
extension type Readability._(JSObject _) implements JSObject {
  external factory Readability(web.Node doc, [ReadabilityOptions options]);
  external ReadabilityResult? parse();
}

@JS('Defuddle')
extension type Defuddle._(JSObject _) implements JSObject {
  external factory Defuddle(web.Node doc);
  external DefuddleResult? parse();
}

@JS()
extension type DefuddleResult._(JSObject _) implements JSObject {
  external String? get title;
  external String? get content;
  external String? get author;
  external String? get published;
  external String? get site;
  external String? get description;
  external String? get image;
  external String? get language;
}

class Article {
  const Article({this.title, this.content});

  final String? title;
  final String? content;
}

Future<Article?> parseAsync(String url) async {
  // On web, direct URL parsing is usually not possible due to CORS.
  // We expect the caller to fetch the HTML and use parseHtmlDocument.
  return null;
}

Future<Article?> parseHtmlDocument(String html) async {
  final parser = web.DOMParser();
  final doc = parser.parseFromString(html, 'text/html');

  // Try Defuddle first if available
  try {
    if (globalContext.has('Defuddle')) {
      final defuddle = Defuddle(doc);
      final result = defuddle.parse();
      if (result != null && result.content != null) {
        return Article(
          title: result.title,
          content: result.content,
        );
      }
    }
  } catch (e) {
    print('Defuddle error: $e');
  }

  // Fallback to Readability
  try {
    if (globalContext.has('Readability')) {
      final readability = Readability(doc);
      final result = readability.parse();

      if (result == null) return null;

      return Article(
        title: result.title,
        content: result.content,
      );
    }
  } catch (e) {
    print('Readability error: $e');
  }

  return null;
}

@JS('window')
external JSObject get globalContext;

extension JSObjectExtension on JSObject {
  @JS('hasOwnProperty')
  external bool _hasOwnProperty(String property);

  bool has(String property) => _hasOwnProperty(property);
}
