class Article {
  const Article({this.title, this.content});

  final String? title;
  final String? content;
}

Future<Article?> parseAsync(String url) async => null;

Future<Article?> parseHtmlDocument(String html) async => null;