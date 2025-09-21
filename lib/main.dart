import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/home_screen.dart'; // <-- Импортируем HomeScreen

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TukaApp());
}

class TukaApp extends StatelessWidget {
  const TukaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme(),
      home: const HomeScreen(), // <-- Главный экран теперь HomeScreen
    );
  }
}
