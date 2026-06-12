import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'services/settings_service.dart';
import 'services/workmanager_service.dart';
import 'screens/home_screen.dart';
import 'theme/bunny_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize WorkManager for background tasks
  await Workmanager().initialize(
    workmanagerCallbackDispatcher,
    isInDebugMode: false,
  );

  final settings = await SettingsService.create();

  // Schedule periodic rotation check (runs every 6 hours)
  if (settings.isConfigured) {
    await scheduleRotationCheck();
  }

  runApp(SimpleSentenceApp(settings: settings));
}

class SimpleSentenceApp extends StatelessWidget {
  final SettingsService settings;

  const SimpleSentenceApp({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '🐰 Simple Sentence',
      debugShowCheckedModeBanner: false,
      theme: BunnyTheme.lightTheme,
      darkTheme: BunnyTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: HomeScreen(settings: settings),
    );
  }
}
