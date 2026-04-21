# Codebase Structure

**Analysis Date:** 2024-05-24

## Directory Layout

```
lib/
├── core/                   # Application-wide shared infrastructure
│   ├── database/           # Drift schema, tables, and DB classes
│   ├── theme/              # Colors, typography, and AppTheme definition
│   ├── utils/              # Helper functions (e.g., ShareUtils)
│   └── widgets/            # Reusable UI components (ItemCard, TagChip)
├── features/               # Feature-sliced domains
│   ├── backup/             # Cloud sync and data export logic
│   ├── bookmarks/          # (Potentially legacy or specialized item handling)
│   ├── chronological_list/ # Main home screen and list viewing logic
│   ├── ingestion/          # Receiving intents, parsing URLs/PDFs
│   ├── intelligence/       # AI features: semantic search, summaries, tagging
│   ├── organization/       # Label/Tag management
│   ├── reader/             # Article and file viewing
│   └── settings/           # App configuration and API key management
└── main.dart               # App entry point and DI initialization
```

## Directory Purposes

**`lib/features/*/presentation/`:**
- Purpose: Contains UI elements specific to that feature.
- Contains: `StatefulWidget`s, `StatelessWidget`s, screens, sheets, dialogs.
- Key files: `lib/features/chronological_list/presentation/item_list_screen.dart`, `lib/features/reader/presentation/reader_screen.dart`.

**`lib/features/*/services/`:**
- Purpose: Contains the business logic and external integrations for the feature.
- Contains: Dart classes registered as singletons in `GetIt`.
- Key files: `lib/features/intelligence/services/summary_service.dart`, `lib/features/ingestion/services/share_service.dart`, `lib/features/backup/services/backup_scheduler_service.dart`.

## Key File Locations

**Entry Points:**
- `lib/main.dart`: Main function, DI setup (`setupLocator`), app root widget.

**Configuration:**
- `pubspec.yaml`: Dependency management and asset declarations.
- `lib/features/settings/services/settings_service.dart`: User preference state wrapper over `SharedPreferences`.

**Core Logic:**
- `lib/core/database/app_database.dart`: Defines all tables, streams, and queries for Drift SQLite.

**Testing:**
- `test/`: Unit and widget tests mapped mostly to feature structure or root flows.

## Naming Conventions

**Files:**
- snake_case: `item_list_screen.dart`, `semantic_search_service.dart`

**Directories:**
- snake_case: `chronological_list`, `core`

**Classes:**
- PascalCase: `ItemListScreen`, `AppDatabase`, `SemanticSearchService`

## Where to Add New Code

**New Feature:**
- Primary code: Create a new folder `lib/features/new_feature/`.
- UI: `lib/features/new_feature/presentation/`
- Logic: `lib/features/new_feature/services/`
- Tests: `test/features/new_feature/`

**New Component/Module:**
- Implementation: Put it inside the relevant feature folder. If it crosses multiple boundaries, it belongs in `lib/core/widgets` or `lib/core/utils`.

**Utilities:**
- Shared helpers: `lib/core/utils/`

## Special Directories

**`lib/core/database/`:**
- Purpose: Houses the Drift database schema.
- Generated: `app_database.g.dart` and `tables.drift.dart` are generated via `build_runner`.
- Committed: Generated files are generally tracked or built during CI.

---

*Structure analysis: 2024-05-24*