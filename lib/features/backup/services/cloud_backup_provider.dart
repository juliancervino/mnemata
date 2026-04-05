import 'dart:typed_data';

enum CloudBackupProviderErrorCode {
  authenticationRequired,
  permissionDenied,
  rateLimited,
  networkUnavailable,
  notFound,
  invalidArchive,
  unknown,
}

class CloudBackupProviderException implements Exception {
  const CloudBackupProviderException({
    required this.code,
    required this.message,
    this.cause,
  });

  final CloudBackupProviderErrorCode code;
  final String message;
  final Object? cause;

  @override
  String toString() =>
      'CloudBackupProviderException(code: $code, message: $message)';
}

class CloudBackupUploadReceipt {
  const CloudBackupUploadReceipt({
    required this.backupId,
    required this.remoteId,
    required this.uploadedAt,
  });

  final String backupId;
  final String remoteId;
  final DateTime uploadedAt;
}

class CloudBackupDescriptor {
  const CloudBackupDescriptor({
    required this.backupId,
    required this.remoteId,
    required this.createdAt,
    this.sizeBytes,
  });

  final String backupId;
  final String remoteId;
  final DateTime createdAt;
  final int? sizeBytes;
}

abstract class CloudBackupProvider {
  Future<CloudBackupUploadReceipt> uploadBackup({required String archivePath});

  Future<List<CloudBackupDescriptor>> listBackups();

  Future<Uint8List> downloadBackup({required String backupId});

  Future<void> deleteBackup({required String backupId});
}
