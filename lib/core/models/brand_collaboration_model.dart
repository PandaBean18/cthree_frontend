class BrandCollaborationModel {
  final String id;
  final String companyName;
  final String? companyUrl;
  final String? logoUrl;
  final String? description;
  final String? postUrl;
  final DateTime createdAt;

  BrandCollaborationModel({
    required this.id,
    required this.companyName,
    this.companyUrl,
    this.logoUrl,
    this.description,
    this.postUrl,
    required this.createdAt,
  });

  factory BrandCollaborationModel.fromJson(Map<String, dynamic> json) {
    return BrandCollaborationModel(
      id: json['id'],
      companyName: json['company_name'],
      companyUrl: json['company_url'],
      logoUrl: json['logo_url'],
      description: json['description'],
      postUrl: json['post_url'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_name': companyName,
      'company_url': companyUrl,
      'logo_url': logoUrl,
      'description': description,
      'post_url': postUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
