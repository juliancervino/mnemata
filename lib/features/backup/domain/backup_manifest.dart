import 'package:crypto/crypto.dart';

class BackupManifestEntry {
  const BackupManifestEntry({
    required this.id,
    required this.relativePath,
    required this.sha256,
  });

  final String id;
  final String relativePath;
  final String sha256;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'relativePath': relativePath,
      'sha256': sha256,
    };
  }

  factory BackupManifestEntry.fromJson(Map<String, dynamic> json) {
    return BackupManifestEntry(
      id: json['id'] as String,
      relativePath: json['relativePath'] as String,
      sha256: json['sha256'] as String,
    );
  }
}

class BackupManifest {
  const BackupManifest({
    required this.schemaVersion,
    required this.appVersion,
    required this.createdAtIso,
    required this.entries,
  });

  final int schemaVersion;
  final String appVersion;
  final String createdAtIso;
  final List<BackupManifestEntry> entries;

  Map<String, dynamic> toJson() {
    final sortedEntries = List<BackupManifestEntry>.from(entries)
      ..sort((a, b) => a.id.compareTo(b.id));

    return {
      'schemaVersion': schemaVersion,
      'appVersion': appVersion,
      'createdAtIso': createdAtIso,
      'entries': sortedEntries.map((entry) => entry.toJson()).toList(),
    };
  }

  factory BackupManifest.fromJson(Map<String, dynamic> json) {
    final rawEntries = json['entries'] as List<dynamic>? ?? const [];
    return BackupManifest(
      schemaVersion: json['schemaVersion'] as int,
      appVersion: json['appVersion'] as String,
      createdAtIso: json['createdAtIso'] as String,
      entries: rawEntries
          .map((entry) => BackupManifestEntry.fromJson(entry as Map<String, dynamic>))
          .toList(),
    );
  }

  static String computeSha256Hex(List<int> bytes) {
    return sha256.convert(bytes).toString();
  }

  bool validateChecksums(Map<String, List<int>> artifactBytesById) {
    return checksumMismatches(artifactBytesById).isEmpty;
  }

  List<String> checksumMismatches(Map<String, List<int>> artifactBytesById) {
    final mismatches = <String>[];

    for (final entry in entries) {
      final bytes = artifactBytesById[entry.id];
      if (bytes == null) {
        mismatches.add(entry.id);
        continue;
      }

      final computed = computeSha256Hex(bytes);
      if (computed != entry.sha256) {
        mismatches.add(entry.id);
      }
    }

    return mismatches;
  }
}
