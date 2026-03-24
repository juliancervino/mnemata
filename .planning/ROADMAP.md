# Roadmap: Mnemata

## Phases

- [x] **Phase 1: Foundation & Ingestion** - Establish the cross-platform base and enable saving content via Share Intents.
- [x] **Phase 2: The Reflective Loop** - Clean content extraction and full-text search.
- [x] **Phase 3: Organization & Continuity** - Folders, tags, and reading history for power-user management.
- [x] **Phase 4: Visual Polish & Quick Discovery** - Representative images and quick tag filtering.
- [x] **Phase 5: File Intelligence** - PDF indexing and native file opening.
- [x] **Phase 6: Guided Ingestion** - Shared content editor and summary.
- [x] **Phase 7: Refined Control & Personalization** - Manual reordering, label customization, and improved gestures.

## Phase Details

### Phase 1: Foundation & Ingestion
... (same as before)
**Plans**: 3 plans
- [x] 01-01-PLAN — Foundation & Persistence
- [x] 01-02-PLAN — Native Share Ingestion
- [x] 01-03-PLAN — Main UI & Navigation

### Phase 2: The Reflective Loop
... (same as before)
**Plans**: 3 plans
- [x] 02-01-PLAN — Persistence & Search Foundation
- [x] 02-02-PLAN — Content Extraction Service
- [x] 02-03-PLAN — Reader & Search UI

### Phase 3: Organization & Continuity
... (same as before)
**Plans**: 3 plans
- [x] 03-01-PLAN — Label & Folder Foundation
- [x] 03-02-PLAN — Folders & Organization UI
- [x] 03-03-PLAN — Gestures & History View

### Phase 4: Visual Polish & Quick Discovery
**Goal**: Enhance item visualization and provide faster access to common tags.
**Depends on**: Phase 3
**Requirements**: ORG-05, ORG-06, CON-04
**Success Criteria**:
  1. List items show representative images/favicons instead of generic icons.
  2. Assigned tags are visible as colored dots on list items.
  3. A horizontal bar of recently used tags allows one-tap filtering.
**Plans**: 2 plans
- [x] 04-01-PLAN — Tag Visualization & Previews
- [x] 04-02-PLAN — Quick Discovery Bar

### Phase 5: File Intelligence
**Goal**: Deep indexing of document content and reliable file opening.
**Depends on**: Phase 1
**Requirements**: CON-05, ING-04
**Success Criteria**:
  1. PDF text content is extracted and searchable via the main search bar.
  2. PDFs and other saved files open correctly in native platform viewers.
**Plans**: 1 plan
- [x] 05-01-PLAN — PDF Content Indexing

### Phase 6: Guided Ingestion
**Goal**: Provide control over content before it's saved.
**Depends on**: Phase 3
**Requirements**: ING-06
**Success Criteria**:
  1. Sharing a link/file triggers a summary screen with editable title.
  - [x] **Phase 7: Refined Control & Personalization** - Manual reordering, label customization, and improved gestures.
  - [x] **Phase 8: Refinement & Advanced Features** - Organization simplification, ingestion robustness, and multi-tag filtering.

  ## Phase Details
  ...
  ### Phase 8: Refinement & Advanced Features
  **Goal**: Address technical debt (cold starts), simplify organization (Tags only), and enhance user productivity (multi-tag filters).
  **Depends on**: Phase 7
  **Requirements**: Various UI/UX and Ingestion refinements.
  **Success Criteria**:
    1. No "Folder" distinction exists; all labels are tags.
    2. Cold start sharing works reliably.
    3. URLs can be extracted from shared text.
    4. Multiple tags can be used to filter the list (AND logic).
    5. Content view respects system navigation bars and shows tags.
  **Plans**: 3 plans
  - [x] 08-01-PLAN — Structural Simplification & Ingestion Robustness
  - [x] 08-02-PLAN — Advanced Organization & Interaction
  - [x] 08-03-PLAN — Visual Polish & Documentation

  ## Progress Table

  | Phase | Plans Complete | Status | Completed |
  |-------|----------------|--------|-----------|
  | 1. Foundation & Ingestion | 3/3 | Completed | 2026-03-20 |
  | 2. The Reflective Loop | 3/3 | Completed | 2026-03-21 |
  | 3. Organization & Continuity | 3/3 | Completed | 2026-03-21 |
  | 4. Visual Polish | 2/2 | Completed | 2026-03-21 |
  | 5. File Intelligence | 1/1 | Completed | 2026-03-21 |
  | 6. Guided Ingestion | 1/1 | Completed | 2026-03-21 |
  | 7. Refined Control | 3/3 | Completed | 2026-03-21 |
  | 8. Refinement & Advanced | 3/3 | Completed | 2026-03-24 |
