import 'dart:convert';
import 'package:cthree/core/api/dio_client.dart';
import 'package:cthree/core/models/conversation_model.dart';
import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

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
      print("Error fetching conversations: $e");
      return null;
    }
  }

  Future<List<Message>?> getConversationMessages(String conversationId) async {
    try {
      final response = await _dio.get('/conversations/$conversationId');

      if (response.statusCode == 200) {
        List<Map<String, dynamic>> messageData = (response.data['messages'] as List)
            .map((item) => item as Map<String, dynamic>)
            .toList();
        
        List<Message> messages = [];
        
        for (Map<String, dynamic> d in messageData) {
          messages.add(Message.fromJson(d));
        }
        
        return messages;
      }
      return null;
    } catch (e) {
      print("Error fetching conversation messages: $e");
      return null;
    }
  }

  void sendMessageViaSocket(WebSocketChannel channel, String conversationId, String text) {
    try {
      final identifier = jsonEncode({
        "channel": "ChatChannel",
        "id": conversationId
      });

      final data = jsonEncode({
        "action": "send_message",
        "body": text
      });

      final payload = jsonEncode({
        "command": "message",
        "identifier": identifier,
        "data": data
      });

      channel.sink.add(payload);
    } catch (e) {
      print("Error sending message via socket: $e");
    }
  }
}