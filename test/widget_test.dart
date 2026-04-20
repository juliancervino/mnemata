import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mnemata/main.dart';
import 'package:mnemata/core/database/app_database.dart';
import 'package:mnemata/features/intelligence/services/api_key_store.dart';
import 'package:mnemata/features/settings/services/settings_service.dart';
import 'package:mnemata/features/ingestion/services/share_service.dart';
import 'package:mnemata/features/ingestion/services/extraction_service.dart';
import 'package:mnemata/features/ingestion/services/pdf_extraction_service.dart';
import 'package:mnemata/features/backup/services/backup_scheduler_service.dart';
import 'package:mnemata/features/chronological_list/services/recycle_purge_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'helpers/test_database_factory.dart';

class MockApiKeyStore extends Mock implements ApiKeyStore {}

class MockSettingsService extends Mock implements SettingsService {}

class MockShareService extends Mock implements ShareService {}

class MockExtractionService extends Mock implements ExtractionService {}

class MockPdfExtractionService extends Mock implements PdfExtractionService {}

class MockBackupSchedulerService extends Mock
    implements BackupSchedulerService {}

class MockRecyclePurgeService extends Mock implements RecyclePurgeService {}

void main() {
  setUp(() async {
    await GetIt.instance.reset();
    SharedPreferences.setMockInitialValues({});

    final mockApiKeyStore = MockApiKeyStore();
    final mockSettingsService = MockSettingsService();
    final mockShareService = MockShareService();
    final mockScheduler = MockBackupSchedulerService();
    final mockRecyclePurge = MockRecyclePurgeService();

    when(() => mockSettingsService.autoTagDomain).thenReturn(true);
    when(() => mockSettingsService.autoTagYear).thenReturn(true);
    when(() => mockSettingsService.aiSummaryEnabled).thenReturn(false);
    when(() => mockSettingsService.semanticSearchEnabled).thenReturn(false);
    when(() => mockSettingsService.aiTagSuggestionsEnabled).thenReturn(false);
    when(() => mockSettingsService.aiProvider).thenReturn('gemini');
    when(
      () => mockApiKeyStore.hasKeyForProvider(any()),
    ).thenAnswer((_) async => false);
    when(() => mockShareService.init()).thenReturn(null);
    when(
      () => mockScheduler.runIfDue(),
    ).thenAnswer((_) async => const BackupSchedulerResult(executed: false));
    when(() => mockRecyclePurge.purgeExpired()).thenAnswer((_) async => 0);

    GetIt.instance.registerSingleton<AppDatabase>(createTestDatabase());
    GetIt.instance.registerSingleton<ApiKeyStore>(mockApiKeyStore);
    GetIt.instance.registerSingleton<SettingsService>(mockSettingsService);
    GetIt.instance.registerSingleton<ShareService>(mockShareService);
    GetIt.instance.registerSingleton<BackupSchedulerService>(mockScheduler);
    GetIt.instance.registerSingleton<RecyclePurgeService>(mockRecyclePurge);
    GetIt.instance.registerSingleton<ExtractionService>(
      MockExtractionService(),
    );
    GetIt.instance.registerSingleton<PdfExtractionService>(
      MockPdfExtractionService(),
    );
    GetIt.instance.registerSingleton<GlobalKey<NavigatorState>>(
      GlobalKey<NavigatorState>(),
    );
  });

  testWidgets('Mnemata app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // We need to call setupLocator or manually register what MyApp needs.
    // main.dart has setupLocator() but it registers real database.
    // Let's just mock the essentials.

    await tester.pumpWidget(const MyApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Smoke gate: the app shell builds and mounts without throwing.
    expect(find.byType(MaterialApp), findsOneWidget);

    // Clear any pending timers
    await tester.pumpWidget(Container());
    await tester.pump(const Duration(milliseconds: 300));
  });
}
