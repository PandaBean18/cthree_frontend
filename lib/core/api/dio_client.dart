import 'package:dio/dio.dart';
import 'package:cthree/core/api/auth_interceptor.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  late final Dio dio;

  factory DioClient() => _instance;

  DioClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: 'http://127.0.0.1:3000',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        }
      )
    );
    dio.interceptors.add(AuthInterceptor(dio));

    // remove in prod
    dio.interceptors.add(LogInterceptor(responseBody: true, requestBody: true));
  }
}