class PortfolioItem {
  final String url;
  final String thumbnailUrl;
  final String mediaType;

  PortfolioItem({required this.url, required this.thumbnailUrl, required this.mediaType});

  factory PortfolioItem.fromJson(Map<String, dynamic> json) {
    return PortfolioItem(url: json['url'], thumbnailUrl: json['thumbnail_url'], mediaType: json['media_type']);
  }
}

class ProfileModel {
  final String id;
  final String email; 
  final String username;
  final String role;
  final String description;
  String? avatarUrl;
  List<PortfolioItem> portfolio = [];

  ProfileModel({
    required this.id,
    required this.email,
    required this.username,
    required this.role,
    required this.description,
    this.avatarUrl,
    required this.portfolio,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    List<PortfolioItem> portfolioItems = [];

    for (int i = json['portfolio'].length-1; i >= 0; i--) {
      var j = json['portfolio'][i];
      PortfolioItem p = PortfolioItem.fromJson(j);
      portfolioItems.add(p);
    }

    return ProfileModel(
      id: json['user']['id'].toString(),
      email: json['user']['email'],
      username: json['user']['username'],
      role: json['user']['role'],
      description: json['user']['description'] ?? '',
      avatarUrl: json['avatar'] != null ? json['avatar']['url'] : null,
      portfolio: portfolioItems,
    );
  }

}