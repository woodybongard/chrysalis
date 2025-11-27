class GroupEntity {
  GroupEntity({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.description,
  });

  factory GroupEntity.fromJson(Map<String, dynamic> json) {
    return GroupEntity(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      description: json['description'] as String?,
    );
  }
  final String id;
  final String name;
  final String? avatarUrl;
  final String? description;
}
