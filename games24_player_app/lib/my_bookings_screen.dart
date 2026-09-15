import 'package:flutter/material.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  int _selectedTabIndex = 0; // 0 = Upcoming, 1 = Completed, 2 = Cancelled

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
            children: [
              _buildSecondaryHeader(context),
              const SizedBox(height: 16),
              _buildSegmentedTabBar(),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildUpcomingHeader(),
                      const SizedBox(height: 16),
                      _buildFootballBookingCard(),
                      const SizedBox(height: 24),
                      _buildBadmintonBookingCard(),
                      const SizedBox(height: 32),
                      _buildRecentPastActivity(),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24, // Assuming we don't have bottom nav in this screen
            child: _buildTurfPointsBanner(),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildSecondaryHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: const Icon(Icons.arrow_back, size: 20, color: Colors.black87),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'My Bookings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Keep track of your game slots',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: const Icon(Icons.filter_list, size: 18, color: Colors.black87),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: const Icon(Icons.help_outline, size: 18, color: Colors.black87),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F5F1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildTab(0, 'Upcoming (2)'),
            ),
            Expanded(
              child: _buildTab(1, 'Completed (5)'),
            ),
            Expanded(
              child: _buildTab(2, 'Cancelled (1)'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(int index, String title) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F6D38) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF6B7280),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF166534),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Upcoming Bookings',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF7FDF9),
            border: Border.all(color: const Color(0xFFE5F5EB)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            '2 slots secured',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF166534),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFootballBookingCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          // Image Header
          ClipRRect(
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            child: SizedBox(
              height: 120,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    'https://picsum.photos/seed/football/600/200',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black.withOpacity(0.1), Colors.black.withOpacity(0.8)],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF166534),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.check_circle_outline, color: Colors.white, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'Confirmed • #G24-8902',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.sports_soccer, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'FOOTBALL 7-A-SIDE',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Grand Arena Turf - Court 3',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Tomorrow',
                        style: TextStyle(color: Colors.black87, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Details
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F5F1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.calendar_today_outlined, size: 20, color: Color(0xFF166534)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Tomorrow, Sat Oct 12 • 06:00 PM - 07:00 PM',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Duration: 1 Hour (Night Floodlit)',
                            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F5F1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.location_on_outlined, size: 20, color: Color(0xFF166534)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Downtown Sports Complex, Court 3',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Sector 4, Central Link Road • 2.4 km away',
                            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.account_balance_wallet_outlined, size: 16, color: Color(0xFF166534)),
                        SizedBox(width: 8),
                        Text(
                          'Paid via UPI',
                          style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                    const Text(
                      '₹989',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Buttons
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.qr_code_2, size: 18),
                    label: const Text('View Ticket / QR', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F6D38),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.near_me_outlined, size: 16, color: Color(0xFF0F6D38)),
                          label: const Text('Get Directions', style: TextStyle(fontSize: 12, color: Color(0xFF0F6D38), fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFFF7FDF9),
                            side: const BorderSide(color: Color(0xFFE5F5EB)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.share_outlined, size: 16, color: Colors.black87),
                          label: const Text('Invite Friends', style: TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFFF3F5F1),
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    'Cancel Slot (Eligible for 100% refund up to 4 hrs prior)',
                    style: TextStyle(fontSize: 10, color: Color(0xFFDC2626), fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadmintonBookingCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          // Image Header
          ClipRRect(
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            child: SizedBox(
              height: 120,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    'https://picsum.photos/seed/badminton/600/200',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black.withOpacity(0.1), Colors.black.withOpacity(0.8)],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF166534),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.check_circle_outline, color: Colors.white, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'Confirmed • #G24-7741',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.sports_tennis, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'BADMINTON SYNTHETIC',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'SkyTurf Arena - Court A',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Wed, Oct 16',
                        style: TextStyle(color: Colors.black87, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Details
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F5F1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.access_time_outlined, size: 20, color: Color(0xFF166534)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Wed, Oct 16 • 07:00 PM - 08:00 PM',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Non-marking shoes mandatory',
                            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F5F1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.location_on_outlined, size: 20, color: Color(0xFF166534)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Central City Rooftop, Tower B',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Sky Tower 5th Floor • 4.1 km away',
                            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF166534)),
                        SizedBox(width: 8),
                        Text(
                          'Paid Full (Card)',
                          style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                    const Text(
                      '₹650',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.confirmation_num_outlined, size: 18),
                          label: const Text('View Ticket', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F6D38),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.tune, size: 18, color: Color(0xFF0F6D38)),
                          label: const Text('Manage', style: TextStyle(fontSize: 14, color: Color(0xFF0F6D38), fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFFF3F5F1),
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentPastActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: const [
                Icon(Icons.history, color: Colors.black87, size: 20),
                SizedBox(width: 8),
                Text(
                  'Recent Past Activity',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            Row(
              children: const [
                Text(
                  'View All (5)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F6D38),
                  ),
                ),
                Icon(Icons.chevron_right, size: 16, color: Color(0xFF0F6D38)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F5F1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.sports_cricket, size: 24, color: Color(0xFFD97706)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Champions\nPitch',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                height: 1.2,
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  '₹1,800',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                                const Text(
                                  'Receipt',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF166534)),
                                ),
                                const Text(
                                  'Sent',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF166534)),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Text(
                              'Cricket Box Turf • 2 Hours Match',
                              style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE5E7EB),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Completed',
                                style: TextStyle(fontSize: 10, color: Colors.black87, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F5F1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF166534)),
                    SizedBox(width: 8),
                    Text(
                      'Played Sun, Oct 6 • 08:00 AM - 10:00 AM',
                      style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Book Again', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F6D38),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.star_outline, size: 16, color: Color(0xFFD97706)),
                        label: const Text('Rate Venue ★ 4.8', style: TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFFF9FAFB),
                          side: BorderSide(color: const Color(0xFFF3F4F6)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTurfPointsBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FDF9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5F5EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFF0F6D38),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emoji_events, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Games24 Turf Points',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                Text(
                  'You earned 180 points this week',
                  style: TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE5F5EB)),
            ),
            child: const Text(
              '+180 pts',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F6D38),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
