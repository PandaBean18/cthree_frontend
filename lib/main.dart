import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './core/theme/app_theme.dart';
import 'package:cthree/features/auth/widgets/auth_wrapper.dart';
import 'package:cthree/core/api/auth_provider.dart';
void main() {
  runApp(
    MultiProvider(providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      
    ],
    child: const MyApp()
    )
  );
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