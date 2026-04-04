import 'package:flutter_test/flutter_test.dart';
import 'package:mnemata/features/backup/domain/backup_manifest.dart';

void main() {
  test('manifest serializes and deserializes with required fields', () {
    final manifest = BackupManifest(
      schemaVersion: 1,
      appVersion: '2.0.0',
      createdAtIso: '2026-04-04T00:00:00Z',
      entries: const [
        BackupManifestEntry(
          id: 'database',
          relativePath: 'database/mnemata_db.sqlite',
          sha256: 'abc123',
        ),
      ],
    );

    final json = manifest.toJson();
    final decoded = BackupManifest.fromJson(json);

    expect(decoded.schemaVersion, 1);
    expect(decoded.appVersion, '2.0.0');
    expect(decoded.createdAtIso, '2026-04-04T00:00:00Z');
    expect(decoded.entries, hasLength(1));
    expect(decoded.entries.first.id, 'database');
    expect(decoded.entries.first.relativePath, 'database/mnemata_db.sqlite');
    expect(decoded.entries.first.sha256, 'abc123');
  });

  test('manifest checksum validation fails on mismatched entry content', () {
    final bytes = 'same bytes'.codeUnits;
    final mismatchBytes = 'tampered bytes'.codeUnits;

    final manifest = BackupManifest(
      schemaVersion: 1,
      appVersion: '2.0.0',
      createdAtIso: '2026-04-04T00:00:00Z',
      entries: [
        BackupManifestEntry(
          id: 'settings',
          relativePath: 'settings/settings.json',
          sha256: BackupManifest.computeSha256Hex(bytes),
        ),
      ],
    );

    expect(manifest.validateChecksums({'settings': bytes}), isTrue);
    expect(manifest.validateChecksums({'settings': mismatchBytes}), isFalse);
  });
}
