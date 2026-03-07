class Campaign {
  String id;
  String title;

  Campaign({required this.id, required this.title});

  factory Campaign.fromJson(Map<String, dynamic> json) {
    return Campaign(id: json['id'], title: json['title']);
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
  CampaignParticipant campaignParticipant;
  DateTime createdAt;
  String deliverableType;
  String? feedback;
  String status;
  String? submissionProofUrl;

  DeliverableModel({
    required this.campaignParticipant, 
    required this.createdAt, 
    required this.deliverableType, 
    this.feedback, 
    required this.status, 
    this.submissionProofUrl
  });

  factory DeliverableModel.fromJson(Map<String, dynamic> json) {
    return DeliverableModel(
      campaignParticipant: CampaignParticipant.fromJson(json['campaign_participant']), 
      createdAt: json['created_at'], 
      deliverableType: json['deliverable_type'], 
      status: json['status'],
      feedback: json['feedback'],
      submissionProofUrl: json['submission_proof_url']
    );
  }
}