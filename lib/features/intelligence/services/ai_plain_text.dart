final RegExp _domainLabelPattern = RegExp(
  r'^(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}$',
  caseSensitive: false,
);

bool looksLikeDomainLabel(String value) {
  final normalized = value.trim().toLowerCase().replaceFirst('www.', '');
  return _domainLabelPattern.hasMatch(normalized);
}

String toAiPlainText(String raw) {
  if (raw.trim().isEmpty) {
    return '';
  }

  var text = raw
      .replaceAll(
        RegExp(r'<script[\s\S]*?<\/script>', caseSensitive: false),
        ' ',
      )
      .replaceAll(RegExp(r'<style[\s\S]*?<\/style>', caseSensitive: false), ' ')
      .replaceAll(RegExp(r'<svg[\s\S]*?<\/svg>', caseSensitive: false), ' ')
      .replaceAll(
        RegExp(r'<noscript[\s\S]*?<\/noscript>', caseSensitive: false),
        ' ',
      )
      .replaceAll(RegExp(r'<[^>]+>'), ' ');

  const entities = <String, String>{
    '&nbsp;': ' ',
    '&amp;': '&',
    '&lt;': '<',
    '&gt;': '>',
    '&quot;': '"',
    '&#39;': "'",
  };
  entities.forEach((key, value) {
    text = text.replaceAll(key, value);
  });

  // Remove unresolved entities to avoid noisy prompt payloads.
  text = text.replaceAll(RegExp(r'&[a-zA-Z0-9#]+;'), ' ');

  return text.replaceAll(RegExp(r'\s+'), ' ').trim();
}
