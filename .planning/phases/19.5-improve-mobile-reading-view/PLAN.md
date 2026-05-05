# 19.5: Improve mobile reading view Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Optimize the reading experience on mobile devices by switching to `HtmlWidget` for structural content support (headings, bold, etc.), improving typography with 1.5em paragraph spacing, and implementing responsive horizontal margins.

**Architecture:** Unify the rendering path in `ReaderScreen` to use `HtmlWidget` across all platforms. Content will be converted from Markdown to HTML if necessary, and highlights will be injected as `<mark>` tags. Styling will be managed via `HtmlWidget`'s `customStylesBuilder`.

**Tech Stack:** Flutter, `flutter_widget_from_html`, `mnemata` theme system.

---

### Task 1: Research & Prepare Responsive Margins

**Files:**
- Modify: `lib/features/reader/presentation/reader_screen.dart`

- [ ] **Step 1: Identify current margin implementation**
Currently `_buildScrollableBody` uses:
```dart
padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
```
inside a `Container` with `_columnWidth`.

- [ ] **Step 2: Define responsive margin logic**
On mobile, we want ~20px margins. On desktop/web, it's controlled by `_columnWidth`.
I will update `_buildScrollableBody` to use a more flexible padding/margin approach.

### Task 2: Unify Rendering Logic in `ReaderScreen`

**Files:**
- Modify: `lib/features/reader/presentation/reader_screen.dart`

- [ ] **Step 1: Update `_buildMainContent` to use `HtmlWidget` for mobile**
Remove the `kIsWeb && isMarkdown` branch and use `HtmlWidget` as the primary renderer for both platforms.

- [ ] **Step 2: Use raw content for rendering**
Ensure `widget.item.content` is used instead of `_plainContent` for the `HtmlWidget`.

- [ ] **Step 3: Implement `_prepareHtmlContent` helper**
Create a helper that:
1. Detects if content is Markdown or HTML.
2. Converts Markdown to HTML if needed.
3. Injects highlights using `_applyHighlightsToHtml`.
4. Ensures paragraph and line break preservation.

- [ ] **Step 4: Update `_applyHighlightsToHtml` to handle pre-existing HTML**
If the content is already HTML (not escaped by `MarkdownConverter`), we need to be careful with escaping.
However, `MarkdownConverter` escapes EVERYTHING first.
If the content is raw HTML from `ExtractionService`, we might need a different converter or just trust `HtmlWidget` to handle it.
Actually, `D-02` says: "The implementation must explicitly preserve line breaks (<br>), carriage returns, and paragraph boundaries (<p>)".

### Task 3: Apply Mobile-Specific Typography & Styling

**Files:**
- Modify: `lib/features/reader/presentation/reader_screen.dart`

- [ ] **Step 1: Implement `customStylesBuilder` for paragraph spacing**
```dart
customStylesBuilder: (element) {
  if (element.localName == 'p') {
    return {
      'margin-bottom': '1.5em',
      'margin-top': '0',
      'display': 'block',
    };
  }
  // ... other tags
}
```

- [ ] **Step 2: Add support for more tags**
Ensure `<h1>`-`<h6>`, `<strong>`, `<em>` etc. are styled correctly if they aren't by default.

### Task 4: Responsive Margins & Padding

**Files:**
- Modify: `lib/features/reader/presentation/reader_screen.dart`

- [ ] **Step 1: Adjust `_buildScrollableBody` padding**
Make horizontal padding responsive. ~20px on mobile, larger on tablet/desktop if not using the centered column.

### Task 5: Verification & Testing

- [ ] **Step 1: Verify on Mobile (simulation via layout constraints if possible, or build)**
- [ ] **Step 2: Check Markdown rendering**
- [ ] **Step 3: Check HTML (web extracted) rendering**
- [ ] **Step 4: Verify Highlight functionality**
- [ ] **Step 5: Verify Paragraph spacing**

---
