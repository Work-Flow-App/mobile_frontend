import 'package:flutter/material.dart';
import 'package:mobile_frontend/app.dart';
import 'package:mobile_frontend/core/theme/app_theme.dart'; // Import the AppTheme

void main() {
  runApp(const WorkfloowApp());
}

/* class WorkfloowApp extends StatefulWidget {
  const WorkfloowApp({super.key});

  @override
  _WorkfloowAppState createState() => _WorkfloowAppState();
}

class _WorkfloowAppState extends State<WorkfloowApp> {
  // Initial theme mode (system setting by default)
  ThemeMode _themeMode = ThemeMode.system;

  // Toggle theme function
  void _toggleTheme() {
    setState(() {
      if (_themeMode == ThemeMode.light) {
        _themeMode = ThemeMode.dark;
      } else {
        _themeMode = ThemeMode.light;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Workfloow',
      theme: AppTheme.lightTheme, // Light theme
      darkTheme: AppTheme.darkTheme, // Dark theme
      themeMode: _themeMode, // Dynamic theme mode based on button toggle
      home: HomeScreen(
        onToggleTheme: _toggleTheme,
      ), // Pass the toggle function to HomeScreen
    );
  }
}

// HomeScreen to see theme effects
class HomeScreen extends StatelessWidget {
  final VoidCallback onToggleTheme; // Callback for toggling theme

  const HomeScreen({
    super.key,
    required this.onToggleTheme,
  }); // Constructor to accept the callback

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Workfloow App")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Welcome to Workfloow!",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Sample Button'),
            ),
            const SizedBox(height: 20),
            Text(
              "Current Theme: ${Theme.of(context).brightness == Brightness.light ? 'Light' : 'Dark'}",
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 20),
            // Button to toggle theme
            ElevatedButton(
              onPressed:
                  onToggleTheme, // Call the passed function to toggle theme
              child: const Text('Toggle Theme'),
            ),
          ],
        ),
      ),
    );
  }
}

// AppTheme.dart file for defining light and dark themes

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.white,
    primaryColor: AppColors.black,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.white,
      foregroundColor: AppColors.black,
      elevation: 0,
    ),
    textTheme: const TextTheme(bodyMedium: TextStyle(color: AppColors.black)),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.black,
    primaryColor: AppColors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.black,
      foregroundColor: AppColors.white,
      elevation: 0,
    ),
    textTheme: const TextTheme(bodyMedium: TextStyle(color: AppColors.white)),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.black,
      ),
    ),
  );
}

// AppColors.dart for defining color constants

class AppColors {
  static const black = Color(0xFF000000);
  static const white = Color(0xFFFFFFFF);
  static const grey = Color(0xFF9E9E9E);
  static const green = Color(0xFF2E7D32);
} */
