import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'constants/colors.dart';

void main() {
  runApp(const TenantScoreApp());
}

class TenantScoreApp extends StatelessWidget {
  const TenantScoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tenant Score App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: kPrimaryColor,
        scaffoldBackgroundColor: kBackgroundColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: kPrimaryColor,
          foregroundColor: Colors.white,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
