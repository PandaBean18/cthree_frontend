class CreatorPlatformModel {
  final String id;
  final String name;
  final String username;
  final double? engagementRate;
  final int? followers;
  final int? views;
  final List<String> insights;

  CreatorPlatformModel({
    required this.id,
    required this.name,
    required this.username,
    this.engagementRate,
    this.followers,
    this.views,
    required this.insights,
  });

  factory CreatorPlatformModel.fromJson(Map<String, dynamic> json) {
    return CreatorPlatformModel(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      username: json['username'] ?? '',
      engagementRate: json['engagement_rate'] != null ? (json['engagement_rate'] as num).toDouble() : null,
      followers: json['followers'],
      views: json['views'],
      insights: json['insights'] != null ? List<String>.from(json['insights']) : [],
    );
  }
}
