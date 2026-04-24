import 'dart:convert';
import 'package:html/dom.dart';
import 'package:html/parser.dart' show parse;

class ExtractedMetadata {
  final String? title;
  final String? author;
  final String? datePublished;
  final String? siteName;
  final String? description;
  final String? image;

  ExtractedMetadata({
    this.title,
    this.author,
    this.datePublished,
    this.siteName,
    this.description,
    this.image,
  });

  @override
  String toString() =>
      'ExtractedMetadata(title: $title, author: $author, datePublished: $datePublished, siteName: $siteName)';
}

class MetadataExtractionService {
  ExtractedMetadata extract(String html) {
    final document = parse(html);

    final jsonLd = _extractJsonLd(document);
    final openGraph = _extractOpenGraph(document);
    final twitter = _extractTwitter(document);
    final basic = _extractBasic(document);

    return ExtractedMetadata(
      title: _pick(jsonLd['title'], openGraph['title'], twitter['title'], basic['title']),
      author: _pick(jsonLd['author'], openGraph['author'], twitter['author'], basic['author']),
      datePublished: _pick(jsonLd['datePublished'], openGraph['datePublished'], twitter['datePublished'], basic['datePublished']),
      siteName: _pick(jsonLd['siteName'], openGraph['siteName'], twitter['siteName'], basic['siteName']),
      description: _pick(jsonLd['description'], openGraph['description'], twitter['description'], basic['description']),
      image: _pick(jsonLd['image'], openGraph['image'], twitter['image'], basic['image']),
    );
  }

  String? _pick(String? p1, String? p2, String? p3, String? p4) {
    if (p1 != null && p1.isNotEmpty) return p1;
    if (p2 != null && p2.isNotEmpty) return p2;
    if (p3 != null && p3.isNotEmpty) return p3;
    if (p4 != null && p4.isNotEmpty) return p4;
    return null;
  }

  Map<String, String?> _extractJsonLd(Document document) {
    final results = <String, String?>{};
    final scripts = document.querySelectorAll('script[type="application/ld+json"]');

    for (final script in scripts) {
      try {
        final content = script.text;
        final json = jsonDecode(content);
        if (json is Map) {
          _parseJsonLdMap(json, results);
        } else if (json is List) {
          for (final item in json) {
            if (item is Map) {
              _parseJsonLdMap(item, results);
            }
          }
        }
      } catch (_) {}
    }
    return results;
  }

  void _parseJsonLdMap(Map json, Map<String, String?> results) {
    results['title'] ??= json['headline']?.toString() ?? json['name']?.toString();

    final author = json['author'];
    if (author is Map) {
      results['author'] ??= author['name']?.toString();
    } else if (author is String) {
      results['author'] ??= author;
    } else if (author is List && author.isNotEmpty) {
      final first = author.first;
      if (first is Map) {
        results['author'] ??= first['name']?.toString();
      } else if (first is String) {
        results['author'] ??= first;
      }
    }

    results['datePublished'] ??=
        json['datePublished']?.toString() ?? json['dateCreated']?.toString();
    results['description'] ??= json['description']?.toString();

    final publisher = json['publisher'];
    if (publisher is Map) {
      results['siteName'] ??= publisher['name']?.toString();
    }

    final image = json['image'];
    if (image is Map) {
      results['image'] ??= image['url']?.toString();
    } else if (image is String) {
      results['image'] ??= image;
    } else if (image is List && image.isNotEmpty) {
      final first = image.first;
      if (first is Map) {
        results['image'] ??= first['url']?.toString();
      } else if (first is String) {
        results['image'] ??= first;
      }
    }
  }

  Map<String, String?> _extractOpenGraph(Document document) {
    final results = <String, String?>{};
    final metas = document.querySelectorAll('meta[property^="og:"]');
    for (final meta in metas) {
      final property = meta.attributes['property'];
      final content = meta.attributes['content'];
      if (property == null || content == null) continue;

      switch (property) {
        case 'og:title':
          results['title'] = content;
        case 'og:article:author':
          results['author'] ??= content;
        case 'og:site_name':
          results['siteName'] = content;
        case 'og:description':
          results['description'] = content;
        case 'og:image':
          results['image'] = content;
      }
    }
    return results;
  }

  Map<String, String?> _extractTwitter(Document document) {
    final results = <String, String?>{};
    final metas = document.querySelectorAll('meta[name^="twitter:"]');
    for (final meta in metas) {
      final name = meta.attributes['name'];
      final content = meta.attributes['content'];
      if (name == null || content == null) continue;

      switch (name) {
        case 'twitter:title':
          results['title'] = content;
        case 'twitter:creator':
          results['author'] ??= content;
        case 'twitter:site':
          results['siteName'] ??= content;
        case 'twitter:description':
          results['description'] = content;
        case 'twitter:image':
          results['image'] = content;
      }
    }
    return results;
  }

  Map<String, String?> _extractBasic(Document document) {
    return {
      'title': document.querySelector('title')?.text ?? document.querySelector('h1')?.text,
      'author': document.querySelector('meta[name="author"]')?.attributes['content'],
      'description': document.querySelector('meta[name="description"]')?.attributes['content'],
    };
  }
}
