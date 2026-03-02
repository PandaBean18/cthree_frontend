import 'package:flutter/material.dart';
import './core/theme/app_theme.dart';
import 'package:cthree/features/auth/screens/login_screen.dart';
import 'package:cthree/features/creator_flow/screens/dashboard.dart';
import 'package:cthree/features/auth/widgets/auth_wrapper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sponsorship Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme, // Apply our custom theme here
      home: const AuthWrapper(), // Your starting page
    );
  }
}