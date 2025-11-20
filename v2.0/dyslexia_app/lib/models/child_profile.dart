class ChildProfile {
  final String id;
  final String tutorId;
  final String name;
  final int age;
  final DateTime? dateOfBirth;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ChildProfile({
    required this.id,
    required this.tutorId,
    required this.name,
    required this.age,
    this.dateOfBirth,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tutorId': tutorId,
      'name': name,
      'age': age,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory ChildProfile.fromMap(Map<String, dynamic> map) {
    return ChildProfile(
      id: map['id'] as String,
      tutorId: map['tutorId'] as String,
      name: map['name'] as String,
      age: map['age'] as int,
      dateOfBirth: map['dateOfBirth'] != null
          ? DateTime.parse(map['dateOfBirth'] as String)
          : null,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }

  ChildProfile copyWith({
    String? id,
    String? tutorId,
    String? name,
    int? age,
    DateTime? dateOfBirth,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChildProfile(
      id: id ?? this.id,
      tutorId: tutorId ?? this.tutorId,
      name: name ?? this.name,
      age: age ?? this.age,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
