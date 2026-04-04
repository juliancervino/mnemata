# External Integrations

**Analysis Date:** 2026-04-04

## APIs & External Services

**Web content ingestion:**
- Arbitrary public websites are fetched for metadata/content extraction.
  - SDK/Client: `http`, `metadata_fetch`, `readability`, `favicon` in `lib/features/ingestion/services/extraction_service.dart`.
  - Auth: Not required by current implementation (no API key or OAuth flow detected).

**Archive-hosted page handling:**
- Archive mirrors are specially recognized and routed for manual JS-assisted extraction.
  - Domains handled: `archive.ph`, `archive.today`, `archive.is`, `archive.li`, `archive.vn`, `archive.fo`, `archive.md`, `archive.moe` in `lib/features/ingestion/services/share_service.dart`.
  - SDK/Client: `webview_flutter` + custom processors in `lib/features/ingestion/presentation/archive_scraper_screen.dart` and `lib/features/ingestion/services/archive_content_processor.dart`.

## Data Storage

**Databases:**
- SQLite via Drift.
  - Connection: local on-device DB opened with `driftDatabase(name: 'mnemata_db')` in `lib/core/database/app_database.dart`.
  - Client: `drift`/`drift_flutter` in `lib/core/database/app_database.dart`.
  - Search: SQLite FTS5 module enabled in `build.yaml` and materialized in generated SQL in `lib/core/database/app_database.g.dart`.

**File Storage:**
- Local app documents directory for copied inbound files in `lib/features/ingestion/services/share_service.dart`.
- Temporary filesystem use during readability fallback in `lib/features/ingestion/services/extraction_service.dart`.

**Caching:**
- Network image caching through `cached_network_image` in `lib/features/chronological_list/presentation/item_list_screen.dart`.
- Plugin/runtime caching directories are generated under `build/` (tool-managed artifacts).

## Authentication & Identity

**Auth Provider:**
- Custom/no user authentication layer detected.
  - Implementation: local-only app state, no account/session service referenced in `lib/`.

## Monitoring & Observability

**Error Tracking:**
- None detected (no Sentry/Firebase Crashlytics/etc. dependency in `pubspec.yaml`).

**Logs:**
- Runtime diagnostics via `debugPrint(...)` and occasional `print(...)` in ingestion services (for example `lib/features/ingestion/services/share_service.dart`, `lib/features/ingestion/services/extraction_service.dart`).

## CI/CD & Deployment

**Hosting:**
- App is configured for device/desktop/web distribution via Flutter target directories (`android/`, `ios/`, `macos/`, `linux/`, `windows/`, `web/`).

**CI Pipeline:**
- Not detected (`.github/workflows/` absent).

## Environment Configuration

**Required env vars:**
- Not detected; no environment variable lookups under `lib/`.

**Secrets location:**
- No repository-managed secret file pattern detected (`.env*` not present at root).
- Platform/local developer config exists in `android/local.properties` (path noted; values not inspected).

## Webhooks & Callbacks

**Incoming:**
- OS share intent callback stream through `ReceiveSharingIntent.instance.getMediaStream()` and initial payload via `getInitialMedia()` in `lib/features/ingestion/services/share_service.dart`.
- iOS document handling for PDFs declared in `ios/Runner/Info.plist` (`CFBundleDocumentTypes`).

**Outgoing:**
- External browser handoff via `launchUrl(..., mode: LaunchMode.externalApplication)` in `lib/features/reader/presentation/reader_screen.dart`.
- Outbound share sheet dispatch via `Share.share(...)` in `lib/core/utils/share_utils.dart`.

---

*Integration audit: 2026-04-04*