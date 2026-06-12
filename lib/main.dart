import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'services/settings_service.dart';
import 'services/workmanager_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize WorkManager for background tasks
  await Workmanager().initialize(
    workmanagerCallbackDispatcher,
    isInDebugMode: false,
  );

  final settings = await SettingsService.create();

  runApp(SimpleSentenceApp(settings: settings));
}

class SimpleSentenceApp extends StatelessWidget {
  final SettingsService settings;

  const SimpleSentenceApp({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple Sentence',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A90D9),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A90D9),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
        ),
      ),
      themeMode: ThemeMode.system,
      home: HomeScreen(settings: settings),
    );
  }
}
