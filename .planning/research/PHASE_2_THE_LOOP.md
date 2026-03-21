# Phase 2: The Reflective Loop - Research

**Researched:** 2024-05-22
**Domain:** Content Extraction, Full-Text Search (FTS), Offline Reading UI
**Confidence:** HIGH

## Summary
Phase 2 focuses on transforming raw URLs into a clean reading experience and making all content searchable offline. The research identifies `dart_readability` as the most stable Dart-native solution for content extraction, `Drift` (with FTS5) for high-performance searching, and `flutter_widget_from_html` for rendering.

**Primary recommendation:** Use `dart_readability` for client-side extraction and SQLite FTS5 virtual tables (configured via `.drift` files) for search.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `dart_readability` | ^0.6.0 | Content Extraction | Active Dart port of Mozilla's readability engine. Works cross-platform without native wrappers. |
| `drift` | ^2.16.0 | Persistence & Search | Robust SQLite ORM; supports FTS5 via virtual tables and `.drift` files. |
| `flutter_widget_from_html` | ^0.15.0 | Reader UI | Superior performance to `flutter_html`, modular, and handles complex HTML/tables well. |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `http` | ^1.2.0 | Content Fetching | To retrieve the raw HTML from URLs before extraction. |
| `path_provider` | ^2.1.0 | Local Storage | To manage paths for downloaded assets/PDFs. |

## Architecture Patterns

### Recommended Project Structure
```
lib/
├── features/
│   ├── reader/          # Reader View UI & Logic
│   └── search/          # Search UI & Drift query logic
└── core/
    ├── database/
    │   ├── tables.drift   # Virtual tables and SQL triggers
    │   └── search_service.dart # Abstraction for FTS queries
```

### Pattern 1: FTS5 Virtual Table with External Content
Instead of storing all text twice, use a virtual table that "points" to the main `mnemata_items` table.
**Example (`tables.drift`):**
```sql
CREATE VIRTUAL TABLE mnemata_search USING fts5(
    title,
    content,
    content='mnemata_items',
    content_rowid='id',
    tokenize='porter' -- Enables stemming (searching 'reading' finds 'read')
);

-- Triggers to keep index in sync
CREATE TRIGGER mnemata_items_ai AFTER INSERT ON mnemata_items BEGIN
  INSERT INTO mnemata_search(rowid, title, content) VALUES (new.id, new.title, new.content);
END;
```

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Clean Text Extraction | Regex or manual DOM traversal | `dart_readability` | Heuristics for "main content" are extremely complex (handling sidebars, nav, ads). |
| HTML Rendering | Custom Widget Tree | `flutter_widget_from_html` | Handling inline styles, tables, and images correctly is a massive undertaking. |
| Search Ranking | Linear scanning (`LIKE %term%`) | SQLite FTS5 | FTS5 provides `rank` for relevancy and is orders of magnitude faster on large datasets. |

## Common Pitfalls

### Pitfall 1: Bloated Database
**What goes wrong:** Storing full HTML in the main table can slow down standard list queries.
**How to avoid:** Use a separate `ItemContent` table or ensure the "list view" query only selects the necessary metadata columns, not the full `content` blob.

### Pitfall 2: FTS5 Availability on Web
**What goes wrong:** Some Web/WASM SQLite builds might not include FTS5 by default.
**How to avoid:** Use `sqlite3_flutter_libs` and verify the `drift_flutter` configuration for web targets.

## Code Examples

### Content Extraction Flow
```dart
// Fetch and Parse
final response = await http.get(Uri.parse(url));
final doc = Readability(response.body, url: url).parse();
final cleanHtml = doc.content;
final title = doc.title;
```

### Search Query in Drift
```dart
Stream<List<SearchResult>> searchItems(String query) {
  return (select(mnemataSearch)..where((t) => t.match(query)))
      .map((row) => SearchResult(id: row.rowid, title: row.title))
      .watch();
}
```

## Validation Architecture
- **Unit Tests:** Test `dart_readability` against a set of saved HTML files.
- **Integration Tests:** Verify that inserting a record into `mnemata_items` correctly populates `mnemata_search`.
