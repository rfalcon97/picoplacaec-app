class AppUser {
  const AppUser({required this.id, required this.email, required this.role});

  final String id;
  final String email;
  final String role;

  bool get isAdmin => role == 'ADMIN';

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        email: json['email'] as String,
        role: json['role'] as String,
      );
}
