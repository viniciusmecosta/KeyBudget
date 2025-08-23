class User {
  final String id;
  final String name;
  final String email;
  final String? avatarPath;
  final String? phoneNumber;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.avatarPath,
    this.phoneNumber,
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarPath,
    String? phoneNumber,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarPath: avatarPath ?? this.avatarPath,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar_path': avatarPath,
      'phone_number': phoneNumber,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      avatarPath: map['avatar_path'],
      phoneNumber: map['phone_number'],
    );
  }
}
