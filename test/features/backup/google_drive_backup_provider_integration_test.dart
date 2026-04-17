import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mnemata/features/backup/services/cloud_backup_provider.dart';
import 'package:mnemata/features/backup/services/google_drive_auth_client.dart';
import 'package:mnemata/features/backup/services/google_drive_backup_provider.dart';

void main() {
  test(
    'authenticated provider upload/list/download succeeds with runtime token',
    () async {
      final authClient = GoogleDriveAuthClient(
        accessTokenProvider: () async => 'token-123',
        refreshTokenProvider: () async => 'token-123',
        clock: () => DateTime.utc(2026, 4, 5),
        expirySkew: const Duration(seconds: 30),
      );
      final driveClient = _RecordingGoogleDriveClient();
      final provider = GoogleDriveBackupProvider(
        authClient: authClient,
        client: driveClient,
      );

      final tempDir = await Directory.systemTemp.createTemp(
        'drive_provider_integration_',
      );
      final archiveFile = File('${tempDir.path}/mnemata_backup.zip');
      await archiveFile.writeAsBytes(const <int>[1, 2, 3], flush: true);

      try {
        final upload = await provider.uploadBackup(
          archivePath: archiveFile.path,
        );
        final listed = await provider.listBackups();
        final downloaded = await provider.downloadBackup(
          backupId: upload.backupId,
        );

        expect(upload.remoteId, equals('remote-${upload.backupId}'));
        expect(listed, hasLength(1));
        expect(downloaded, equals(const <int>[9, 8, 7]));
        expect(
          driveClient.seenTokens,
          equals(<String>['token-123', 'token-123', 'token-123', 'token-123']),
        );
      } finally {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    },
  );

  test(
    'auth failures map to authenticationRequired without deferred stubs',
    () async {
      final authClient = GoogleDriveAuthClient(
        accessTokenProvider: () async => throw const GoogleDriveAuthException(
          code: GoogleDriveAuthErrorCode.notSignedIn,
          message: 'Sign in required.',
        ),
        refreshTokenProvider: () async => throw const GoogleDriveAuthException(
          code: GoogleDriveAuthErrorCode.notSignedIn,
          message: 'Sign in required.',
        ),
        clock: () => DateTime.utc(2026, 4, 5),
        expirySkew: const Duration(seconds: 30),
      );
      final provider = GoogleDriveBackupProvider(
        authClient: authClient,
        client: _RecordingGoogleDriveClient(),
      );

      final tempDir = await Directory.systemTemp.createTemp(
        'drive_provider_auth_failure_',
      );
      final archiveFile = File('${tempDir.path}/mnemata_backup.zip');
      await archiveFile.writeAsBytes(const <int>[4, 5, 6], flush: true);

      try {
        await expectLater(
          () => provider.uploadBackup(archivePath: archiveFile.path),
          throwsA(
            isA<CloudBackupProviderException>().having(
              (error) => error.code,
              'code',
              CloudBackupProviderErrorCode.authenticationRequired,
            ),
          ),
        );
      } finally {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    },
  );

  test('upload retries with forced refresh after auth failure', () async {
    final issuedTokens = <String>['stale-token', 'fresh-token'];
    final authClient = GoogleDriveAuthClient(
      accessTokenProvider: () async => issuedTokens.removeAt(0),
      refreshTokenProvider: () async => issuedTokens.removeAt(0),
      clock: () => DateTime.utc(2026, 4, 5),
      expirySkew: const Duration(seconds: 30),
    );
    final driveClient = _FlakyAuthGoogleDriveClient();
    final provider = GoogleDriveBackupProvider(
      authClient: authClient,
      client: driveClient,
    );

    final tempDir = await Directory.systemTemp.createTemp(
      'drive_provider_retry_',
    );
    final archiveFile = File('${tempDir.path}/mnemata_backup.zip');
    await archiveFile.writeAsBytes(const <int>[1, 2, 3], flush: true);

    try {
      final upload = await provider.uploadBackup(archivePath: archiveFile.path);
      expect(upload.remoteId, equals('remote-${upload.backupId}'));
      expect(
        driveClient.seenTokens,
        equals(<String>['stale-token', 'fresh-token']),
      );
    } finally {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    }
  });
}

class _RecordingGoogleDriveClient implements GoogleDriveClient {
  final List<String> seenTokens = <String>[];
  GoogleDriveBackupRecord? _lastRecord;

  @override
  Future<GoogleDriveUploadResult> uploadArchive({
    required String accessToken,
    required String archivePath,
    required String backupId,
  }) async {
    seenTokens.add(accessToken);
    _lastRecord = GoogleDriveBackupRecord(
      backupId: backupId,
      remoteId: 'remote-$backupId',
      createdAt: DateTime.utc(2026, 4, 5),
    );

    return GoogleDriveUploadResult(
      backupId: backupId,
      remoteId: _lastRecord!.remoteId,
      uploadedAt: DateTime.utc(2026, 4, 5),
    );
  }

  @override
  Future<List<GoogleDriveBackupRecord>> listArchives({
    required String accessToken,
  }) async {
    seenTokens.add(accessToken);
    if (_lastRecord == null) {
      return const <GoogleDriveBackupRecord>[];
    }

    return <GoogleDriveBackupRecord>[_lastRecord!];
  }

  @override
  Future<GoogleDriveDownloadResult> downloadArchive({
    required String accessToken,
    required String remoteId,
    required String backupId,
  }) async {
    seenTokens.add(accessToken);
    return GoogleDriveDownloadResult(
      backupId: backupId,
      bytes: const <int>[9, 8, 7],
    );
  }

  @override
  Future<void> deleteArchive({
    required String accessToken,
    required String remoteId,
  }) async {
    seenTokens.add(accessToken);
    if (_lastRecord?.remoteId == remoteId) {
      _lastRecord = null;
    }
  }
}

class _FlakyAuthGoogleDriveClient implements GoogleDriveClient {
  final List<String> seenTokens = <String>[];

  @override
  Future<GoogleDriveUploadResult> uploadArchive({
    required String accessToken,
    required String archivePath,
    required String backupId,
  }) async {
    seenTokens.add(accessToken);
    if (accessToken == 'stale-token') {
      throw const GoogleDriveProviderFailure(
        type: GoogleDriveProviderFailureType.auth,
        message: 'Google Drive authentication failed.',
      );
    }

    return GoogleDriveUploadResult(
      backupId: backupId,
      remoteId: 'remote-$backupId',
      uploadedAt: DateTime.utc(2026, 4, 5),
    );
  }

  @override
  Future<List<GoogleDriveBackupRecord>> listArchives({
    required String accessToken,
  }) async {
    return const <GoogleDriveBackupRecord>[];
  }

  @override
  Future<GoogleDriveDownloadResult> downloadArchive({
    required String accessToken,
    required String remoteId,
    required String backupId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteArchive({
    required String accessToken,
    required String remoteId,
  }) {
    throw UnimplementedError();
  }
}
