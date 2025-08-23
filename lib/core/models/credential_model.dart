class Credential {
  final String? id;
  final String location;
  final String login;
  final String encryptedPassword;
  final String? email;
  final String? phoneNumber;
  final String? notes;
  final String? logoPath;

  Credential({
    this.id,
    required this.location,
    required this.login,
    required this.encryptedPassword,
    this.email,
    this.phoneNumber,
    this.notes,
    this.logoPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'location': location,
      'login': login,
      'encrypted_password': encryptedPassword,
      'email': email,
      'phone_number': phoneNumber,
      'notes': notes,
      'logo_path': logoPath,
    };
  }

  factory Credential.fromMap(Map<String, dynamic> map, String id) {
    return Credential(
      id: id,
      location: map['location'],
      login: map['login'],
      encryptedPassword: map['encrypted_password'],
      email: map['email'],
      phoneNumber: map['phone_number'],
      notes: map['notes'],
      logoPath: map['logo_path'],
    );
  }
}
