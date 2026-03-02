import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:cthree/core/storage/auth_storage.dart';
import 'package:cthree/features/auth/screens/login_screen.dart';
import 'package:cthree/features/creator_flow/screens/dashboard.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override 
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _checkAuthStatus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.secondary,))
          );
        } 

        if (snapshot.data == true) {
          return const ContentPlannerScreen();
        } else {
          return const LoginScreen();
        }
      }
    );
  }

  Future<bool> _checkAuthStatus() async {
    final accessToken = await AuthStorage.getAccessToken();
    final refreshToken = await AuthStorage.getRefreshToken();
    
    if (accessToken == null || refreshToken == null) {
      return false;
    } 

    bool isTokenExpired = JwtDecoder.isExpired(accessToken);

    if (!isTokenExpired) {
      return true;
    }

    return await _tryRefreshToken(refreshToken);
  }

  Future<bool> _tryRefreshToken(refreshToken) async {
    await Future.delayed(Duration(seconds: 5));
    try {
      // todo
      return false;
    } catch (e) {
      return false;
    }
  }
}