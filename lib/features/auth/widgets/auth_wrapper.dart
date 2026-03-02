import 'package:flutter/material.dart';
import 'package:cthree/features/auth/screens/login_screen.dart';
import 'package:cthree/features/creator_flow/screens/dashboard.dart';
import 'package:cthree/core/api/auth_provider.dart';
import 'package:provider/provider.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override 
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.status == AuthStatus.authenticating || auth.status == AuthStatus.initial) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.secondary),),
      );
    }

    return auth.isAuthenticated ? const ContentPlannerScreen() : const LoginScreen();
  }
}