import 'package:flutter/material.dart';
import 'package:mobile_frontend/core/features/skip/demo_home_screen.dart';
import 'package:mobile_frontend/core/theme/app_theme.dart';

class WorkfloowApp extends StatelessWidget {
  const WorkfloowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Workfloow',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: DemoHomeScreen(),
    );
  }
}
