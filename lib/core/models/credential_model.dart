class Credential {
  final int? id;
  final int userId;
  final String location;
  final String login;
  final String encryptedPassword;
  final String? email;
  final String? phoneNumber;
  final String? notes;

  Credential({
    this.id,
    required this.userId,
    required this.location,
    required this.login,
    required this.encryptedPassword,
    this.email,
    this.phoneNumber,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'location': location,
      'login': login,
      'encrypted_password': encryptedPassword,
      'email': email,
      'phone_number': phoneNumber,
      'notes': notes,
    };
  }

  factory Credential.fromMap(Map<String, dynamic> map) {
    return Credential(
      id: map['id'],
      userId: map['user_id'],
      location: map['location'],
      login: map['login'],
      encryptedPassword: map['encrypted_password'],
      email: map['email'],
      phoneNumber: map['phone_number'],
      notes: map['notes'],
    );
  }
}
