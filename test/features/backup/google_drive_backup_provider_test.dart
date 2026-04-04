import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mnemata/features/backup/services/cloud_backup_provider.dart';
import 'package:mnemata/features/backup/services/google_drive_backup_provider.dart';

void main() {
  test('GoogleDriveBackupProvider implements CloudBackupProvider contract', () {
    final provider = GoogleDriveBackupProvider(
      client: _FakeGoogleDriveClient(),
    );

    expect(provider, isA<CloudBackupProvider>());
  });

  test('GoogleDriveBackupProvider maps provider failures deterministically', () async {
    final provider = GoogleDriveBackupProvider(
      client: _FakeGoogleDriveClient(
        failure: const GoogleDriveProviderFailure(
          type: GoogleDriveProviderFailureType.rateLimited,
          message: 'quota exceeded',
        ),
      ),
    );

    final tempDir = await Directory.systemTemp.createTemp('drive_provider_test_');
    final archive = File('${tempDir.path}/backup.zip');
    await archive.writeAsBytes(const <int>[1, 2, 3], flush: true);

    try {
      expect(
        () => provider.uploadBackup(archivePath: archive.path),
        throwsA(
          isA<CloudBackupProviderException>().having(
            (error) => error.code,
            'code',
            CloudBackupProviderErrorCode.rateLimited,
          ),
        ),
      );
    } finally {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    }
  });
}

class _FakeGoogleDriveClient implements GoogleDriveClient {
  _FakeGoogleDriveClient({this.failure});

  final GoogleDriveProviderFailure? failure;

  @override
  Future<GoogleDriveUploadResult> uploadArchive({
    required String archivePath,
    required String backupId,
  }) async {
    if (failure != null) {
      throw failure!;
    }

    return GoogleDriveUploadResult(
      backupId: backupId,
      remoteId: 'remote-$backupId',
      uploadedAt: DateTime.utc(2026, 4, 4),
    );
  }

  @override
  Future<List<GoogleDriveBackupRecord>> listArchives() async {
    if (failure != null) {
      throw failure!;
    }

    return const <GoogleDriveBackupRecord>[];
  }

  @override
  Future<GoogleDriveDownloadResult> downloadArchive({
    required String remoteId,
    required String backupId,
  }) async {
    if (failure != null) {
      throw failure!;
    }

    return GoogleDriveDownloadResult(
      backupId: backupId,
      bytes: const <int>[1],
    );
  }
}
