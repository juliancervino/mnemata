# Mnemata (v1.0)

Mnemata is a centralized, cross-platform knowledge repository designed to help you save, extract, and organize content from across the web and your local files. Built with Flutter and SQLite, it offers a fast, offline-first experience for managing your digital references with modern intelligence features.

## Core Values

- **Permanent Saving**: Content is extracted and stored locally, ensuring you never lose access even if the original source disappears.
- **Clean Extraction**: Advanced readability algorithms strip away ads, trackers, and clutter, leaving only the content that matters.
- **Effortless Discovery**: Beyond full-text search (FTS5), Mnemata utilizes semantic intelligence to help you find information by meaning, not just keywords.
- **Secure Portability**: Your data belongs to you. Built-in cloud backup and local export ensure your collection is always safe and portable.

## Key Features

- **Native Ingestion**: Share URLs or files (PDFs, images) directly from any app on iOS or Android to Mnemata.
- **Intelligence & Advanced Reading**:
  - **AI Summaries**: Generate gated, distraction-free summaries for extracted articles (OpenAI/Claude).
  - **Semantic Search**: Discover items based on conceptual relevance.
  - **Tag Suggestions**: Context-aware suggestions from your existing tags during ingestion.
- **Cloud & Data Safety**:
  - **Secure Cloud Backup**: Automated and manual backups to Google Drive with manifest verification.
  - **Data Portability**: Complete export and import capabilities for entire collections.
  - **Restore Safety**: Manifest-validated restore process with integrity checks.
- **Guided Ingestion**: Review and refine titles, descriptions, and tags via a dedicated summary screen before saving.
- **Offline Reader**: A distraction-free reading experience for extracted web articles and indexed PDFs.
- **Powerful Organization**: 
  - **Multi-Tag Filtering**: Narrow down your collection by combining multiple tags with "AND" logic.
  - **Bulk Operations**: Manage, tag, or delete multiple items simultaneously.
  - **Manual Reordering**: Arrange your main list exactly how you want it with drag-and-drop.
- **PDF Intelligence**: Indexing of PDF text content and native file opening.

## Technical Architecture

- **Framework**: [Flutter](https://flutter.dev/) for high-performance cross-platform UI.
- **Database**: [Drift](https://drift.simonbinder.eu/) (SQLite) for reactive persistence and **FTS5** for full-text search.
- **Intelligence**: Integration with **OpenAI** and **Anthropic (Claude)** for summaries and semantic features, secured via encrypted local storage.
- **Cloud Services**: **Google Drive API** for secure, user-owned data backup.
- **Extraction**: [Readability](https://github.com/lucas-mancini/readability) (via FFI) for clean web content.
- **Service Locator**: [GetIt](https://pub.dev/packages/get_it) for robust dependency injection.

## Getting Started

### Prerequisites

- Flutter SDK (Latest stable version)
- Android Studio / Xcode (for mobile development)
- Google Cloud Project credentials (for Cloud Backup features)
- AI Provider API Key (Optional, for Intelligence features)

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/mnemata.git
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Generate database and model code:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```
4. Run the app:
   ```bash
   flutter run
   ```

### Run Web Locally (Testing URL)

To launch Mnemata as a local web server and test it in your browser:

1. Start the web server on a fixed port:
   ```bash
   flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
   ```
2. Open this URL in your browser:
   - `http://localhost:8080`

Notes:
- Flutter will print a line like `lib/main.dart is being served at http://0.0.0.0:8080`.
- Keep the terminal open while testing.
- To stop the web server, press `q` in the `flutter run` terminal.

### Google Drive Backup OAuth Setup

Cloud backup/restore requires both OAuth client IDs and Google Drive API enablement in the same Google Cloud project.

1. In Google Cloud Console, open your Mnemata project.
2. Enable Google Drive API (`APIs & Services` -> `Library` -> `Google Drive API` -> `Enable`).
3. Configure OAuth consent screen for your app.
4. Create OAuth client credentials for your target platform(s).
5. Pass client IDs at runtime:
   ```bash
   flutter run \
     --dart-define=GOOGLE_OAUTH_CLIENT_ID=<your_client_id> \
     --dart-define=GOOGLE_OAUTH_SERVER_CLIENT_ID=<your_server_client_id>
   ```

If Drive API is not enabled, backup/restore can fail with auth-like errors (for example `authenticationRequired`) even when the Google consent flow succeeds.

## Development

Mnemata follows a feature-first architectural pattern:
- `lib/core`: Shared database, security, and utility services.
- `lib/features/chronological_list`: Main list view, reordering, and item tile logic.
- `lib/features/ingestion`: Share intent handling, extraction services, and guided ingestion UI.
- `lib/features/intelligence`: AI provider integrations, semantic search, and summary services.
- `lib/features/backup`: Cloud backup (Google Drive) and local data portability logic.
- `lib/features/organization`: Label (Tag) management, filtering, and bulk operations.
- `lib/features/reader`: HTML/PDF rendering and distraction-free viewing.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
