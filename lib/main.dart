import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mnemata/core/database/app_database.dart';
import 'package:mnemata/features/backup/services/backup_archive_service.dart';
import 'package:mnemata/features/backup/services/backup_scheduler_service.dart';
import 'package:mnemata/features/backup/services/backup_storage_service.dart';
import 'package:mnemata/features/backup/services/cloud_backup_provider.dart';
import 'package:mnemata/features/backup/services/google_drive_auth_client.dart';
import 'package:mnemata/features/backup/services/google_drive_backup_provider.dart';
import 'package:mnemata/features/backup/services/network_power_signal_service.dart';
import 'package:mnemata/features/ingestion/services/share_service.dart';
import 'package:mnemata/features/ingestion/services/extraction_service.dart';
import 'package:mnemata/features/ingestion/services/pdf_extraction_service.dart';
import 'package:mnemata/features/chronological_list/services/recycle_purge_service.dart';
import 'package:mnemata/features/intelligence/services/ai_provider_client.dart';
import 'package:mnemata/features/intelligence/services/annotation_service.dart';
import 'package:mnemata/features/intelligence/services/api_key_store.dart';
import 'package:mnemata/features/intelligence/services/semantic_indexer_service.dart';
import 'package:mnemata/features/intelligence/services/semantic_search_service.dart';
import 'package:mnemata/features/intelligence/services/summary_service.dart';
import 'package:mnemata/features/intelligence/services/tag_suggestion_service.dart';
import 'package:mnemata/features/settings/services/settings_service.dart';
import 'package:mnemata/features/chronological_list/presentation/item_list_screen.dart';
import 'package:mnemata/core/theme/app_theme.dart';

final getIt = GetIt.instance;
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> setupLocator() async {
  const googleOauthClientId = String.fromEnvironment('GOOGLE_OAUTH_CLIENT_ID');
  const googleOauthServerClientId = String.fromEnvironment(
    'GOOGLE_OAUTH_SERVER_CLIENT_ID',
  );

  getIt.registerSingleton<GlobalKey<NavigatorState>>(navigatorKey);
  getIt.registerSingleton<AppDatabase>(AppDatabase());
  getIt.registerLazySingleton<ExtractionService>(() => ExtractionService());
  getIt.registerLazySingleton<PdfExtractionService>(
    () => PdfExtractionService(),
  );

  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SettingsService>(SettingsService(prefs));
  getIt.registerLazySingleton<ApiKeyStore>(ApiKeyStore.new);
  getIt.registerLazySingleton<AIProviderClient>(AIProviderClient.new);
  getIt.registerLazySingleton<SummaryService>(
    () => SummaryService(
      database: getIt<AppDatabase>(),
      apiKeyStore: getIt<ApiKeyStore>(),
      providerClient: getIt<AIProviderClient>(),
      settingsService: getIt<SettingsService>(),
    ),
  );
  getIt.registerLazySingleton<TagSuggestionService>(
    () => TagSuggestionService(
      database: getIt<AppDatabase>(),
      apiKeyStore: getIt<ApiKeyStore>(),
      providerClient: getIt<AIProviderClient>(),
      settingsService: getIt<SettingsService>(),
    ),
  );
  getIt.registerLazySingleton<SemanticIndexerService>(
    () => SemanticIndexerService(
      database: getIt<AppDatabase>(),
      apiKeyStore: getIt<ApiKeyStore>(),
      settingsService: getIt<SettingsService>(),
      embeddingGenerator: (_) async => const <double>[0.01, 0.02, 0.03],
    ),
  );
  getIt.registerLazySingleton<SemanticSearchService>(
    () => SemanticSearchService(
      database: getIt<AppDatabase>(),
      apiKeyStore: getIt<ApiKeyStore>(),
      settingsService: getIt<SettingsService>(),
    ),
  );
  getIt.registerLazySingleton<AnnotationService>(
    () => AnnotationService(database: getIt<AppDatabase>()),
  );

  getIt.registerLazySingleton<BackupStorageService>(BackupStorageService.new);
  getIt.registerLazySingleton<BackupArchiveService>(
    () => BackupArchiveService(
      storageService: getIt<BackupStorageService>(),
      database: getIt<AppDatabase>(),
      settingsService: getIt<SettingsService>(),
    ),
  );
  getIt.registerLazySingleton<GoogleDriveAuthClient>(
    () => GoogleDriveAuthClient(
      googleClientId: googleOauthClientId.isEmpty ? null : googleOauthClientId,
      serverClientId: googleOauthServerClientId.isEmpty
          ? null
          : googleOauthServerClientId,
    ),
  );
  getIt.registerLazySingleton<CloudBackupProvider>(
    () => GoogleDriveBackupProvider(
      authClient: getIt<GoogleDriveAuthClient>(),
      client: GoogleDriveHttpClient(httpClient: http.Client()),
    ),
  );
  getIt.registerLazySingleton<NetworkPowerSignalService>(
    NetworkPowerSignalService.new,
  );
  getIt.registerLazySingleton<BackupSchedulerService>(
    () => BackupSchedulerService(
      settingsService: getIt<SettingsService>(),
      cloudBackupProvider: getIt<CloudBackupProvider>(),
      createBackupArchive: () =>
          getIt<BackupArchiveService>().createBackupArchive(),
      networkPowerSignalService: getIt<NetworkPowerSignalService>(),
    ),
  );
  getIt.registerLazySingleton<RecyclePurgeService>(
    () => RecyclePurgeService(
      database: getIt<AppDatabase>(),
      settingsService: getIt<SettingsService>(),
    ),
  );

  getIt.registerSingleton<ShareService>(
    ShareService(
      getIt<AppDatabase>(),
      getIt<ExtractionService>(),
      getIt<PdfExtractionService>(),
      getIt<GlobalKey<NavigatorState>>(),
    ),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupLocator();

  // Start share listeners as early as possible to avoid missing first-share intents.
  getIt<ShareService>().init();
  unawaited(getIt<BackupSchedulerService>().runIfDue());
  unawaited(
    getIt<RecyclePurgeService>().purgeExpired().catchError((error, stackTrace) {
      debugPrint('recycle_purge.startup_failed error=$error');
    }),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mnemata',
      navigatorKey: navigatorKey,
      theme: MnemataTheme.light,
      darkTheme: MnemataTheme.dark,
      themeMode: ThemeMode.system,
      home: const ItemListScreen(),
    );
  }
}
