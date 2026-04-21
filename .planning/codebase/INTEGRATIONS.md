# External Integrations

**Analysis Date:** 2024-05-24

## APIs & External Services

**Intelligence / LLM Providers:**
- Google Gemini - Generative AI (`gemini-2.5-flash-lite`).
  - Implementation: Built-in HTTP integration to `generativelanguage.googleapis.com`.
  - Auth: API Key (`mnemata.intelligence.apiKey` stored securely).
- OpenAI - Generative AI (`gpt-5-nano`).
  - Implementation: Built-in HTTP integration to `api.openai.com`.
  - Auth: Bearer Token (API Key stored securely).
- Anthropic Claude - Generative AI (`claude-haiku-4-5-20251001`).
  - Implementation: Built-in HTTP integration to `api.anthropic.com`.
  - Auth: API Key (`x-api-key` header stored securely).

**File Backup & Cloud Storage:**
- Google Drive API - Cloud syncing of SQLite databases and assets.
  - Implementation: Custom HTTP Client (`GoogleDriveHttpClient`) built around `http` and `googleapis.com/drive/v3`.
  - Auth: OAuth Access Tokens via `google_sign_in`.

## Data Storage

**Databases:**
- SQLite (Drift ORM)
  - Connection: Local disk initialization for native platforms; `sqlite3.wasm` and Web Workers (`drift_worker.js`) for the Web.
  - Client: `drift` and `drift_flutter` packages.

**File Storage:**
- Local filesystem only (via `path_provider`).
- Google Drive for cloud-based exports and backups.

**Caching:**
- None for explicit caching. AI responses and embedding representations (like Semantic Chunks, Summaries, Index States) are cached persistently within the primary SQLite Database (`SummaryCaches`, `SemanticIndexStates`, `SemanticChunks` tables).

## Authentication & Identity

**Auth Provider:**
- Custom (Offline First)
  - Implementation: The app operates entirely offline and requires no centralized authentication.
- Google Sign-In
  - Implementation: Strictly used for acquiring OAuth authorization to user's Google Drive (`auth/drive.appdata` scope) for backing up data. This runs via `GoogleDriveAuthClient`.

## Monitoring & Observability

**Error Tracking:**
- None built-in. Standard Flutter exception reporting.

**Logs:**
- Basic runtime debug and logging (`debugPrint`/`print`). No external logging aggregation services detected.

## CI/CD & Deployment

**Hosting:**
- Not applicable for native targets; typically hosted on standard static file servers or CDN for Web implementations.

**CI Pipeline:**
- Standard Flutter CI mechanisms implied, but no specific external pipelines (like GitHub Actions definitions or Bitrise) were reviewed.

## Environment Configuration

**Required env vars:**
- `GOOGLE_OAUTH_CLIENT_ID`: Required for Google Sign-In on Web (via `--dart-define` or injected `<meta>` tags in `web/index.html`).

**Secrets location:**
- External AI Provider API keys are entered by the user within the App settings at runtime and written locally to `flutter_secure_storage`.
  - Keys are namespaced using `mnemata.intelligence.apiKey.[provider]`.

## Webhooks & Callbacks

**Incoming:**
- System URL Handlers (`receive_sharing_intent`) - OS-level hooks for dropping links, files, or text directly into the application.

**Outgoing:**
- None

---

*Integration audit: 2024-05-24*
