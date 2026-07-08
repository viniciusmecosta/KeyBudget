class User {
  final String id;
  final String name;
  final String email;
  final String? avatarPath;
  final String? phoneNumber;
  final bool? enableIncomes;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.avatarPath,
    this.phoneNumber,
    this.enableIncomes,
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarPath,
    String? phoneNumber,
    bool? enableIncomes,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarPath: avatarPath ?? this.avatarPath,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      enableIncomes: enableIncomes ?? this.enableIncomes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar_path': avatarPath,
      'phone_number': phoneNumber,
      'enable_incomes': enableIncomes,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      avatarPath: map['avatar_path'],
      phoneNumber: map['phone_number'],
      enableIncomes: map['enable_incomes'],
    );
  }
}
