class Supplier {
  final String? id;
  final String name;
  final String? representativeName;
  final String? email;
  final String? phoneNumber;
  final String? photoPath;
  final String? notes;

  Supplier({
    this.id,
    required this.name,
    this.representativeName,
    this.email,
    this.phoneNumber,
    this.photoPath,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'representative_name': representativeName,
      'email': email,
      'phone_number': phoneNumber,
      'photo_path': photoPath,
      'notes': notes,
    };
  }

  factory Supplier.fromMap(Map<String, dynamic> map, String id) {
    return Supplier(
      id: id,
      name: map['name'],
      representativeName: map['representative_name'],
      email: map['email'],
      phoneNumber: map['phone_number'],
      photoPath: map['photo_path'],
      notes: map['notes'],
    );
  }
}
