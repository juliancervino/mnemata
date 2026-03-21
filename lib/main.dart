import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mnemata/core/database/app_database.dart';
import 'package:mnemata/features/ingestion/services/share_service.dart';
import 'package:mnemata/features/ingestion/services/extraction_service.dart';
import 'package:mnemata/features/chronological_list/presentation/item_list_screen.dart';

final getIt = GetIt.instance;

void setupLocator() {
  getIt.registerSingleton<AppDatabase>(AppDatabase());
  getIt.registerLazySingleton<ExtractionService>(() => ExtractionService());
  getIt.registerSingleton<ShareService>(ShareService(getIt<AppDatabase>(), getIt<ExtractionService>()));
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setupLocator();
  
  // Initialize share service
  getIt<ShareService>().init();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mnemata',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ItemListScreen(),
    );
  }
}
