class NotificationEntity {
  NotificationEntity({required this.data, this.title, this.body});

  factory NotificationEntity.fromMap(Map<String, dynamic> map) {
    return NotificationEntity(
      title: map['title'] as String?,
      body: map['body'] as String?,
      data: Map<String, dynamic>.from((map['data'] as Map?) ?? {}),
    );
  }
  final String? title;
  final String? body;
  final Map<String, dynamic> data;
}
