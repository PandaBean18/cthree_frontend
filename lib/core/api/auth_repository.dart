import 'package:dio/dio.dart';
import 'package:cthree/core/models/user_model.dart';
import 'package:cthree/core/storage/auth_storage.dart';
import 'package:cthree/core/api/dio_client.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class AuthRepository {
  final Dio _dio = DioClient().dio;

  Future<UserModel?> pwdLogin(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login', 
        data: {
          'user': {
            'email': email,
          },
          'password': password,
        }
      );

      if (response.statusCode == 200) {
        final data = response.data;

        final String accessToken = data['access_token'];
        final String refreshToken = data['refresh_token'];
        final String jti = JwtDecoder.decode(accessToken)['jti'];

        await AuthStorage.saveTokens(accessToken: accessToken, refreshToken: refreshToken, jti: jti);

        return UserModel.fromJson(data['user']);
      }

      return null;
    } on DioException catch (e) {
      // remove in prod
      print("Login Error: ${e.response?.data['error'] ?? e.message}");
      return null;
    }
  }

  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String username, 
    required String description
  }) async {
    try {
      final response = await _dio.post(
        '/auth/signup',
        data: {
          'user': {
            'email': email,    
            'username': username,
            'description': description,
            'role': 'creator',
            'timezone': 'Asia/Kolkata'
          },
          'password': password
        }
      );

      if (response.statusCode == 201) {
        final data = response.data;

        final String accessToken = data['access_token'];
        final String refreshToken = data['refresh_token'];
        final String jti = JwtDecoder.decode(accessToken)['jti'];

        await AuthStorage.saveTokens(accessToken: accessToken, refreshToken: refreshToken, jti: jti);

        return UserModel.fromJson(data['user']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<UserModel?> bootstrapAuth() async {
    final refreshToken = await AuthStorage.getRefreshToken();
    final jti = await AuthStorage.getJti();
    if (refreshToken == null) {
      return null;
    }

    try {
      final response = await _dio.post(
        '/auth/refresh',
        data: {
          'refresh_token': refreshToken,
          'access_token_identifier': jti
        }
      );

      if (response.statusCode == 200) {
        final data = response.data;

        final String accessToken = data['access_token'];
        final String refreshToken = data['refresh_token'];
        final String jti = JwtDecoder.decode(accessToken)['jti'];

        await AuthStorage.saveTokens(accessToken: accessToken, refreshToken: refreshToken, jti: jti);

        return UserModel.fromJson(data['user']);
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        await AuthStorage.deleteAll();
      }
      return null;
    } catch (e) {
      return null;
    }

  }
}