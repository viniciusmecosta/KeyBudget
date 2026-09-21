class User {
  final String id;
  final String name;
  final String email;
  final String? avatarPath;
  final String? phoneNumber;
  final bool? enableIncomes;
  final bool? appLocked;
  final bool? protectScreenCapture;
  final bool? enableSuppliers;
  final int? themeColor;
  final String? themeMode;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.avatarPath,
    this.phoneNumber,
    this.enableIncomes,
    this.appLocked,
    this.protectScreenCapture,
    this.enableSuppliers,
    this.themeColor,
    this.themeMode,
  });

  bool get effectiveProtectScreenCapture =>
      protectScreenCapture ?? (appLocked ?? true);

  String get effectiveThemeMode {
    switch (themeMode) {
      case 'light':
      case 'dark':
      case 'system':
        return themeMode!;
      default:
        return 'system';
    }
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarPath,
    bool clearAvatarPath = false,
    String? phoneNumber,
    bool clearPhoneNumber = false,
    bool? enableIncomes,
    bool? appLocked,
    bool? protectScreenCapture,
    bool clearProtectScreenCapture = false,
    bool? enableSuppliers,
    int? themeColor,
    String? themeMode,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarPath: clearAvatarPath ? null : (avatarPath ?? this.avatarPath),
      phoneNumber: clearPhoneNumber ? null : (phoneNumber ?? this.phoneNumber),
      enableIncomes: enableIncomes ?? this.enableIncomes,
      appLocked: appLocked ?? this.appLocked,
      protectScreenCapture: clearProtectScreenCapture
          ? null
          : (protectScreenCapture ?? this.protectScreenCapture),
      enableSuppliers: enableSuppliers ?? this.enableSuppliers,
      themeColor: themeColor ?? this.themeColor,
      themeMode: themeMode ?? this.themeMode,
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
      'protect_screen_capture': protectScreenCapture,
      'enable_suppliers': enableSuppliers ?? false,
      'theme_color': themeColor,
      'theme_mode': themeMode,
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
      protectScreenCapture: map['protect_screen_capture'] as bool?,
      enableSuppliers: map['enable_suppliers'] ?? false,
      themeColor: map['theme_color'],
      themeMode: map['theme_mode'] as String?,
    );
  }
}
