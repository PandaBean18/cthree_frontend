import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './core/theme/app_theme.dart';
import 'package:cthree/features/auth/widgets/auth_wrapper.dart';
import 'package:cthree/core/api/auth_provider.dart';
import 'package:cthree/core/api/deliverable_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
void main() {
  runApp(
    MultiProvider(providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider(create: (_) => DeliverableProvider()),
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
      localizationsDelegates: const [
        FlutterQuillLocalizations.delegate, 
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'),
      ],
      home: const AuthWrapper(),
    );
  }
}