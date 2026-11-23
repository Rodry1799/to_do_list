class UserModel {
  final int id;
  final String username;
  final String email;
  final String token;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: int.parse(json['id'].toString()),
      username: json['username'],
      email: json['email'],
      token: json['token'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'token': token,
      };
}
