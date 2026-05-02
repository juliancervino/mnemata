# Mnemata Project Overview

Mnemata is a centralized, cross-platform knowledge repository built with Flutter. It allows users to save, extract, and organize content from the web (URLs) and local files (PDFs, images) into a permanent, searchable, offline-first collection.


## Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

### 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

### 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

### 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

### 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.
## Technical Architecture

- **Framework**: Flutter (Cross-platform UI).
- **Architecture**: Feature-first structure (`lib/features/`).
- **Persistence**: SQLite via [Drift](https://drift.simonbinder.eu/) with **FTS5** for full-text search.
- **Dependency Injection**: [GetIt](https://pub.dev/packages/get_it) service locator.
- **Key Features**:
  - **Ingestion**: native sharing intents, URL/file extraction.
  - **Intelligence**: AI-generated summaries (OpenAI/Claude), semantic search.
  - **Backup**: Google Drive cloud backup/restore.
  - **Reader**: Distraction-free reading for web articles and PDFs.

## Directory Structure

- `lib/core/`: Shared database, theme, utilities, and common widgets.
- `lib/features/`: domain-specific logic and UI (Backup, Chronological List, Ingestion, Intelligence, Organization, Reader, Settings).
- `assets/`: Fonts (Geist) and images.
- `handoff/`: Detailed design specifications and tokens (Reference only).
- `test/`: Unit and widget tests.

## Building and Running

### Prerequisites
- Flutter SDK (latest stable).
- Android Studio / Xcode for mobile platforms.

### Commands
- **Install dependencies**: `flutter pub get`
- **Code generation**: `flutter pub run build_runner build --delete-conflicting-outputs` (Required for Drift database and model updates).
- **Run the app**: `flutter run`
- **Run Web locally**: `flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080`
- **Run tests**: `flutter test`

### Google Drive Backup Setup
Pass client IDs at runtime for backup features:
```bash
flutter run \
  --dart-define=GOOGLE_OAUTH_CLIENT_ID=<your_client_id> \
  --dart-define=GOOGLE_OAUTH_SERVER_CLIENT_ID=<your_server_client_id>
```

## Development Conventions

### UI and Design
- **Strict Token Usage**: Always use `MnemataTheme`, `MnemataColors`, and `MnemataRadii` from `lib/core/theme/app_theme.dart`.
- **No Hardcoding**: Never hardcode colors (`Colors.xxx`) or font sizes in feature code. Use `Theme.of(context).colorScheme` or `textTheme`.
- **Typography**: 
  - **Serif** (Instrument Serif) for article titles and reader body.
  - **Sans** (Geist) for general UI.
  - **Mono** (JetBrains Mono) for metadata and tracked kickers.
- **Shared Widgets**: Use `TagChip`, `ItemCard`, and `SectionLabel` from `lib/core/widgets/` to maintain consistency.
- **Dark Mode**: Support both Light and Dark themes (`ThemeMode.system`).

### Coding Style
- **Separation of Concerns**: Keep business logic in Services (`lib/features/*/services/`) and UI in Presentation (`lib/features/*/presentation/`).
- **Dependency Injection**: Register and retrieve services via `getIt` (initialized in `lib/main.dart`).
- **Back Navigation**: Always include an explicit back button (`Icons.arrow_back_ios_new`) in custom headers for pushed screens.
- **HTML Extraction**: Articles are extracted into `plainContent` and rendered with `SelectableText.rich`.

## Testing Practices
- Use `mocktail` for mocking dependencies.
- Ensure new features include unit/widget tests in the `test/` directory.
- Verify UI changes in both Light and Dark modes.
