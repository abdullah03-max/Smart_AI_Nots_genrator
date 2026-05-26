// lib/data/models/user_model.dart

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? profileImage;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.profileImage,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? 'User',
      email: json['email'] ?? '',
      profileImage: json['profile_image'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'profile_image': profileImage,
      };

  UserModel copyWith({
    String? name,
    String? profileImage,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt,
    );
  }
}
