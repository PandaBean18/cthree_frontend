class ProfileModel {
  final String id;
  final String email; 
  final String username;
  final String role;
  final String description;
  String? avatarUrl;
  List<String> portfolio = [];

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
    return ProfileModel(
      id: json['user']['id'].toString(),
      email: json['user']['email'],
      username: json['user']['username'],
      role: json['user']['role'],
      description: json['user']['description'] ?? '',
      avatarUrl: json['avatar'] != null ? json['avatar']['url'] : null ,
      portfolio: List<String>.from(json['portfolio'] ?? []),
    );
  }

}