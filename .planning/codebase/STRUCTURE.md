# Codebase Structure

**Analysis Date:** 2026-04-04

## Directory Layout

```text
mnemata/
├── lib/                          # Flutter app source
│   ├── main.dart                 # Bootstrap, DI, root app
│   ├── core/                     # Shared persistence and utilities
│   │   ├── database/             # Drift schema, migrations, queries
│   │   └── utils/                # Cross-feature helpers
│   └── features/                 # Feature-first modules
│       ├── chronological_list/   # Primary list UX and item editing
│       ├── ingestion/            # Share intent + extraction pipeline
│       ├── organization/         # Label management and assignment
│       ├── reader/               # Offline article reader UI
│       └── settings/             # App settings and about UI
├── test/                         # Unit/widget tests mirroring core/features
├── assets/                       # App image assets
├── android/ ios/ linux/ macos/ web/ windows/  # Platform runners
└── tool/                         # Project utility scripts/tools
```

## Directory Purposes

**`lib/core/database/`:**
- Purpose: Define data model, migrations, indexes, and all SQL/query APIs.
- Contains: `app_database.dart`, Drift generated file `app_database.g.dart`, table specs.
- Key files: `lib/core/database/app_database.dart`, `lib/core/database/tables.dart`, `lib/core/database/tables.drift`.

**`lib/features/chronological_list/`:**
- Purpose: Main home experience for browsing, filtering, reordering, selecting, and opening items.
- Contains: Stateful list UI and item editor forms.
- Key files: `lib/features/chronological_list/presentation/item_list_screen.dart`, `lib/features/chronological_list/presentation/item_editor_screen.dart`.

**`lib/features/ingestion/`:**
- Purpose: Intake pipeline for shared content and extraction paths.
- Contains: Summary/extractor screens and ingestion/extraction services.
- Key files: `lib/features/ingestion/services/share_service.dart`, `lib/features/ingestion/services/extraction_service.dart`, `lib/features/ingestion/presentation/ingestion_summary_screen.dart`.

**`lib/features/organization/`:**
- Purpose: Label CRUD and assignment UI components.
- Contains: Label manager and modal selector sheets.
- Key files: `lib/features/organization/presentation/label_manager_screen.dart`, `lib/features/organization/presentation/label_selector_sheet.dart`.

**`lib/features/reader/`:**
- Purpose: Render extracted HTML and read/open/share saved items.
- Contains: Reader screen and URL launch actions.
- Key files: `lib/features/reader/presentation/reader_screen.dart`.

**`lib/features/settings/`:**
- Purpose: Persisted settings and app metadata/about pages.
- Contains: Settings service and settings/about screens.
- Key files: `lib/features/settings/services/settings_service.dart`, `lib/features/settings/presentation/settings_screen.dart`, `lib/features/settings/presentation/about_screen.dart`.

## Key File Locations

| Area | File | Purpose |
| --- | --- | --- |
| Entry point | `lib/main.dart` | App bootstrap, DI registration, theme, home route |
| Database facade | `lib/core/database/app_database.dart` | Persistence APIs, streams, migration strategy |
| Schema definitions | `lib/core/database/tables.dart` | Drift table structure and relations |
| FTS/index triggers | `lib/core/database/tables.drift` | Virtual table and trigger maintenance |
| Ingestion orchestrator | `lib/features/ingestion/services/share_service.dart` | Share-intent handling and route decisions |
| Main screen | `lib/features/chronological_list/presentation/item_list_screen.dart` | Primary UI workflow |
| Reader | `lib/features/reader/presentation/reader_screen.dart` | Offline content rendering |
| Tests | `test/core/database/app_database_test.dart` | Persistence test anchor |

## Naming Conventions

**Files:**
- Use `snake_case.dart` naming for Dart files (for example `item_list_screen.dart`, `settings_service.dart`).
- Use suffixes to encode role: `_screen.dart`, `_service.dart`, `_processor.dart`, `_sheet.dart`.

**Directories:**
- Use feature-first grouping under `lib/features/<feature_name>/`.
- Separate by concern with subfolders `presentation/` and `services/` when both UI and logic exist.

## Where to Add New Code

**New feature:**
- Primary code: `lib/features/<new_feature>/presentation/` for screens and local state.
- Service/business logic: `lib/features/<new_feature>/services/` for orchestration or external processing.
- Data access extensions: `lib/core/database/app_database.dart` and `lib/core/database/tables.dart` if schema/query changes are needed.
- Tests: `test/features/<new_feature>/...` matching source module shape.

**New component/module:**
- Reusable UI tied to one feature: place in that feature's `presentation/` folder.
- Cross-feature helpers: place in `lib/core/utils/`.

**Utilities:**
- Shared helper functions and formatting flows: `lib/core/utils/` (for example `lib/core/utils/share_utils.dart`).

## Special Directories

**`.planning/`:**
- Purpose: Roadmaps, phases, and generated planning/codebase documentation.
- Generated: No (human/agent maintained planning artifacts).
- Committed: Yes.

**`build/` and `.dart_tool/`:**
- Purpose: Build artifacts and generated tool state.
- Generated: Yes.
- Committed: No.

**Platform runner directories (`android/`, `ios/`, `linux/`, `macos/`, `web/`, `windows/`):**
- Purpose: Native wrappers and platform-specific configuration.
- Generated: Mixed (framework-generated baseline + manual edits).
- Committed: Yes.

---

*Structure analysis: 2026-04-04*
