import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

@JS('Readability')
extension type Readability._(JSObject _) implements JSObject {
  external factory Readability(web.Node doc);
  external ReadabilityResult? parse();
}

@JS()
extension type ReadabilityResult._(JSObject _) implements JSObject {
  external String? get title;
  external String? get content;
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
}

class Article {
  const Article({this.title, this.content});
  final String? title;
  final String? content;
}

Future<Article?> parseAsync(String url) async => null;

/// parseWithBrowser is removed as it's unreliable due to CORS security restrictions
/// when trying to access iframe.contentDocument from a different origin.
Future<Article?> parseWithBrowser(String url) async => null;

Future<Article?> parseHtmlDocument(String html) async {
  final parser = web.DOMParser();
  final doc = parser.parseFromString(html.toJS, 'text/html');

  // Try Defuddle first
  try {
    if (_hasGlobal('Defuddle')) {
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
    web.console.warn('Defuddle error: ${e.toString()}'.toJS);
  }

  // Fallback to Readability
  try {
    if (_hasGlobal('Readability')) {
      final readability = Readability(doc);
      final result = readability.parse();

      if (result == null) return null;

      return Article(
        title: result.title,
        content: result.content,
      );
    }
  } catch (e) {
    web.console.error('Readability error: ${e.toString()}'.toJS);
  }

  return null;
}

@JS('globalThis')
external JSObject get _globalThis;

@JS('Reflect.has')
external bool _reflectHas(JSObject target, String property);

bool _hasGlobal(String property) => _reflectHas(_globalThis, property);
