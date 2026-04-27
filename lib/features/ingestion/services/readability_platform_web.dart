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

Future<Article?> parseWithBrowser(String url) async {
  final completer = Completer<Article?>();
  final iframe = web.HTMLIFrameElement();
  
  iframe.style.display = 'none';
  iframe.src = url;

  StreamSubscription? subscription;
  
  void cleanup() {
    subscription?.cancel();
    iframe.remove();
  }

  subscription = iframe.onLoad.listen((_) async {
    try {
      final doc = iframe.contentDocument;
      if (doc == null) {
        completer.complete(null);
        return;
      }

      // Try Defuddle first on the rendered document
      if (_hasGlobal('Defuddle')) {
        final defuddle = Defuddle(doc);
        final result = defuddle.parse();
        if (result != null && result.content != null) {
          completer.complete(Article(
            title: result.title,
            content: result.content,
          ));
          return;
        }
      }

      // Fallback to Readability
      if (_hasGlobal('Readability')) {
        final readability = Readability(doc);
        final result = readability.parse();
        if (result != null) {
          completer.complete(Article(
            title: result.title,
            content: result.content,
          ));
          return;
        }
      }
      
      completer.complete(null);
    } catch (e) {
      web.console.error('Browser extraction error: ${e.toString()}'.toJS);
      completer.complete(null);
    } finally {
      cleanup();
    }
  });

  web.document.body?.append(iframe);

  // Timeout after 20 seconds
  return completer.future.timeout(
    const Duration(seconds: 20),
    onTimeout: () {
      cleanup();
      return null;
    },
  );
}

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

@JS('window.hasOwnProperty')
external bool _windowHasOwnProperty(String property);

bool _hasGlobal(String property) => _windowHasOwnProperty(property);
