class User {
  final int id;
  final String username;
  final String role;
  final String? createdAt;

  User({
    required this.id,
    required this.username,
    required this.role,
    this.createdAt,
  });

  bool get isAdmin => role == 'admin';
  bool get isCoAdmin => role == 'coadmin';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      username: json['username'] as String,
      role: json['role'] as String? ?? 'coadmin',
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'role': role,
      'created_at': createdAt,
    };
  }
}
