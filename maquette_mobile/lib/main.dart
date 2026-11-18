import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MonDoApp());
}

class MonDoApp extends StatelessWidget {
  const MonDoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MonDo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const WelcomeScreen(),
    );
  }
}