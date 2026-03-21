# Requirements: Mnemata

## v1: MVP (The Reflective Loop)

### Ingestion & Storage (ING)
- **ING-01**: Save URLs to the application database.
- **ING-02**: Copy received documents (PDFs, images) to local secure storage.
- **ING-03**: Native integration (iOS/Android) as a Share Intent target to receive URLs and files.
- **ING-04**: Extract and index text content from PDF files for full-text search.
- **ING-05**: Display a summary/editor screen after sharing an item to allow title editing and tag assignment before saving.

### Content & Retrieval (CON)
- **CON-01**: Extract title and main content from URLs, removing ads and clutter.
- **CON-02**: Provide offline reading capability for extracted content.
- **CON-03**: Full-text search across item titles, URLs, document names, and extracted content.
- **CON-04**: Use representative images (Open Graph/Favicons) as thumbnails for URL items in the list.
- **CON-05**: Open saved files (PDFs, etc.) using platform-native viewers.

### Organization & UX (ORG)
- **ORG-01**: Hierarchical tree structure for item organization (folders and subfolders).
- **ORG-02**: Many-to-many tagging system with filtering/grouping capabilities.
- **ORG-03**: Maintain a reading history of the last 20 accessed items.
- **ORG-04**: Main view list (newest to oldest) with tap-to-open and swipe gestures (share/edit).
- **ORG-05**: Visual tag indicators (colored dots) on list items in the main view.
- **ORG-06**: Quick-filter bar for recently used tags on the main screen.
- **ORG-07**: Selection of colors for labels (tags/folders) during creation and modification.
- **ORG-08**: Ability to rename existing labels.
- **ORG-09**: Manual reordering of items in the main list via drag-and-drop.

### User Experience (UX)
- **UX-01**: Direct activation of swipe actions (Share/Edit) upon reaching a threshold, without requiring a second tap.
- **UX-02**: Item editing view to modify title, URL, and assigned labels.

### Content & Retrieval (CON)
...
| Requirement | Phase | Status |
|-------------|-------|--------|
...
| ORG-06 | Phase 4 | Completed |
| ORG-07 | Phase 7 | Pending |
| ORG-08 | Phase 7 | Pending |
| ORG-09 | Phase 7 | Pending |
| UX-01 | Phase 7 | Pending |
| UX-02 | Phase 7 | Pending |
