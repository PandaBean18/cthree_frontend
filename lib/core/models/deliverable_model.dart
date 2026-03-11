class SubmissionProof {
  String id;
  String url;
  String thumbnailUrl;
  String mediaType;

  SubmissionProof({required this.id, required this.url, required this.thumbnailUrl, required this.mediaType});

  factory SubmissionProof.fromJson(Map<String, dynamic> json) {
    return SubmissionProof(id: json['id'], url: json['url'], thumbnailUrl: json['thumbnail_url'], mediaType: json['media_type']);
  }
}

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
  String? submissionProofId;
  DateTime dueDate;
  String? brief;
  SubmissionProof? submissionProof;

  DeliverableModel({
    required this.id,
    required this.campaignParticipant, 
    required this.createdAt, 
    required this.deliverableType, 
    this.feedback, 
    required this.status, 
    this.submissionProofId,
    required this.dueDate,
    this.brief,
    this.submissionProof
  });

  factory DeliverableModel.fromJson(Map<String, dynamic> json) {
    return DeliverableModel(
      id: json['id'],
      campaignParticipant: CampaignParticipant.fromJson(json['campaign_participant']), 
      createdAt: DateTime.parse(json['created_at']), 
      deliverableType: json['deliverable_type'], 
      status: json['status'],
      feedback: json['feedback'],
      submissionProofId: json['submission_proof_id'],
      dueDate: DateTime.parse(json['due_date']),
      brief: json['brief'],
      submissionProof: json['submission_proof'] == null ? null : SubmissionProof.fromJson(json['submission_proof'])
    );
  }
}