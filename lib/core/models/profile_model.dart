import 'portfolio_item_model.dart';
import 'creator_platform_model.dart';
import 'brand_collaboration_model.dart';

class ProfileModel {
  final String id;
  final String email; 
  final String username;
  final String role;
  final String description;
  String? avatarUrl;
  List<PortfolioItem> portfolio = [];
  List<CreatorPlatformModel> creatorPlatforms = [];
  List<BrandCollaborationModel> brandCollaborations = [];

  ProfileModel({
    required this.id,
    required this.email,
    required this.username,
    required this.role,
    required this.description,
    this.avatarUrl,
    required this.portfolio,
    required this.creatorPlatforms,
    required this.brandCollaborations,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    List<PortfolioItem> portfolioItems = [];

    for (int i = json['portfolio'].length-1; i >= 0; i--) {
      var j = json['portfolio'][i];
      PortfolioItem p = PortfolioItem.fromJson(j);
      portfolioItems.add(p);
    }

    List<CreatorPlatformModel> platforms = [];
    if (json['creator_platforms'] != null) {
      for (var j in json['creator_platforms']) {
        platforms.add(CreatorPlatformModel.fromJson(j));
      }
    }

    List<BrandCollaborationModel> brandCollaborations = [];
    if (json['brand_collaborations'] != null) {
      for (var j in json['brand_collaborations']) {
        brandCollaborations.add(BrandCollaborationModel.fromJson(j));
      }
    }

    return ProfileModel(
      id: json['user']['id'].toString(),
      email: json['user']['email'],
      username: json['user']['username'],
      role: json['user']['role'],
      description: json['user']['description'] ?? '',
      avatarUrl: json['avatar'] != null ? json['avatar']['url'] : null,
      portfolio: portfolioItems,
      creatorPlatforms: platforms,
      brandCollaborations: brandCollaborations,
    );
  }

}