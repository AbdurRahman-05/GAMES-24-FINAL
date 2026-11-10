import 'main_layout.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'booking_manager.dart';
import 'challenge_manager.dart';

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String time;
  final IconData icon;
  final Color color;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.icon,
    required this.color,
    this.isRead = false,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<NotificationItem> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('fullName') ?? 'Player';

    final bookings = BookingManager().allBookings;
    final challenges = ChallengeManager().challengesNotifier.value;

    final List<NotificationItem> list = [];

    // 1. Welcome Notification
    list.add(
      NotificationItem(
        id: 'notif_welcome',
        title: 'Welcome to Games24! 🎉',
        message: 'Hello $name, explore nearby turfs, book instant slots, and join competitive challenges!',
        time: 'Just now',
        icon: Icons.celebration_rounded,
        color: const Color(0xFF166534),
        isRead: false,
      ),
    );

    // 2. Booking confirmations
    for (var b in bookings.take(3)) {
      list.add(
        NotificationItem(
          id: 'notif_b_${b['id']}',
          title: 'Booking Confirmed ✅',
          message: 'Your slot at ${b['courtName'] ?? 'Turf'} on ${b['date']} (${b['timeSlot']}) is locked in.',
          time: 'Active',
          icon: Icons.confirmation_number_rounded,
          color: const Color(0xFF0284C7),
          isRead: false,
        ),
      );
    }

    // 3. Challenge alert
    for (var c in challenges.take(2)) {
      list.add(
        NotificationItem(
          id: 'notif_c_${c.id}',
          title: 'Open Challenge Alert ⚽',
          message: '${c.challengerName} is seeking opponents for ${c.sport} at ${c.turfName}.',
          time: c.time,
          icon: Icons.flag_rounded,
          color: const Color(0xFFEA580C),
          isRead: true,
        ),
      );
    }

    if (mounted) {
      setState(() {
        _notifications.clear();
        _notifications.addAll(list);
        _isLoading = false;
      });
    }
  }

  void _clearAll() {
    setState(() {
      _notifications.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF111827), size: 20),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const MainLayout()),
              );
            }
          },
        ),
        actions: [
          if (_notifications.isNotEmpty)
            TextButton(
              onPressed: _clearAll,
              child: const Text(
                'Clear All',
                style: TextStyle(
                  color: Color(0xFFDC2626),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF166534)))
          : _notifications.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.notifications_off_outlined, size: 56, color: Color(0xFF9CA3AF)),
                        SizedBox(height: 16),
                        Text(
                          'No Notifications Yet',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF374151)),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'You are all caught up! Match confirmations and squad invites will appear here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notifications.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = _notifications[index];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: item.isRead ? const Color(0xFFE5E7EB) : const Color(0xFFBBF7D0),
                          width: item.isRead ? 1.0 : 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: item.color.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(item.icon, color: item.color, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Color(0xFF111827),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      item.time,
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.message,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563), height: 1.35),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
