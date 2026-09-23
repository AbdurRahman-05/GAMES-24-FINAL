import '../models/notification_model.dart';

class MockNotificationsRepository {
  MockNotificationsRepository._();

  static const List<NotificationModel> notifications = [
    NotificationModel(
      id: 'n1',
      title: 'Booking Confirmed!',
      body: 'Your slot at Madurai Turf Arena (KK Nagar) is confirmed for 28 Jul, 07:00 PM.',
      time: '10 mins ago',
      type: 'booking',
      isRead: false,
    ),
    NotificationModel(
      id: 'n2',
      title: 'Match Request Accepted',
      body: 'Host Vijay Sethu accepted your request to join Football (7v7) match.',
      time: '2 hours ago',
      type: 'match',
      isRead: false,
    ),
    NotificationModel(
      id: 'n3',
      title: 'Weekend Offer 🎉',
      body: 'Get 20% OFF on all Badminton court bookings in Anna Nagar using code MADURAI20.',
      time: '1 day ago',
      type: 'offer',
      isRead: true,
    ),
    NotificationModel(
      id: 'n4',
      title: 'Team Challenge Received',
      body: 'Meenakshi Strikers challenged your team Madurai Lions FC to a Box Cricket match!',
      time: '2 days ago',
      type: 'team',
      isRead: true,
    ),
  ];
}
