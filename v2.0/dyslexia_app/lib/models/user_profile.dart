/// Perfil del usuario
class UserProfile {
  final String id;
  final String name;
  final int age;
  final DateTime createdAt;
  final int totalActivitiesCompleted;
  final Map<String, int> activityCounts;

  UserProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.createdAt,
    this.totalActivitiesCompleted = 0,
    Map<String, int>? activityCounts,
  }) : activityCounts = activityCounts ?? {};

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'age': age,
    'createdAt': createdAt.toIso8601String(),
    'totalActivitiesCompleted': totalActivitiesCompleted,
    'activityCounts': activityCounts,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'],
    name: json['name'],
    age: json['age'],
    createdAt: DateTime.parse(json['createdAt']),
    totalActivitiesCompleted: json['totalActivitiesCompleted'] ?? 0,
    activityCounts: Map<String, int>.from(json['activityCounts'] ?? {}),
  );

  UserProfile copyWith({
    String? name,
    int? age,
    int? totalActivitiesCompleted,
    Map<String, int>? activityCounts,
  }) => UserProfile(
    id: id,
    name: name ?? this.name,
    age: age ?? this.age,
    createdAt: createdAt,
    totalActivitiesCompleted:
        totalActivitiesCompleted ?? this.totalActivitiesCompleted,
    activityCounts: activityCounts ?? this.activityCounts,
  );
}
