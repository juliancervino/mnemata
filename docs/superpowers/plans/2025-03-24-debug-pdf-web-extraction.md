# Debug and Fix PDF Web Extraction Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Improve PDF extraction on web by adding diagnostic logging and detailed error reporting, ensuring byte integrity during the ingestion process.

**Architecture:** Add conditional logging (using `kIsWeb`) to `PdfExtractionService` and `ShareService` to capture byte counts and extraction failures on the web platform without affecting mobile performance or behavior.

**Tech Stack:** Flutter, Syncfusion PDF, Foundation (kIsWeb)

---

### Task 1: Add diagnostics to PdfExtractionService

**Files:**
- Modify: `lib/features/ingestion/services/pdf_extraction_service.dart`

- [ ] **Step 1: Add byte length logging at the start of `extractText`**

```dart
<<<<
  Future<String?> extractText(Uint8List bytes) async {
    if (bytes.isEmpty) return null;
====
  Future<String?> extractText(Uint8List bytes) async {
    if (kIsWeb) {
      debugPrint('PdfExtractionService: extractText received bytes=${bytes.lengthInBytes}');
    }
    if (bytes.isEmpty) return null;
>>>>
```

- [ ] **Step 2: Add detailed error logging if PdfDocument fails to load on the web**

```dart
<<<<
    } catch (e) {
      debugPrint('PDF Extraction error: $e');
      return null;
====
    } catch (e, stack) {
      if (kIsWeb) {
        debugPrint('PdfExtractionService: web extraction failure: $e');
        debugPrint('PdfExtractionService: stack trace: $stack');
      } else {
        debugPrint('PDF Extraction error: $e');
      }
      return null;
>>>>
```

### Task 2: Instrument ShareService for web file extraction

**Files:**
- Modify: `lib/features/ingestion/services/share_service.dart`

- [ ] **Step 1: Log file info before calling extraction service in `handleManualFileImport`**

```dart
<<<<
    try {
      String? extractedText;
      if (normalizedName.toLowerCase().endsWith('.pdf')) {
        extractedText = await _pdfExtractionService.extractText(bytes);
      }

      _hideLoadingOverlay();
      final resultFromSummary = await _pushSummaryWhenNavigatorReady(
        (context) => IngestionSummaryScreen(
          type: 'file',
          filePath: normalizedName,
          title: normalizedName,
          content: extractedText,
        ),
      );
      _handleSummaryOutcome(resultFromSummary, source: normalizedName);
      debugPrint(
        'ShareService: web file ingest mimeType=$mimeType bytes=${bytes.lengthInBytes}',
      );
====
    try {
      String? extractedText;
      if (normalizedName.toLowerCase().endsWith('.pdf')) {
        if (kIsWeb) {
          debugPrint('ShareService: extracting PDF web file=$normalizedName bytes=${bytes.lengthInBytes}');
        }
        extractedText = await _pdfExtractionService.extractText(bytes);
      }

      _hideLoadingOverlay();
      final resultFromSummary = await _pushSummaryWhenNavigatorReady(
        (context) => IngestionSummaryScreen(
          type: 'file',
          filePath: normalizedName,
          title: normalizedName,
          content: extractedText,
        ),
      );
      _handleSummaryOutcome(resultFromSummary, source: normalizedName);
      if (kIsWeb) {
        debugPrint(
          'ShareService: web file ingest complete mimeType=$mimeType bytes=${bytes.lengthInBytes} success=${extractedText != null}',
        );
      }
>>>>
```

### Task 3: Verification

- [ ] **Step 1: Run existing tests to ensure no regressions**

Run: `flutter test test/features/ingestion/services/pdf_extraction_service_test.dart`
Expected: PASS

Run: `flutter test test/features/ingestion/services/share_service_test.dart`
Expected: PASS
