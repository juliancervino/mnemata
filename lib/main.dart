import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mnemata/core/database/app_database.dart';
import 'package:mnemata/features/ingestion/services/share_service.dart';
import 'package:mnemata/features/ingestion/services/extraction_service.dart';
import 'package:mnemata/features/ingestion/services/pdf_extraction_service.dart';
import 'package:mnemata/features/settings/services/settings_service.dart';
import 'package:mnemata/features/chronological_list/presentation/item_list_screen.dart';

final getIt = GetIt.instance;
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> setupLocator() async {
  getIt.registerSingleton<GlobalKey<NavigatorState>>(navigatorKey);
  getIt.registerSingleton<AppDatabase>(AppDatabase());
  getIt.registerLazySingleton<ExtractionService>(() => ExtractionService());
  getIt.registerLazySingleton<PdfExtractionService>(() => PdfExtractionService());
  
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SettingsService>(SettingsService(prefs));

  getIt.registerSingleton<ShareService>(ShareService(
    getIt<AppDatabase>(),
    getIt<ExtractionService>(),
    getIt<PdfExtractionService>(),
    getIt<GlobalKey<NavigatorState>>(),
  ));
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupLocator();

  // Start share listeners as early as possible to avoid missing first-share intents.
  getIt<ShareService>().init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mnemata',
      navigatorKey: navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const ItemListScreen(),
    );
  }
}
