class Campaign {
  String id;
  String title;
  String brief;

  Campaign({required this.id, required this.title, required this.brief});

  factory Campaign.fromJson(Map<String, dynamic> json) {
    return Campaign(id: json['id'], title: json['title'], brief: json['brief']);
  }
}

class CampaignParticipant {
  Campaign campaign;

  CampaignParticipant({required this.campaign});

  factory CampaignParticipant.fromJson(Map<String, dynamic> json) {
    return CampaignParticipant(campaign: Campaign.fromJson(json['campaign']));
  }
}

class DeliverableModel {
  String id;
  CampaignParticipant campaignParticipant;
  DateTime createdAt;
  String deliverableType;
  String? feedback;
  String status;
  String? submissionProofUrl;
  DateTime dueDate;
  String? brief;

  DeliverableModel({
    required this.id,
    required this.campaignParticipant, 
    required this.createdAt, 
    required this.deliverableType, 
    this.feedback, 
    required this.status, 
    this.submissionProofUrl,
    required this.dueDate,
    this.brief
  });

  factory DeliverableModel.fromJson(Map<String, dynamic> json) {
    return DeliverableModel(
      id: json['id'],
      campaignParticipant: CampaignParticipant.fromJson(json['campaign_participant']), 
      createdAt: DateTime.parse(json['created_at']), 
      deliverableType: json['deliverable_type'], 
      status: json['status'],
      feedback: json['feedback'],
      submissionProofUrl: json['submission_proof_url'],
      dueDate: DateTime.parse(json['due_date']),
    );
  }
}