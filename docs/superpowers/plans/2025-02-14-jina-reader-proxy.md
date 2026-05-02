# Jina Reader Proxy Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement Jina Reader (`r.jina.ai`) as a third-tier fallback in the `ExtractionService` web flow.

**Architecture:** Add a private `_fetchViaJinaReader` method and update the `extractContent` tiered logic for web. Use `Accept: text/html` to get HTML output.

**Tech Stack:** Dart, Flutter, `http` package.

---

### Task 1: Implement `_fetchViaJinaReader` in `ExtractionService`

**Files:**
- Modify: `lib/features/ingestion/services/extraction_service.dart`

- [ ] **Step 1: Add `_fetchViaJinaReader` method**

Add the method before `_processHtml`.

```dart
  Future<String?> _fetchViaJinaReader(String url) async {
    _webLog('Attempting Jina Reader fetch for: $url');
    try {
      final proxyUrl = 'https://r.jina.ai/$url';
      final response = await _client
          .get(
            Uri.parse(proxyUrl),
            headers: {'Accept': 'text/html'},
          )
          .timeout(const Duration(seconds: 20));

      _webLog('Jina Reader status: ${response.statusCode}');
      _checkFailureHeuristics(response.statusCode, response.body);

      if (response.statusCode == 200) {
        return response.body;
      }
    } on ExtractionBlockedException {
      rethrow;
    } catch (e) {
      _webLog('Jina Reader failed: $e');
      debugPrint('r.jina.ai failed for $url: $e');
    }
    return null;
  }
```

- [ ] **Step 2: Update `extractContent` for Web flow**

Include Jina Reader as the third tier.

```dart
        // 2. Fallbacks (Web: Tiered proxies)
        _webLog('Attempting fallback via CORS proxy...');
        html = await _fetchViaCorsProxy(url);
        if (html == null) {
          _webLog('CORS proxy failed, attempting AllOrigins proxy...');
          html = await _fetchViaAllOrigins(url);
        }
        if (html == null) {
          _webLog('AllOrigins proxy failed, attempting Jina Reader...');
          html = await _fetchViaJinaReader(url);
        }
```

- [ ] **Step 3: Verify no changes to Mobile flow**

Check that the `else` block remains untouched.

- [ ] **Step 4: Commit**

```bash
git add lib/features/ingestion/services/extraction_service.dart
git commit -m "feat: add Jina Reader as third fallback tier for web extraction"
```

### Task 2: Add Test Case for Jina Reader Fallback

**Files:**
- Modify: `test/features/ingestion/services/extraction_service_test.dart`

- [ ] **Step 1: Add Jina Reader fallback test**

Add this test case to the `ExtractionService (Web Flow)` group.

```dart
    test('fallback to Jina Reader when first two proxies fail', () async {
      when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((invocation) async {
            final uri = invocation.positionalArguments[0] as Uri;
            final headers = invocation.namedArguments[#headers] as Map<String, String>?;
            
            if (uri.toString().contains('corsproxy.io')) {
              return http.Response('Not Found', 404);
            } else if (uri.toString().contains('allorigins.win')) {
              return http.Response('Not Found', 404);
            } else if (uri.toString().contains('r.jina.ai')) {
              if (headers?['Accept'] == 'text/html') {
                 return http.Response(testHtml, 200);
              }
              return http.Response('Wrong Header', 400);
            } else {
              return http.Response('Not Found', 404);
            }
          });
      
      when(() => mockMetadataService.extract(any())).thenReturn(
        ExtractedMetadata(title: 'Jina Title', description: 'Jina Desc'),
      );
      
      final mockArticle = MockArticle();
      when(() => mockArticle.title).thenReturn('Reader Title');
      when(() => mockArticle.content).thenReturn('Jina Content' * 30);

      when(() => mockReadabilityWrapper.parseHtml(any())).thenAnswer(
        (_) async => mockArticle,
      );

      final result = await service.extractContent(testUrl);

      expect(result?.title, 'Jina Title');
      expect(result?.content, contains('Jina Content'));
      verify(() => mockHttpClient.get(any(that: predicate<Uri>((uri) => uri.toString().contains('r.jina.ai'))), headers: any(named: 'headers'))).called(1);
    });
```

- [ ] **Step 2: Run tests**

Run: `flutter test test/features/ingestion/services/extraction_service_test.dart`
Expected: ALL PASS

- [ ] **Step 3: Commit**

```bash
git add test/features/ingestion/services/extraction_service_test.dart
git commit -m "test: add test case for Jina Reader fallback"
```

### Task 3: Final Verification

- [ ] **Step 1: Run all extraction tests**

Run: `flutter test test/features/ingestion/services/`
Expected: ALL PASS

- [ ] **Step 2: Verify `_webLog` usage**

Check the code to ensure `_webLog` is used correctly for diagnostics.
