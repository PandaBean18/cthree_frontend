import 'package:cthree/core/api/dio_client.dart';
import 'package:cthree/core/models/conversation_model.dart';
import 'package:dio/dio.dart';

class ConversationRepository {
  final Dio _dio = DioClient().dio;

  Future<List<ConversationModel>?> getConversations() async {
    try {
      final response = await _dio.get('/conversations');

      if (response.statusCode == 200) {
         List<Map<String, dynamic>> data = (response.data as List)
                                          .map((item) => item as Map<String, dynamic>)
                                          .toList();

        List<ConversationModel> a = [];

        for (Map<String, dynamic> d in data) {
          ConversationModel v = ConversationModel.fromJson(d);
          a.add(v);
        }

        return a; 
      } 
      return null;
    } catch (e) {
      return null;
    }
  }
}