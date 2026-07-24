class AppNotification {
  final String id;
  final String? subject;
  final String body;
  final String? readAt;
  final String createdAt;

  AppNotification(
      {required this.id,
      this.subject,
      required this.body,
      this.readAt,
      required this.createdAt});

  bool get isRead => readAt != null;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['_id'] as String,
      subject: json['subject'] as String?,
      body: json['body'] as String,
      readAt: json['readAt'] as String?,
      createdAt: json['createdAt'] as String,
    );
  }
}
