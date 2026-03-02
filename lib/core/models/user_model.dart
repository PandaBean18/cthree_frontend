class UserModel {
  final String id;
  final String email; 
  final String username;
  final String role;
  final String timezone;
  final String description;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    required this.role,
    required this.timezone,
    required this.description,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'].toString(),
      email: json['email'],
      username: json['username'],
      role: json['role'],
      timezone: json['timezone'] ?? 'UTC',
      description: json['description'] ?? '',
    );
  }
}