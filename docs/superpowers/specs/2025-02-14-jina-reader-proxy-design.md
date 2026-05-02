# Design: Refine Tiered Proxy Pipeline with Jina Reader

**Goal:** Add Jina Reader (`r.jina.ai`) as a third fallback for web content extraction to improve success rates when other proxies are blocked or fail.

**Context:** The current web extraction pipeline uses a tiered approach: Direct Fetch -> CORS Proxy -> AllOrigins. Adding Jina Reader provides a specialized extraction service as a last resort.

## Architecture

The `ExtractionService` for Web will be updated to include Jina Reader in its fallback sequence.

### Data Flow (Web Flow only)
1. `_client.get(url)` (Direct)
2. `_fetchViaCorsProxy(url)`
3. `_fetchViaAllOrigins(url)`
4. `_fetchViaJinaReader(url)` (New)

### Components

#### 1. `_fetchViaJinaReader(String url)`
- **Endpoint:** `https://r.jina.ai/${Uri.encodeComponent(url)}`
- **Headers:** `{'Accept': 'text/html'}` to ensure HTML output compatible with `processRawHtml`.
- **Timeout:** 15 seconds.
- **Diagnostics:** Logs attempts and failures via `_webLog`.
- **Validation:** Uses `_checkFailureHeuristics` to handle status codes and block detection.

#### 2. `extractContent` Update
The tiered logic in `extractContent` will be extended:
```dart
if (html == null) {
  _webLog('AllOrigins proxy failed, attempting Jina Reader...');
  html = await _fetchViaJinaReader(url);
}
```

## Error Handling
- `ExtractionBlockedException` will be rethrown if detected by `_checkFailureHeuristics`.
- General exceptions during the Jina fetch will be caught, logged, and return `null` to allow the flow to terminate gracefully if all attempts fail.

## Testing
- Mock `http.Client` to simulate failures for all previous tiers.
- Verify Jina Reader is called with the correct `Accept` header.
- Ensure `processRawHtml` is called with the output from Jina.

## Safety
- **NO CHANGES** to the `else` block (Mobile/IO flow).
