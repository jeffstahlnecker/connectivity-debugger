import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/dashboard_screen.dart';
import 'services/log_storage_service.dart';

class MyApp extends StatelessWidget {
  final LogStorageService? logStorageService;

  const MyApp({super.key, this.logStorageService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Connectivity Debugger',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: DashboardScreen(logStorageService: logStorageService),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  runApp(const MyApp());
}
