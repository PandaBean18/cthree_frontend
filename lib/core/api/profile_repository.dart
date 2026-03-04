import 'package:dio/dio.dart';
import 'package:cthree/core/models/profile_model.dart';
import 'package:cthree/core/api/dio_client.dart';

class ProfileRepository {
  final Dio _dio = DioClient().dio;

  Future<ProfileModel?> getMe() async {
    try {
      final response = await _dio.get(
        '/users/me'
      );

      if (response.statusCode == 200) {
        final data = response.data;

        return ProfileModel.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}