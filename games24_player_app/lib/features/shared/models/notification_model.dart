class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String time;
  final String type; // 'booking', 'match', 'offer', 'team'
  final bool isRead;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.type,
    this.isRead = false,
  });
}
