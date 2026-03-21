# Roadmap: Mnemata

## Phases

- [ ] **Phase 1: Foundation & Ingestion** - Establish the cross-platform base and enable saving content via Share Intents.
- [ ] **Phase 2: The Reflective Loop** - Clean content extraction and full-text search.
- [ ] **Phase 3: Organization & Continuity** - Folders, tags, and reading history for power-user management.

## Phase Details

### Phase 1: Foundation & Ingestion
**Goal**: Users can get content into the app from any platform and see it in a list.
**Depends on**: Nothing
**Requirements**: ING-01, ING-02, ING-03, ORG-04 (list/tap)
**Success Criteria**:
  1. User can share a URL from a browser to Mnemata and see it in the list.
  2. User can share a PDF from a mobile file manager and see it in the list.
  3. User can see a chronological list of saved items on iOS, Android, and Web.
  4. User can tap an item in the list to open the original URL or document.
**Plans**: 3 plans
- [ ] 01-01-PLAN.md — Foundation & Persistence (Flutter setup, Drift DB)
- [ ] 01-02-PLAN.md — Native Share Ingestion (Android/iOS config, Share Service)
- [ ] 01-03-PLAN.md — Main UI & Navigation (Chronological List, Tap to Open)

### Phase 2: The Reflective Loop
**Goal**: Enable clean offline reading and discovery through search.
**Depends on**: Phase 1
**Requirements**: CON-01, CON-02, CON-03
**Success Criteria**:
  1. Saved URLs are automatically converted to clean, ad-free text views.
  2. Extracted content is available for reading even when the device is offline.
  3. User can find items by searching for keywords inside the extracted content.
  4. Search results update in real-time as the user types.
**Plans**: TBD

### Phase 3: Organization & Continuity
**Goal**: High-fidelity organization and frictionless recent item access.
**Depends on**: Phase 2
**Requirements**: ORG-01, ORG-02, ORG-03, ORG-04 (gestures)
**Success Criteria**:
  1. User can create, rename, and nest folders to organize items.
  2. User can apply multiple tags to an item and filter by tag.
  3. User can quickly access the 20 most recently opened items.
  4. User can swipe an item in the list to trigger 'Share' or 'Edit' actions.
**Plans**: TBD

## Progress Table

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation & Ingestion | 3/3 | Completed | 2026-03-20 |
| 2. The Reflective Loop | 3/3 | Completed | 2026-03-21 |
| 3. Organization & Continuity | 3/3 | Completed | 2026-03-21 |
