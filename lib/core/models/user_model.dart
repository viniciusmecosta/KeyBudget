class User {
  final int? id;
  final String name;
  final String email;
  final String passwordHash;
  final String? avatarPath;
  final String? phoneNumber;

  User({
    this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    this.avatarPath,
    this.phoneNumber,
  });

  User copyWith({
    int? id,
    String? name,
    String? email,
    String? passwordHash,
    String? avatarPath,
    String? phoneNumber,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      avatarPath: avatarPath ?? this.avatarPath,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password_hash': passwordHash,
      'avatar_path': avatarPath,
      'phone_number': phoneNumber,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      passwordHash: map['password_hash'],
      avatarPath: map['avatar_path'],
      phoneNumber: map['phone_number'],
    );
  }
}
