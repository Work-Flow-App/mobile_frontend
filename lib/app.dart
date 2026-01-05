import 'package:flutter/material.dart';
import 'package:mobile_frontend/core/features/auth/login_screen.dart';
import 'package:mobile_frontend/core/theme/app_theme.dart';
import 'package:mobile_frontend/state/auth_provider.dart';
import 'package:provider/provider.dart';

class WorkfloowApp extends StatelessWidget {
  const WorkfloowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Workfloow',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: LoginScreen(),
      ),
    );
  }
}
