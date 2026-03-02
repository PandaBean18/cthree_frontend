import 'package:dio/dio.dart';
import 'package:cthree/core/storage/auth_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class AuthInterceptor extends Interceptor {
  final Dio dio;

  AuthInterceptor(this.dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await AuthStorage.getAccessToken();

    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final refreshToken = await AuthStorage.getRefreshToken();
      final jti = await AuthStorage.getJti();

      if (refreshToken != null && jti != null) {
        try {
          final response = await dio.post('/auth/refresh',data: {
            'refresh_token': refreshToken,
            'access_token_identifier': jti,
          });

          if (response.statusCode == 200) {
            final newAccessToken = response.data['access_token'];
            final newRefreshToken = response.data['refresh_token'];
            final newJti = JwtDecoder.decode(newAccessToken)['jti'];

            await AuthStorage.saveTokens(accessToken: newAccessToken, refreshToken: newRefreshToken, jti: newJti);

            err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
            final clonedRequest = await dio.fetch(err.requestOptions);
            
            return handler.resolve(clonedRequest);
          }
        } catch (refreshErr) {
          await AuthStorage.deleteAll();
        }
      }
    }

    return handler.next(err);
  }
}