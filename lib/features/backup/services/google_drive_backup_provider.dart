import 'dart:io';
import 'dart:typed_data';

import 'package:mnemata/features/backup/services/cloud_backup_provider.dart';
import 'package:path/path.dart' as p;

enum GoogleDriveProviderFailureType {
  auth,
  permissionDenied,
  rateLimited,
  network,
  notFound,
  invalidPayload,
  unknown,
}

class GoogleDriveProviderFailure implements Exception {
  const GoogleDriveProviderFailure({
    required this.type,
    required this.message,
  });

  final GoogleDriveProviderFailureType type;
  final String message;
}

class GoogleDriveUploadResult {
  const GoogleDriveUploadResult({
    required this.backupId,
    required this.remoteId,
    required this.uploadedAt,
  });

  final String backupId;
  final String remoteId;
  final DateTime uploadedAt;
}

class GoogleDriveBackupRecord {
  const GoogleDriveBackupRecord({
    required this.backupId,
    required this.remoteId,
    required this.createdAt,
  });

  final String backupId;
  final String remoteId;
  final DateTime createdAt;
}

class GoogleDriveDownloadResult {
  const GoogleDriveDownloadResult({
    required this.backupId,
    required this.bytes,
  });

  final String backupId;
  final List<int> bytes;
}

abstract class GoogleDriveClient {
  Future<GoogleDriveUploadResult> uploadArchive({
    required String archivePath,
    required String backupId,
  });

  Future<List<GoogleDriveBackupRecord>> listArchives();

  Future<GoogleDriveDownloadResult> downloadArchive({
    required String remoteId,
    required String backupId,
  });
}

class GoogleDriveBackupProvider implements CloudBackupProvider {
  GoogleDriveBackupProvider({required GoogleDriveClient client}) : _client = client;

  final GoogleDriveClient _client;

  @override
  Future<CloudBackupUploadReceipt> uploadBackup({required String archivePath}) async {
    final archiveFile = File(archivePath);
    if (!await archiveFile.exists()) {
      throw const CloudBackupProviderException(
        code: CloudBackupProviderErrorCode.invalidArchive,
        message: 'Backup archive does not exist.',
      );
    }

    if (!archivePath.toLowerCase().endsWith('.zip')) {
      throw const CloudBackupProviderException(
        code: CloudBackupProviderErrorCode.invalidArchive,
        message: 'Backup archive must be a .zip file.',
      );
    }

    final length = await archiveFile.length();
    if (length == 0) {
      throw const CloudBackupProviderException(
        code: CloudBackupProviderErrorCode.invalidArchive,
        message: 'Backup archive cannot be empty.',
      );
    }

    final backupId = _buildBackupId(archivePath);

    try {
      final result = await _client.uploadArchive(
        archivePath: archivePath,
        backupId: backupId,
      );

      return CloudBackupUploadReceipt(
        backupId: result.backupId,
        remoteId: result.remoteId,
        uploadedAt: result.uploadedAt,
      );
    } on GoogleDriveProviderFailure catch (error) {
      throw _mapFailure(error);
    }
  }

  @override
  Future<List<CloudBackupDescriptor>> listBackups() async {
    try {
      final records = await _client.listArchives();
      return records
          .map(
            (record) => CloudBackupDescriptor(
              backupId: record.backupId,
              remoteId: record.remoteId,
              createdAt: record.createdAt,
            ),
          )
          .toList(growable: false);
    } on GoogleDriveProviderFailure catch (error) {
      throw _mapFailure(error);
    }
  }

  @override
  Future<Uint8List> downloadBackup({required String backupId}) async {
    try {
      final records = await _client.listArchives();
      final record = _findRecordByBackupId(records, backupId);
      if (record == null) {
        throw const CloudBackupProviderException(
          code: CloudBackupProviderErrorCode.notFound,
          message: 'Requested backup was not found in Google Drive.',
        );
      }

      final result = await _client.downloadArchive(
        remoteId: record.remoteId,
        backupId: backupId,
      );

      if (result.bytes.isEmpty) {
        throw const CloudBackupProviderException(
          code: CloudBackupProviderErrorCode.invalidArchive,
          message: 'Downloaded archive was empty.',
        );
      }

      return Uint8List.fromList(result.bytes);
    } on GoogleDriveProviderFailure catch (error) {
      throw _mapFailure(error);
    }
  }

  String _buildBackupId(String archivePath) {
    final basename = p.basenameWithoutExtension(archivePath).trim();
    if (basename.isNotEmpty) {
      return basename;
    }

    return DateTime.now().toUtc().millisecondsSinceEpoch.toString();
  }

  GoogleDriveBackupRecord? _findRecordByBackupId(
    List<GoogleDriveBackupRecord> records,
    String backupId,
  ) {
    for (final record in records) {
      if (record.backupId == backupId) {
        return record;
      }
    }

    return null;
  }

  CloudBackupProviderException _mapFailure(GoogleDriveProviderFailure failure) {
    switch (failure.type) {
      case GoogleDriveProviderFailureType.auth:
        return CloudBackupProviderException(
          code: CloudBackupProviderErrorCode.authenticationRequired,
          message: failure.message,
          cause: failure,
        );
      case GoogleDriveProviderFailureType.permissionDenied:
        return CloudBackupProviderException(
          code: CloudBackupProviderErrorCode.permissionDenied,
          message: failure.message,
          cause: failure,
        );
      case GoogleDriveProviderFailureType.rateLimited:
        return CloudBackupProviderException(
          code: CloudBackupProviderErrorCode.rateLimited,
          message: failure.message,
          cause: failure,
        );
      case GoogleDriveProviderFailureType.network:
        return CloudBackupProviderException(
          code: CloudBackupProviderErrorCode.networkUnavailable,
          message: failure.message,
          cause: failure,
        );
      case GoogleDriveProviderFailureType.notFound:
        return CloudBackupProviderException(
          code: CloudBackupProviderErrorCode.notFound,
          message: failure.message,
          cause: failure,
        );
      case GoogleDriveProviderFailureType.invalidPayload:
        return CloudBackupProviderException(
          code: CloudBackupProviderErrorCode.invalidArchive,
          message: failure.message,
          cause: failure,
        );
      case GoogleDriveProviderFailureType.unknown:
        return CloudBackupProviderException(
          code: CloudBackupProviderErrorCode.unknown,
          message: failure.message,
          cause: failure,
        );
    }
  }
}
