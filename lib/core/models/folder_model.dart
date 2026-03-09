class Folder {
  final String? id;
  final String name;
  final String? color;
  final DateTime createdAt;

  Folder({
    this.id,
    required this.name,
    this.color,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'color': color,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Folder.fromMap(Map<String, dynamic> map, String id) {
    return Folder(
      id: id,
      name: map['name'],
      color: map['color'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
