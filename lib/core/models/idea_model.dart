class InspoModel {
  final String id;
  final String sourceType;
  final String status;
  final String? externalUrl;
  final String? thumbnailUrl;
  final DateTime createdAt;

  InspoModel({
    required this.id,
    required this.sourceType,
    required this.status,
    this.externalUrl,
    this.thumbnailUrl,
    required this.createdAt,
  });

  factory InspoModel.fromJson(Map<String, dynamic> json) {
    return InspoModel(
      id: json['id'],
      sourceType: json['source_type'],
      status: json['status'],
      externalUrl: json['external_url'],
      thumbnailUrl: json['thumbnail_url'],
      createdAt: DateTime.parse(json['created_at']).add(const Duration(hours: 5, minutes: 30)),
    );
  }
}

class IdeaModel {
  final String id;
  final String title;
  final Map<String, dynamic> description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<InspoModel> inspos;

  IdeaModel({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    required this.inspos,
  });

  factory IdeaModel.fromJson(Map<String, dynamic> json) {
    return IdeaModel(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? {'ops': []},
      createdAt: DateTime.parse(json['created_at']).add(const Duration(hours: 5, minutes: 30)),
      updatedAt: DateTime.parse(json['updated_at']).add(const Duration(hours: 5, minutes: 30)),
      inspos: json['inspos'] != null 
          ? (json['inspos'] as List).map((i) => InspoModel.fromJson(i)).toList() 
          : [],
    );
  }
}