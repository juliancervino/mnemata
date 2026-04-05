import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mnemata/features/backup/services/cloud_backup_provider.dart';
import 'package:mnemata/features/backup/services/google_drive_auth_client.dart';
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
  const GoogleDriveProviderFailure({required this.type, required this.message});

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
    this.sizeBytes,
  });

  final String backupId;
  final String remoteId;
  final DateTime createdAt;
  final int? sizeBytes;
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
    required String accessToken,
    required String archivePath,
    required String backupId,
  });

  Future<List<GoogleDriveBackupRecord>> listArchives({
    required String accessToken,
  });

  Future<GoogleDriveDownloadResult> downloadArchive({
    required String accessToken,
    required String remoteId,
    required String backupId,
  });

  Future<void> deleteArchive({
    required String accessToken,
    required String remoteId,
  });
}

class GoogleDriveBackupProvider implements CloudBackupProvider {
  GoogleDriveBackupProvider({
    required GoogleDriveAuthClient authClient,
    required GoogleDriveClient client,
  }) : _authClient = authClient,
       _client = client;

  final GoogleDriveAuthClient _authClient;
  final GoogleDriveClient _client;

  @override
  Future<CloudBackupUploadReceipt> uploadBackup({
    required String archivePath,
  }) async {
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
      final accessToken = await _authClient.refreshIfNeeded();
      final result = await _client.uploadArchive(
        accessToken: accessToken,
        archivePath: archivePath,
        backupId: backupId,
      );

      return CloudBackupUploadReceipt(
        backupId: result.backupId,
        remoteId: result.remoteId,
        uploadedAt: result.uploadedAt,
      );
    } on GoogleDriveAuthException catch (error) {
      throw CloudBackupProviderException(
        code: CloudBackupProviderErrorCode.authenticationRequired,
        message: error.message,
        cause: error,
      );
    } on GoogleDriveProviderFailure catch (error) {
      throw _mapFailure(error);
    }
  }

  @override
  Future<List<CloudBackupDescriptor>> listBackups() async {
    try {
      final accessToken = await _authClient.refreshIfNeeded();
      final records = await _client.listArchives(accessToken: accessToken);
      return records
          .map(
            (record) => CloudBackupDescriptor(
              backupId: record.backupId,
              remoteId: record.remoteId,
              createdAt: record.createdAt,
              sizeBytes: record.sizeBytes,
            ),
          )
          .toList(growable: false);
    } on GoogleDriveAuthException catch (error) {
      throw CloudBackupProviderException(
        code: CloudBackupProviderErrorCode.authenticationRequired,
        message: error.message,
        cause: error,
      );
    } on GoogleDriveProviderFailure catch (error) {
      throw _mapFailure(error);
    }
  }

  @override
  Future<Uint8List> downloadBackup({required String backupId}) async {
    try {
      final accessToken = await _authClient.refreshIfNeeded();
      final records = await _client.listArchives(accessToken: accessToken);
      final record = _findRecordByBackupId(records, backupId);
      if (record == null) {
        throw const CloudBackupProviderException(
          code: CloudBackupProviderErrorCode.notFound,
          message: 'Requested backup was not found in Google Drive.',
        );
      }

      final result = await _client.downloadArchive(
        accessToken: accessToken,
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
    } on GoogleDriveAuthException catch (error) {
      throw CloudBackupProviderException(
        code: CloudBackupProviderErrorCode.authenticationRequired,
        message: error.message,
        cause: error,
      );
    } on GoogleDriveProviderFailure catch (error) {
      throw _mapFailure(error);
    }
  }

  @override
  Future<void> deleteBackup({required String backupId}) async {
    try {
      final accessToken = await _authClient.refreshIfNeeded();
      final records = await _client.listArchives(accessToken: accessToken);
      final record = _findRecordByBackupId(records, backupId);
      if (record == null) {
        throw const CloudBackupProviderException(
          code: CloudBackupProviderErrorCode.notFound,
          message: 'Requested backup was not found in Google Drive.',
        );
      }

      await _client.deleteArchive(
        accessToken: accessToken,
        remoteId: record.remoteId,
      );
    } on GoogleDriveAuthException catch (error) {
      throw CloudBackupProviderException(
        code: CloudBackupProviderErrorCode.authenticationRequired,
        message: error.message,
        cause: error,
      );
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

class GoogleDriveHttpClient implements GoogleDriveClient {
  GoogleDriveHttpClient({required http.Client httpClient})
    : _httpClient = httpClient;

  final http.Client _httpClient;

  static final Uri _multipartUploadUri = Uri.parse(
    'https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart&fields=id,createdTime,appProperties,name',
  );

  @override
  Future<GoogleDriveUploadResult> uploadArchive({
    required String accessToken,
    required String archivePath,
    required String backupId,
  }) async {
    final archiveFile = File(archivePath);
    final fileBytes = await archiveFile.readAsBytes();
    final metadata = <String, dynamic>{
      'name': '$backupId.zip',
      'parents': <String>['appDataFolder'],
      'appProperties': <String, String>{
        'mnemata_backup': 'true',
        'backupId': backupId,
      },
    };

    final boundary =
        'mnemata-boundary-${DateTime.now().microsecondsSinceEpoch}';
    final body = <int>[
      ...utf8.encode('--$boundary\r\n'),
      ...utf8.encode('Content-Type: application/json; charset=UTF-8\r\n\r\n'),
      ...utf8.encode(jsonEncode(metadata)),
      ...utf8.encode('\r\n--$boundary\r\n'),
      ...utf8.encode('Content-Type: application/zip\r\n\r\n'),
      ...fileBytes,
      ...utf8.encode('\r\n--$boundary--\r\n'),
    ];

    final response = await _httpClient.post(
      _multipartUploadUri,
      headers: <String, String>{
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'multipart/related; boundary=$boundary',
      },
      body: body,
    );

    _throwIfFailed(response);
    final payload = _decodeJson(response.body);
    final remoteId = payload['id'] as String?;
    if (remoteId == null || remoteId.isEmpty) {
      throw const GoogleDriveProviderFailure(
        type: GoogleDriveProviderFailureType.invalidPayload,
        message: 'Google Drive upload response did not include file id.',
      );
    }

    final createdAtRaw = payload['createdTime'] as String?;
    final uploadedAt =
        DateTime.tryParse(createdAtRaw ?? '')?.toUtc() ??
        DateTime.now().toUtc();
    return GoogleDriveUploadResult(
      backupId: _resolveBackupId(payload, fallback: backupId),
      remoteId: remoteId,
      uploadedAt: uploadedAt,
    );
  }

  @override
  Future<List<GoogleDriveBackupRecord>> listArchives({
    required String accessToken,
  }) async {
    final query =
        "trashed=false and 'appDataFolder' in parents and appProperties has { key='mnemata_backup' and value='true' }";
    final uri =
        Uri.https('www.googleapis.com', '/drive/v3/files', <String, String>{
          'spaces': 'appDataFolder',
          'q': query,
          'fields': 'files(id,name,createdTime,size,appProperties)',
          'orderBy': 'createdTime desc',
          'pageSize': '100',
        });

    final response = await _httpClient.get(
      uri,
      headers: <String, String>{'Authorization': 'Bearer $accessToken'},
    );

    _throwIfFailed(response);
    final payload = _decodeJson(response.body);
    final files = payload['files'];
    if (files is! List<dynamic>) {
      throw const GoogleDriveProviderFailure(
        type: GoogleDriveProviderFailureType.invalidPayload,
        message: 'Google Drive list response did not include files.',
      );
    }

    final records = <GoogleDriveBackupRecord>[];
    for (final item in files) {
      if (item is! Map<String, dynamic>) {
        continue;
      }
      final remoteId = item['id'] as String?;
      if (remoteId == null || remoteId.isEmpty) {
        continue;
      }

      final createdAt =
          DateTime.tryParse(item['createdTime'] as String? ?? '')?.toUtc() ??
          DateTime.now().toUtc();
      records.add(
        GoogleDriveBackupRecord(
          backupId: _resolveBackupId(item, fallback: remoteId),
          remoteId: remoteId,
          createdAt: createdAt,
          sizeBytes: _tryParseSizeBytes(item['size']),
        ),
      );
    }

    return records;
  }

  @override
  Future<GoogleDriveDownloadResult> downloadArchive({
    required String accessToken,
    required String remoteId,
    required String backupId,
  }) async {
    final uri = Uri.https(
      'www.googleapis.com',
      '/drive/v3/files/$remoteId',
      <String, String>{'alt': 'media'},
    );
    final response = await _httpClient.get(
      uri,
      headers: <String, String>{'Authorization': 'Bearer $accessToken'},
    );

    _throwIfFailed(response);
    if (response.bodyBytes.isEmpty) {
      throw const GoogleDriveProviderFailure(
        type: GoogleDriveProviderFailureType.invalidPayload,
        message: 'Google Drive download response was empty.',
      );
    }

    return GoogleDriveDownloadResult(
      backupId: backupId,
      bytes: response.bodyBytes,
    );
  }

  @override
  Future<void> deleteArchive({
    required String accessToken,
    required String remoteId,
  }) async {
    final uri = Uri.https('www.googleapis.com', '/drive/v3/files/$remoteId');
    final response = await _httpClient.delete(
      uri,
      headers: <String, String>{'Authorization': 'Bearer $accessToken'},
    );

    _throwIfFailed(response);
  }

  Map<String, dynamic> _decodeJson(String rawBody) {
    final parsed = jsonDecode(rawBody);
    if (parsed is! Map<String, dynamic>) {
      throw const GoogleDriveProviderFailure(
        type: GoogleDriveProviderFailureType.invalidPayload,
        message: 'Google Drive response body was not a JSON object.',
      );
    }

    return parsed;
  }

  String _resolveBackupId(
    Map<String, dynamic> payload, {
    required String fallback,
  }) {
    final appProperties = payload['appProperties'];
    if (appProperties is Map<String, dynamic>) {
      final fromMetadata = appProperties['backupId'] as String?;
      if (fromMetadata != null && fromMetadata.trim().isNotEmpty) {
        return fromMetadata.trim();
      }
    }

    final name = payload['name'] as String?;
    if (name != null && name.trim().isNotEmpty) {
      return p.basenameWithoutExtension(name.trim());
    }

    return fallback;
  }

  int? _tryParseSizeBytes(Object? rawSize) {
    if (rawSize is int && rawSize >= 0) {
      return rawSize;
    }

    if (rawSize is String) {
      return int.tryParse(rawSize);
    }

    return null;
  }

  void _throwIfFailed(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    throw _mapStatusToFailure(response.statusCode);
  }

  GoogleDriveProviderFailure _mapStatusToFailure(int statusCode) {
    if (statusCode == 401) {
      return const GoogleDriveProviderFailure(
        type: GoogleDriveProviderFailureType.auth,
        message: 'Google Drive authentication failed.',
      );
    }
    if (statusCode == 403) {
      return const GoogleDriveProviderFailure(
        type: GoogleDriveProviderFailureType.permissionDenied,
        message:
            'Google Drive permissions are not sufficient for backup access.',
      );
    }
    if (statusCode == 404) {
      return const GoogleDriveProviderFailure(
        type: GoogleDriveProviderFailureType.notFound,
        message: 'Google Drive backup item was not found.',
      );
    }
    if (statusCode == 429) {
      return const GoogleDriveProviderFailure(
        type: GoogleDriveProviderFailureType.rateLimited,
        message: 'Google Drive request was rate limited.',
      );
    }
    if (statusCode >= 500) {
      return const GoogleDriveProviderFailure(
        type: GoogleDriveProviderFailureType.network,
        message: 'Google Drive service is unavailable.',
      );
    }

    return GoogleDriveProviderFailure(
      type: GoogleDriveProviderFailureType.unknown,
      message: 'Google Drive request failed with status $statusCode.',
    );
  }
}
