import 'package:dio/dio.dart';
import 'package:cthree/core/models/profile_model.dart';
import 'package:cthree/core/api/dio_client.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'package:mime/mime.dart';
import 'package:cthree/data/dto/create_portfolio_item_request.dart';
import 'package:cthree/data/dto/create_platform_request.dart';
import 'package:cthree/core/models/portfolio_item_model.dart';
import 'package:cthree/core/models/creator_platform_model.dart';
import 'package:cthree/core/models/brand_collaboration_model.dart';

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

  Stream<double> uploadSampleWork({
    required XFile mediaFile,
    required String title,
    required String description,
    required bool isCollaborative,
    String? collabBrand,
    String? externalUrl,
  }) {
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
        
        // 1. Get Upload Signature
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

        // 2. Upload to Cloudinary
        final cloudinaryResponse = await _cloudinaryDio.post(
          "https://api.cloudinary.com/v1_1/${sigData['cloud_name']}/$mediaType/upload",
          data: formData,
          onSendProgress: (sent, total) {
            double progress = sent / total;
            // Cap Cloudinary progress at 80% to leave room for Rails API calls
            controller.add(progress * 0.8); 
          }
        );

        if (cloudinaryResponse.statusCode == 200) {
          final cData = cloudinaryResponse.data;
          
          // 3. Confirm Upload with Rails (Registers the asset in your DB)
          final confirmResponse = await _dio.post('/media/confirm_upload', data: {
            "public_id": cData['public_id'],
            "resource_type": mediaType,
            "label": 'portfolio',
            "metadata": {
              "width": cData['width'],
              "height": cData['height'],
              "format": cData['format'],
            }
          });

          // Extract the media item ID returned by Rails
          final mediaItemId = confirmResponse.data['item']['id'];
          
          controller.add(0.9); // Reached 90%

          // 4. Create the final Portfolio Item
          await _dio.post('/portfolio_items', data: {
            "title": title,
            "description": description,
            "is_collaborative": isCollaborative,
            if (isCollaborative && collabBrand != null && collabBrand.isNotEmpty) 
              "collab_brand": collabBrand,
            if (externalUrl != null && externalUrl.isNotEmpty) 
              "external_url": externalUrl,
            "media_item_id": mediaItemId,
          });

          // Complete!
          controller.add(1.0);
          await controller.close();
        } else {
          throw Exception("Cloudinary upload failed");
        }
      } catch (e) {
        controller.addError(e);
        controller.close();
      }
    }

    startUpload();
    return controller.stream;
  }

  Future<Map<String, dynamic>?> uploadThumbnail(XFile imageFile) async {
    try {
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
      );

      if (cloudinaryResponse.statusCode == 200) {
        final cData = cloudinaryResponse.data;
        
        final confirmResponse = await _dio.post('/media/confirm_upload', data: {
          "public_id": cData['public_id'],
          "resource_type": "image",
          "label": 'portfolio_thumbnail',
          "metadata": {
            "width": cData['width'],
            "height": cData['height'],
            "format": cData['format'],
          }
        });

        return {
          'id': confirmResponse.data['item']['id'],
          'url': cData['secure_url'],
        };
      }
      return null;
    } catch (e) {
      print("Error uploading thumbnail: $e");
      return null;
    }
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

  Future<CreatorPlatformModel?> createCreatorPlatform(CreatePlatformRequest request) async {
    try {
      final response = await _dio.post(
        '/creator_platforms',
        data: request.toJson(),
      );
      if (response.statusCode == 201) {
        return CreatorPlatformModel.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print("Error creating platform: $e");
      return null;
    }
  }

  Future<String?> uploadInsight(XFile imageFile) async {
    try {
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
      );

      if (cloudinaryResponse.statusCode == 200) {
        final cData = cloudinaryResponse.data;
        
        final confirmResponse = await _dio.post('/media/confirm_upload', data: {
          "public_id": cData['public_id'],
          "resource_type": "image",
          "label": 'platform_insight',
          "metadata": {
            "width": cData['width'],
            "height": cData['height'],
            "format": cData['format'],
          }
        });

        return confirmResponse.data['item']['id'];
      }
      return null;
    } catch (e) {
      print("Error uploading insight: $e");
      return null;
    }
  }

  Future<BrandCollaborationModel?> addBrandCollaboration({
    required String companyName,
    String? companyUrl,
    String? logoUrl,
    String? description,
    String? postUrl,
  }) async {
    try {
      final response = await _dio.post(
        '/users/me/brand_collaborations',
        data: {
          'company_name': companyName,
          'company_url': companyUrl,
          'logo_url': logoUrl,
          'description': description,
          'post_url': postUrl,
        },
      );
      if (response.statusCode == 201) {
        return BrandCollaborationModel.fromJson(response.data['brand_collaboration']);
      }
      return null;
    } catch (e) {
      print("Error adding brand collaboration: $e");
      return null;
    }
  }

  Future<bool> deleteBrandCollaboration(String id) async {
    try {
      final response = await _dio.delete('/users/me/brand_collaborations/$id');
      return response.statusCode == 200;
    } catch (e) {
      print("Error deleting brand collaboration: $e");
      return false;
    }
  }
}