class CreatePlatformRequest {
  final String name;
  final String username;
  final double? engagementRate;
  final int? followers;
  final int? views;
  final List<String> insightItemIds;

  CreatePlatformRequest({
    required this.name,
    required this.username,
    this.engagementRate,
    this.followers,
    this.views,
    required this.insightItemIds,
  });

  Map<String, dynamic> toJson() {
    final map = {
      'name': name,
      'username': username,
      'engagement_rate': engagementRate,
      'followers': followers,
      'views': views,
      'insight_item_ids': insightItemIds,
    };
    
    return Map.fromEntries(map.entries.where((e) => e.value != null));
  }
}
