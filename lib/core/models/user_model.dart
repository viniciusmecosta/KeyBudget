class User {
  final String id;
  final String name;
  final String email;
  final String? avatarPath;
  final String? phoneNumber;
  final bool? enableIncomes;
  final bool? appLocked;
  final bool? enableSuppliers;
  final int? themeColor;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.avatarPath,
    this.phoneNumber,
    this.enableIncomes,
    this.appLocked,
    this.enableSuppliers,
    this.themeColor,
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarPath,
    String? phoneNumber,
    bool? enableIncomes,
    bool? appLocked,
    bool? enableSuppliers,
    int? themeColor,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarPath: avatarPath ?? this.avatarPath,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      enableIncomes: enableIncomes ?? this.enableIncomes,
      appLocked: appLocked ?? this.appLocked,
      enableSuppliers: enableSuppliers ?? this.enableSuppliers,
      themeColor: themeColor ?? this.themeColor,
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
      'app_locked': appLocked ?? true,
      'enable_suppliers': enableSuppliers ?? false,
      'theme_color': themeColor,
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
      appLocked: map['app_locked'] ?? true,
      enableSuppliers: map['enable_suppliers'] ?? false,
      themeColor: map['theme_color'],
    );
  }
}
