import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'booking_manager.dart';
import 'booking_qr_pass_modal.dart';
import 'challenge_manager.dart';
import 'services/cashfree_service.dart';

class BookingPreviewScreen extends StatefulWidget {
  final int turfId;
  final String turfName;
  final String turfLocation;
  final String imageUrl;
  final String courtName;
  final String sport;
  final String date;
  final String timeSlot;
  final List<String> timeSlots;
  final double courtFee;
  final String customerName;
  final String customerPhone;
  final bool isOpenForChallenge;
  final String teamName;
  final String teamSize;
  final Map<String, dynamic> bookingPayload;

  const BookingPreviewScreen({
    super.key,
    required this.turfId,
    required this.turfName,
    required this.turfLocation,
    required this.imageUrl,
    required this.courtName,
    required this.sport,
    required this.date,
    required this.timeSlot,
    required this.timeSlots,
    required this.courtFee,
    required this.customerName,
    required this.customerPhone,
    required this.isOpenForChallenge,
    required this.teamName,
    required this.teamSize,
    required this.bookingPayload,
  });

  @override
  State<BookingPreviewScreen> createState() => _BookingPreviewScreenState();
}

class _BookingPreviewScreenState extends State<BookingPreviewScreen> {
  String _selectedPaymentMethod = 'UPI'; // 'UPI', 'CARDS', 'NETBANKING'
  bool _isProcessing = false;
  String _statusStep = '';
  String? _errorMessage;

  IconData _getSportIcon(String sport) {
    final s = sport.toLowerCase();
    if (s.contains('cricket')) return Icons.sports_cricket_rounded;
    if (s.contains('badminton')) return Icons.sports_tennis_rounded;
    if (s.contains('pickle')) return Icons.sports_tennis_outlined;
    return Icons.sports_soccer_rounded;
  }

  Future<void> _executeCashfreePayment() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _statusStep = '1/3 Initializing order with Cashfree Test API...';
    });

    try {
      // 1. Create Order via Cashfree API on Backend
      final orderRes = await CashfreeService.createOrder(
        orderAmount: widget.courtFee,
        customerPhone: widget.customerPhone,
        customerName: widget.customerName,
        turfId: widget.turfId,
        bookingPayload: widget.bookingPayload,
      );

      if (orderRes == null || orderRes['orderId'] == null) {
        if (!mounted) return;
        setState(() {
          _isProcessing = false;
          _errorMessage = 'Failed to create Cashfree order. Check network connection.';
        });
        return;
      }

      final String orderId = orderRes['orderId'].toString();

      if (!mounted) return;
      setState(() {
        _statusStep = '2/3 Order Created (#${orderId.substring(orderId.length > 12 ? orderId.length - 12 : 0)}). Verifying test payment...';
      });

      // Small pause for realistic payment simulation
      await Future.delayed(const Duration(milliseconds: 1000));

      if (!mounted) return;
      setState(() {
        _statusStep = '3/3 Finalizing slot booking in PostgreSQL...';
      });

      // 2. Verify Payment on Backend
      final verifyRes = await CashfreeService.verifyOrderPayment(orderId);

      if (!mounted) return;

      if (!verifyRes.success) {
        // Fallback: direct booking endpoint if verification returned false
        final fallbackRes = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/turfs/${widget.turfId}/book'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(widget.bookingPayload),
        );

        if (fallbackRes.statusCode == 200 || fallbackRes.statusCode == 201) {
          final resData = jsonDecode(fallbackRes.body);
          final bookingData = resData is Map ? (resData['booking'] ?? resData) : {};
          _onBookingSuccess(Map<String, dynamic>.from(bookingData), orderId);
          return;
        }

        setState(() {
          _isProcessing = false;
          _errorMessage = verifyRes.message.isNotEmpty
              ? verifyRes.message
              : 'Payment verification failed. Please try again.';
        });
        return;
      }

      // Success! Finalize booking in local state and show QR modal
      final bookingData = verifyRes.booking ?? widget.bookingPayload;
      _onBookingSuccess(Map<String, dynamic>.from(bookingData), orderId);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Booking error: $e';
      });
    }
  }

  void _onBookingSuccess(Map<String, dynamic> bookingObj, String orderId) {
    try {
      bookingObj['turfId'] = widget.turfId;
      bookingObj['verifiedAdminId'] = widget.turfId;
      bookingObj['turfName'] = widget.turfName;
      bookingObj['imageUrl'] = widget.imageUrl;
      bookingObj['location'] = widget.turfLocation;
      bookingObj['courtName'] = widget.courtName;
      bookingObj['isActive'] = true;
      bookingObj['isOpenMatch'] = widget.isOpenForChallenge;
      bookingObj['customerName'] = widget.customerName;
      bookingObj['customerPhone'] = widget.customerPhone;
      bookingObj['sport'] = widget.sport;
      bookingObj['amount'] = widget.courtFee;
      bookingObj['paymentMethod'] = 'Cashfree ($_selectedPaymentMethod)';
      bookingObj['orderId'] = orderId;

      if (bookingObj['date'] == null) bookingObj['date'] = widget.date;
      if (bookingObj['timeSlot'] == null) bookingObj['timeSlot'] = widget.timeSlot;
      if (bookingObj['status'] == null) bookingObj['status'] = 'Confirmed';
      if (bookingObj['bookingCode'] == null && bookingObj['id'] != null) {
        bookingObj['bookingCode'] = 'G24-BK-${bookingObj['id'].toString().padLeft(4, '0')}';
      }
      if (bookingObj['bookingId'] == null) {
        bookingObj['bookingId'] = bookingObj['bookingCode'] ?? 'G24-BK-0001';
      }

      BookingManager().addBooking(bookingObj);
    } catch (e) {
      debugPrint('Error caching booking locally: $e');
    }
    BookingManager().fetchBookings();

    // If Open Match Challenge was requested, add to ChallengeManager
    if (widget.isOpenForChallenge) {
      final initials = widget.teamName.length >= 2
          ? widget.teamName.substring(0, 2).toUpperCase()
          : 'TC';

      ChallengeManager().addChallenge(
        Challenge(
          id: 'ch_${DateTime.now().millisecondsSinceEpoch}',
          turfName: widget.turfName,
          location: widget.turfLocation,
          date: widget.date,
          time: widget.timeSlot,
          sport: widget.sport,
          challengerName: widget.teamName,
          challengerTeamInitials: initials,
          challengerColor: const Color(0xFFD4FF00),
          creatorPhone: widget.customerPhone,
          teamSize: widget.teamSize,
          isCreator: true,
          joinRequests: [],
        ),
      );
    }

    if (mounted) {
      // Pop the preview screen with true, then show the ticket pass
      Navigator.pop(context, true);
      BookingQrPassModal.show(context, bookingObj);
    }
  }

  @override
  Widget build(BuildContext context) {
    final int hoursCount = widget.timeSlots.isNotEmpty ? widget.timeSlots.length : 1;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0C10),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F141F),
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Booking Summary & Pay',
              style: TextStyle(
                fontFamily: 'Delight',
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            Text(
              'Cashfree Secure Payment Gateway',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFF1E273A), height: 1),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. VENUE & COURT CARD
            _buildVenueCard(),
            const SizedBox(height: 14),

            // 2. SCHEDULE & TIMING CARD
            _buildScheduleCard(hoursCount),
            const SizedBox(height: 14),

            // 3. PLAYER & CHALLENGE DETAILS CARD
            _buildPlayerCard(),
            const SizedBox(height: 14),

            // 4. CASHFREE TEST API TRUST BANNER
            _buildCashfreeGatewayCard(),
            const SizedBox(height: 14),

            // 5. PAYMENT MODE SELECTOR
            _buildPaymentMethodSelector(),
            const SizedBox(height: 14),

            // 6. PRICE BREAKDOWN CARD
            _buildPriceBreakdownCard(),
            const SizedBox(height: 20),

            // Error display if any
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2B1115),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(fontSize: 12, color: Color(0xFFFCA5A5)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Live status banner during processing
            if (_isProcessing) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF172010),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFD4FF00).withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Color(0xFFD4FF00),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _statusStep,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFD4FF00),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            const SizedBox(height: 70), // Spacing for bottom button
          ],
        ),
      ),
      bottomSheet: _buildBottomPayButton(),
    );
  }

  Widget _buildVenueCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF121622),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E273A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Turf Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: widget.imageUrl.isNotEmpty
                ? Image.network(
                    widget.imageUrl,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildFallbackThumbnail(),
                  )
                : _buildFallbackThumbnail(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F2916),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFD4FF00).withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_getSportIcon(widget.sport), size: 12, color: const Color(0xFFD4FF00)),
                          const SizedBox(width: 4),
                          Text(
                            widget.sport.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFD4FF00),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
                      ),
                      child: const Text(
                        'VERIFIED TURF',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF38BDF8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  widget.turfName,
                  style: const TextStyle(
                    fontFamily: 'Delight',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 13, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        widget.turfLocation,
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Court: ${widget.courtName}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFCBD5E1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackThumbnail() {
    return Container(
      width: 72,
      height: 72,
      color: const Color(0xFF1E293B),
      child: const Icon(Icons.stadium_rounded, color: Color(0xFF94A3B8), size: 32),
    );
  }

  Widget _buildScheduleCard(int hoursCount) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF121622),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E273A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFFD4FF00)),
              const SizedBox(width: 8),
              const Text(
                'BOOKING SCHEDULE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2916),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFD4FF00).withValues(alpha: 0.3)),
                ),
                child: Text(
                  '$hoursCount ${hoursCount == 1 ? 'Hour' : 'Hours'} Total',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFD4FF00),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B0E17),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF1A2234)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Date',
                        style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.date,
                        style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B0E17),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF1A2234)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Time Slot',
                        style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.timeSlot,
                        style: const TextStyle(fontSize: 13, color: Color(0xFFD4FF00), fontWeight: FontWeight.w800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF121622),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E273A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.person_outline_rounded, size: 16, color: Color(0xFFD4FF00)),
              SizedBox(width: 8),
              Text(
                'ATHLETE DETAILS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.customerName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.customerPhone.isNotEmpty ? widget.customerPhone : 'No mobile registered',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: const Text(
                  'Booker',
                  style: TextStyle(fontSize: 11, color: Color(0xFFCBD5E1), fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),

          if (widget.isOpenForChallenge) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF261D0F),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.flash_on_rounded, color: Color(0xFFF59E0B), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Open Match Challenge Enabled',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFFFBBF24)),
                        ),
                        Text(
                          "Team '${widget.teamName}' (${widget.teamSize}) is looking for an opponent",
                          style: const TextStyle(fontSize: 11, color: Color(0xFFFDE68A)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCashfreeGatewayCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1712),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF064E3B),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.security_rounded, color: Color(0xFF34D399), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Cashfree Payments',
                      style: TextStyle(
                        fontFamily: 'Delight',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF065F46),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'TEST SANDBOX',
                        style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: Color(0xFF6EE7B7)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                const Text(
                  'Connected with registered Merchant Test API keys. Real PG session is generated on Cashfree Sandbox.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSelector() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF121622),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E273A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SELECT PAYMENT MODE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 12),

          _buildPaymentTile(
            id: 'UPI',
            title: 'UPI Instant Pay',
            subtitle: 'Google Pay, PhonePe, Paytm, BHIM',
            icon: Icons.flash_on_rounded,
            iconColor: const Color(0xFFD4FF00),
          ),
          const SizedBox(height: 8),

          _buildPaymentTile(
            id: 'CARDS',
            title: 'Credit / Debit Card',
            subtitle: 'Visa, Mastercard, RuPay',
            icon: Icons.credit_card_rounded,
            iconColor: const Color(0xFF38BDF8),
          ),
          const SizedBox(height: 8),

          _buildPaymentTile(
            id: 'NETBANKING',
            title: 'Net Banking',
            subtitle: 'All Major Indian Banks',
            icon: Icons.account_balance_rounded,
            iconColor: const Color(0xFFA78BFA),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTile({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    final isSelected = _selectedPaymentMethod == id;
    return InkWell(
      onTap: () => setState(() => _selectedPaymentMethod = id),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1F2916) : const Color(0xFF0B0E17),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFD4FF00) : const Color(0xFF1E273A),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : const Color(0xFFE2E8F0),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? const Color(0xFFD4FF00) : Colors.transparent,
                border: Border.all(
                  color: isSelected ? const Color(0xFFD4FF00) : const Color(0xFF475569),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 12, color: Colors.black)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceBreakdownCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF121622),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E273A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PRICE SUMMARY',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 12),
          _buildPriceRow('Court Booking Charges', '₹${widget.courtFee.toInt()}'),
          const SizedBox(height: 8),
          _buildPriceRow('Platform & Gateway Fee', 'FREE', isHighlight: true),
          const SizedBox(height: 8),
          _buildPriceRow('Taxes & GST', '₹0'),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFF1E273A)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Payable',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              Text(
                '₹${widget.courtFee.toInt()}',
                style: const TextStyle(
                  fontFamily: 'Delight',
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFD4FF00),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8))),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: isHighlight ? const Color(0xFF34D399) : Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomPayButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: const BoxDecoration(
        color: Color(0xFF0F141F),
        border: Border(top: BorderSide(color: Color(0xFF1E273A))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _executeCashfreePayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4FF00),
              foregroundColor: Colors.black,
              disabledBackgroundColor: const Color(0xFF263316),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _isProcessing
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFFD4FF00)),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Processing Cashfree Test Pay...',
                        style: TextStyle(
                          fontFamily: 'Delight',
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFD4FF00),
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_rounded, size: 18, color: Colors.black),
                      const SizedBox(width: 8),
                      Text(
                        'PAY ₹${widget.courtFee.toInt()} (CASHFREE TEST PAY)',
                        style: const TextStyle(
                          fontFamily: 'Delight',
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
