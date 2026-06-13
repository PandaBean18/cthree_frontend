class Message {
  String id;
  String body;
  DateTime createdAt;
  DateTime? readAt;
  String senderId;
  String sender;

  Message({
    required this.id, 
    required this.body, 
    required this.createdAt, 
    this.readAt, 
    required this.senderId, 
    required this.sender
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? '', 
      body: json['body'], 
      createdAt: DateTime.parse(json['created_at']).add(const Duration(hours: 5, minutes: 30)), 
      senderId: json['sender_id'], 
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null, 
      sender: json['sender_label'],
    );
  }
}

class ConversationModel {
  String id;
  String campaignId;
  String creatorId;
  String sponsorId;
  String campaignTitle;
  Message? latestMessage;

  ConversationModel({ 
    required this.id, 
    required this.campaignId, 
    required this.creatorId, 
    required this.sponsorId, 
    required this.campaignTitle, 
    this.latestMessage 
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'],
      campaignId: json['campaign']['id'],
      creatorId: json['creator_id'],
      sponsorId: json['sponsor_id'],
      campaignTitle: json['campaign']['title'],
      latestMessage: json['latest_message'] == null ? null : Message.fromJson(json['latest_message'])
    );
  }
}