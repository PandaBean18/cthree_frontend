import 'package:dio/dio.dart';
import 'package:cthree/core/models/profile_model.dart';
import 'package:cthree/core/api/dio_client.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'package:mime/mime.dart';
import 'package:cthree/data/dto/create_portfolio_item_request.dart';
import 'package:cthree/core/models/portfolio_item_model.dart';

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

  Future<Map<String, dynamic>?> parseLink(String url) async {
    try {
      final response = await _dio.post(
        '/media/parse_link',
        data: {
          'url': url,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print("Error in parseLink: $e");
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
            controller.add(progress * 0.9);
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

  Stream<double> uploadSampleWork(XFile mediaFile) {
    final controller = StreamController<double>();

    Future<void> startUpload() async {
      String? mediaType;
      String? mime = lookupMimeType(mediaFile.path);

      if (mime != null) {
        if (mime.startsWith('image/')) mediaType = 'image';
        if (mime.startsWith('video/')) mediaType = 'video';
      }

      mediaType ??= 'image';

      try {
        controller.add(0.0);
        final sigResponse = await _dio.get('/media/signature');
        final sigData = sigResponse.data;
        final formData = FormData.fromMap({
          "file": await MultipartFile.fromFile(mediaFile.path),
          "api_key": sigData['api_key'],
          "timestamp": sigData['timestamp'],
          "signature": sigData['signature'],
          "folder": sigData['folder'],
          "tags": sigData['tags'],
          "source": "uw",
        });

        final cloudinaryResponse = await _cloudinaryDio.post(
          "https://api.cloudinary.com/v1_1/${sigData['cloud_name']}/${mediaType}/upload",
          data: formData,
          onSendProgress: (sent, total) {
            double progress = sent / total;
            controller.add(progress * 0.9);
          }
        );

        if (cloudinaryResponse.statusCode == 200) {
          final cData = cloudinaryResponse.data;
          await _dio.post('/media/confirm_upload', data: {
            "public_id": cData['public_id'],
            "resource_type": mediaType,
            "label": 'portfolio',
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

  Future<PortfolioItem?> createPortfolioItem(CreatePortfolioItemRequest request) async {
    try {
      final response = await _dio.post(
        '/portfolio_items',
        data: request.toJson(),
      );

      if (response.statusCode == 201 && response.data != null) {
        return PortfolioItem.fromJson(response.data);
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        final errorData = e.response?.data;
        if (errorData != null && errorData['errors'] != null) {
          final errors = List<String>.from(errorData['errors']);
          throw Exception(errors.join(', '));
        }
        throw Exception('Validation failed');
      }
      print("DioError in createPortfolioItem: ${e.message}");
      rethrow;
    } catch (e) {
      print("Error in createPortfolioItem: $e");
      rethrow;
    }
  }
}