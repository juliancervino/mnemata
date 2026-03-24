# Mnemata

Mnemata is a centralized, cross-platform knowledge repository designed to help you save, extract, and organize content from across the web and your local files. Built with Flutter and SQLite, it offers a fast, offline-first experience for managing your digital references.

## Core Values

- **Permanent Saving**: Content is extracted and stored locally, ensuring you never lose access even if the original source disappears.
- **Clean Extraction**: Advanced readability algorithms strip away ads, trackers, and clutter, leaving only the content that matters.
- **Effortless Discovery**: Full-text search (FTS5) indexes everything—from item titles and URLs to the extracted body text and PDF contents.
- **Intuitive Organization**: A flexible tagging system with multi-select "AND" filtering allows for powerful, yet simple, categorization.

## Key Features

- **Native Ingestion**: Share URLs or files (PDFs, images) directly from any app on iOS or Android to Mnemata.
- **Smart URL Extraction**: Automatically finds URLs within shared text.
- **Guided Ingestion**: Edit titles and assign tags via a summary screen before saving.
- **Offline Reader**: A distraction-free reading experience for extracted web articles.
- **PDF Intelligence**: Indexing of PDF text content and native file opening.
- **Multi-Tag Filtering**: Narrow down your collection by combining multiple tags.
- **Manual Reordering**: Arrange your main list exactly how you want it with drag-and-drop.
- **Reading History**: Quick access to your most recently opened items.

## Technical Architecture

- **Framework**: [Flutter](https://flutter.dev/) for cross-platform UI.
- **Database**: [Drift](https://drift.simonbinder.eu/) (SQLite) for reactive persistence.
- **Search**: SQLite **FTS5** for high-performance full-text search.
- **Extraction**: [Readability](https://github.com/lucas-mancini/readability) (via FFI) for clean web content.
- **Service Locator**: [GetIt](https://pub.dev/packages/get_it) for dependency injection.

## Getting Started

### Prerequisites

- Flutter SDK (Latest stable version)
- Android Studio / Xcode (for mobile development)

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/mnemata.git
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Generate database code:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```
4. Run the app:
   ```bash
   flutter run
   ```

## Development

Mnemata follows a feature-first architectural pattern:
- `lib/core`: Shared database, tables, and themes.
- `lib/features/chronological_list`: Main list view, reordering, and item tile logic.
- `lib/features/ingestion`: Share intent handling, extraction services, and summary screen.
- `lib/features/organization`: Label (Tag) management and selection UI.
- `lib/features/reader`: HTML rendering and offline reading view.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
