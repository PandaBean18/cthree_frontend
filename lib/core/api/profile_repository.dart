import 'package:dio/dio.dart';
import 'package:cthree/core/models/profile_model.dart';
import 'package:cthree/core/api/dio_client.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';

class ProfileRepository {
  final Dio _dio = DioClient().dio;
  final Dio _cloudinaryDio = Dio();

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

  Stream<double> updateProfilePicture(XFile imageFile) {
    final controller = StreamController<double>();

    Future<void> startUpload() async {
      try {
        controller.add(0.0);
        final sigResponse = await _dio.get('/media/signature');
        final sigData = sigResponse.data;
        final formData = FormData.fromMap({
          "file": await MultipartFile.fromFile(imageFile.path),
          "api_key": sigData['api_key'],
          "timestamp": sigData['timestamp'],
          "signature": sigData['signature'],
          "folder": sigData['folder'],
          "tags": sigData['tags'],
          "source": "uw",
        });

        final cloudinaryResponse = await _cloudinaryDio.post(
          "https://api.cloudinary.com/v1_1/${sigData['cloud_name']}/image/upload",
          data: formData,
          onSendProgress: (sent, total) {
            double progress = sent / total;
            controller.add(progress * 0.8);
          }
        );

        if (cloudinaryResponse.statusCode == 200) {
          final cData = cloudinaryResponse.data;
          await _dio.post('/media/confirm_upload', data: {
            "public_id": cData['public_id'],
            "resource_type": "image",
            "label": 'avatar',
            "metadata": {
              "width": cData['width'],
              "height": cData['height'],
              "format": cData['format'],
            }
          });
          controller.add(1);
          await controller.close();
        }
      } catch (e) {
        controller.addError(e);
        controller.close();
      }
    }

    startUpload();
    return controller.stream;
  }
}