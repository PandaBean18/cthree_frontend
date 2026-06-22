import 'package:dio/dio.dart';
import 'package:cthree/core/api/dio_client.dart';
import 'package:cthree/core/models/idea_model.dart';
import 'package:image_picker/image_picker.dart';

class IdeaRepository {
  final Dio _dio = DioClient().dio;
  final Dio _cloudinaryDio = Dio();

  Future<List<IdeaModel>?> getIdeas() async {
    try {
      final response = await _dio.get('/ideas');
      if (response.statusCode == 200) {
        List<Map<String, dynamic>> data = (response.data as List)
            .map((item) => item as Map<String, dynamic>)
            .toList();
        return data.map((d) => IdeaModel.fromJson(d)).toList();
      }
      return null;
    } catch (e) {
      print("Error fetching ideas: $e");
      return null;
    }
  }

  Future<IdeaModel?> getIdea(String id) async {
    try {
      final response = await _dio.get('/ideas/$id');
      if (response.statusCode == 200) {
        return IdeaModel.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print("Error fetching idea $id: $e");
      return null;
    }
  }

  Future<IdeaModel?> createIdea({
    required String title,
    required Map<String, dynamic> description,
    required List<Map<String, dynamic>> inspos,
  }) async {
    try {
      final response = await _dio.post('/ideas', data: {
        'title': title,
        'description': description,
        'inspos': inspos,
      });

      if (response.statusCode == 201) {
        return IdeaModel.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print("Error creating idea: $e");
      return null;
    }
  }

  Future<IdeaModel?> updateIdea(String id, String title, Map<String, dynamic> description) async {
    try {
      final response = await _dio.patch('/ideas/$id', data: {
        'title': title,
        'description': description,
      });

      if (response.statusCode == 200) {
        return IdeaModel.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print("Error updating idea: $e");
      return null;
    }
  }

  Future<bool> deleteIdea(String id) async {
    try {
      final response = await _dio.delete('/ideas/$id');
      return response.statusCode == 204;
    } catch (e) {
      print("Error deleting idea: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>?> generateLinkInspoPayload(String url) async {
    try {
      final response = await _dio.post(
        '/media/parse_link',
        data: {'url': url},
      );

      if (response.statusCode == 200 && response.data != null) {
        final parsed = response.data;
        
        if (url.contains('instagram.com')) {
          return {
            "source_type": "instagram",
            "temporary_thumbnail_url": parsed['temporary_thumbnail_url'] ?? parsed['thumbnail_url']
          };
        } else if (url.contains('youtube.com') || url.contains('youtu.be')) {
          return {
            "source_type": "youtube",
            "external_url": url,
            "external_thumbnail_url": parsed['thumbnail_url']
          };
        } else {
          return {
            "source_type": "generic",
            "external_url": url,
            "external_thumbnail_url": parsed['temporary_thumbnail_url'] ?? parsed['thumbnail_url']
          };
        }
      }
      return null;
    } catch (e) {
      print("Error generating link inspo: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> generateDirectUploadInspoPayload(XFile imageFile) async {
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
          "label": 'inspo',
          "metadata": {
            "width": cData['width'],
            "height": cData['height'],
            "format": cData['format'],
          }
        });

        return {
          "source_type": "direct_upload",
          "thumbnail_item_id": confirmResponse.data['id']
        };
      }
      return null;
    } catch (e) {
      print("Error generating direct upload inspo: $e");
      return null;
    }
  }
}