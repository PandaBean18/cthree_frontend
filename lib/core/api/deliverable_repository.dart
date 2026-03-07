import 'package:dio/dio.dart';
import 'package:cthree/core/models/deliverable_model.dart';
import 'package:cthree/core/api/dio_client.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'package:mime/mime.dart';

class DeliverableRepository {
  final Dio _dio = DioClient().dio;
  final Dio _cloudinaryDio = Dio();

  Future<DeliverableModel?> getDeliverables() async {
    try { 
      final response = await _dio.get(
        '/users/deliverables'
      );

      if (response.statusCode == 200) {
        return DeliverableModel.fromJson(response.data);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Stream<double> submitProof(XFile mediaFile, String deliverableId) {
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
            controller.add(progress * 0.8);
          }
        );

        if (cloudinaryResponse.statusCode == 200) {
          final cData = cloudinaryResponse.data;
          final confirmUploadResponse = await _dio.post('/media/confirm_upload', data: {
            "public_id": cData['public_id'],
            "resource_type": mediaType,
            "label": 'deliverable_proof',
            "metadata": {
              "width": cData['width'],
              "height": cData['height'],
              "format": cData['format'],
            }
          });

          controller.add(0.9);

          await _dio.patch(
            "/deliverables/$deliverableId/submit",
            data: {
              "submission_proof_url": confirmUploadResponse.data['url']
            }
          );

          controller.add(1.0);
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