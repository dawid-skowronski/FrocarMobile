class NotificationModel {
  final int notificationId;
  final int userId;
  final String message;
  final DateTime createdAt;
  final bool isRead;

  NotificationModel({
    required this.notificationId,
    required this.userId,
    required this.message,
    required this.createdAt,
    required this.isRead,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      notificationId: json['notificationId'] ?? 0,
      userId: json['userId'] ?? 0,
      message: json['message'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      isRead: json['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notificationId': notificationId,
      'userId': userId,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
    };
  }
}