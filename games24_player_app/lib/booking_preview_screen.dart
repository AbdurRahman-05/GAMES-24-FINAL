import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  String? _errorMessage;

  IconData _getSportIcon(String sport) {
    final s = sport.toLowerCase();
    if (s.contains('cricket')) return Icons.sports_cricket_rounded;
    if (s.contains('badminton')) return Icons.sports_tennis_rounded;
    if (s.contains('pickle')) return Icons.sports_tennis_outlined;
    return Icons.sports_soccer_rounded;
  }

  void _startCashfreePaymentAnimation() {
    HapticFeedback.mediumImpact();
    setState(() => _errorMessage = null);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CashfreePaymentAnimationDialog(
        amount: widget.courtFee,
        turfId: widget.turfId,
        turfName: widget.turfName,
        courtName: widget.courtName,
        customerName: widget.customerName,
        customerPhone: widget.customerPhone,
        sport: widget.sport,
        paymentMethod: 'Cashfree',
        bookingPayload: widget.bookingPayload,
        timeSlotsFallback: widget.timeSlots,
        onSuccess: (bookingObj, orderId) {
          Navigator.pop(ctx); // Close payment animation dialog
          _onBookingSuccess(bookingObj, orderId);
        },
        onFailed: (error) {
          Navigator.pop(ctx); // Close dialog on failure
          setState(() => _errorMessage = error);
        },
      ),
    );
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
      bookingObj['amount'] ??= widget.courtFee;
      bookingObj['paymentMethod'] ??= 'Cashfree';
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

    // The server creates the open-match challenge when the payment is confirmed; just refresh.
    if (widget.isOpenForChallenge) {
      ChallengeManager().fetchChallenges();
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

            // 4. CASHFREE PAYMENT INFO
            _buildCashfreeGatewayCard(),
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

            const SizedBox(height: 80), // Spacing for bottom button
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
                  'Pay with UPI, cards or netbanking on Cashfree\'s secure checkout. Your slot is held for 10 minutes while you pay.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), height: 1.3),
                ),
              ],
            ),
          ),
        ],
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
            onPressed: _startCashfreePaymentAnimation,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4FF00),
              foregroundColor: Colors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Row(
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

// ============================================================================
// CASHFREE ANIMATED PAYMENT GATEWAY DIALOG
// ============================================================================
class CashfreePaymentAnimationDialog extends StatefulWidget {
  final double amount;
  final int turfId;
  final String turfName;
  final String courtName;
  final String customerName;
  final String customerPhone;
  final String sport;
  final String paymentMethod;
  final Map<String, dynamic> bookingPayload;
  final List<String> timeSlotsFallback;
  final void Function(Map<String, dynamic> bookingObj, String orderId) onSuccess;
  final void Function(String error) onFailed;

  const CashfreePaymentAnimationDialog({
    super.key,
    required this.amount,
    required this.turfId,
    required this.turfName,
    required this.courtName,
    required this.customerName,
    required this.customerPhone,
    required this.sport,
    required this.paymentMethod,
    required this.bookingPayload,
    this.timeSlotsFallback = const [],
    required this.onSuccess,
    required this.onFailed,
  });

  @override
  State<CashfreePaymentAnimationDialog> createState() =>
      _CashfreePaymentAnimationDialogState();
}

class _CashfreePaymentAnimationDialogState
    extends State<CashfreePaymentAnimationDialog> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _successController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _successScale;

  int _step = 1; // 1: Order Init, 2: Token Gen, 3: Verifying, 4: Success
  String _stepText = 'Connecting to Cashfree Gateway...';
  String _orderId = '';
  String _cfPaymentId = '';
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _successScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.elasticOut),
    );

    _runCashfreePaymentFlow();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _successController.dispose();
    super.dispose();
  }

  Future<void> _runCashfreePaymentFlow() async {
    try {
      // Step 1: the server holds the slots and prices them (the amount shown is what is charged).
      setState(() {
        _step = 1;
        _stepText = 'Reserving your slot...';
      });

      final payload = widget.bookingPayload;
      final slots = (payload['timeSlots'] is List)
          ? List<String>.from((payload['timeSlots'] as List).map((e) => e.toString()))
          : widget.timeSlotsFallback;
      final created = await CashfreeService.createOrder(
        turfId: widget.turfId,
        date: (payload['date'] ?? '').toString(),
        timeSlots: slots,
        sport: widget.sport,
        courtName: widget.courtName,
        customerName: widget.customerName,
        customerPhone: widget.customerPhone,
        isOpenMatch: payload['isOpenMatch'] == true,
        teamName: payload['teamName']?.toString(),
        teamSize: payload['teamSize']?.toString(),
      );
      final order = created.order;
      if (order == null) {
        if (!mounted) return;
        widget.onFailed(created.error ?? 'Could not start the payment.');
        return;
      }
      _orderId = order.orderId;
      if (!mounted) return;

      // Step 2: pay. Test mode is only offered by the server outside production.
      HapticFeedback.lightImpact();
      setState(() {
        _step = 2;
        _stepText = order.isTestMode
            ? 'TEST MODE: no real money is charged. Simulating payment of ₹${order.amount.toStringAsFixed(0)}...'
            : 'Complete the payment of ₹${order.amount.toStringAsFixed(0)} on the Cashfree page...';
      });

      if (!order.isTestMode) {
        final checkoutError = await CashfreeService.openCheckout(order);
        if (checkoutError != null) {
          // Player closed the checkout or the payment failed: release the slot right away,
          // unless Cashfree reports it as paid after all.
          final late = await CashfreeService.cancelOrder(order.orderId);
          if (!mounted) return;
          if (late == null || !late.success) {
            widget.onFailed(checkoutError);
            return;
          }
          _finish(late);
          return;
        }
      } else {
        await Future.delayed(const Duration(milliseconds: 900));
      }

      if (!mounted) return;
      HapticFeedback.lightImpact();
      setState(() {
        _step = 3;
        _stepText = 'Verifying payment with Cashfree...';
      });

      // Step 3: the server checks the order status and amount with Cashfree, then confirms.
      var result = await CashfreeService.verifyPayment(order.orderId);
      for (var attempt = 0; attempt < 4 && result.isPending; attempt++) {
        await Future.delayed(const Duration(seconds: 2));
        result = await CashfreeService.verifyPayment(order.orderId);
      }
      if (!mounted) return;

      if (!result.success || result.booking == null) {
        widget.onFailed(result.isPending
            ? 'We have not received payment confirmation yet. If money was deducted, the booking will appear in My Bookings shortly or be refunded automatically.'
            : result.message);
        return;
      }
      _finish(result);
    } catch (e) {
      if (!mounted) return;
      widget.onFailed('Payment error: $e');
    }
  }

  Future<void> _finish(CashfreePaymentResult result) async {
    _cfPaymentId = result.cfPaymentId ?? '';
    setState(() {
      _step = 4;
      _isSuccess = true;
      _stepText = 'Payment confirmed! Your slot is booked. 🎉';
    });
    HapticFeedback.heavyImpact();
    _successController.forward();
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    widget.onSuccess(Map<String, dynamic>.from(result.booking ?? {}), _orderId);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF0D111A),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _isSuccess
                ? const Color(0xFF10B981)
                : const Color(0xFFD4FF00).withValues(alpha: 0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _isSuccess
                  ? const Color(0xFF10B981).withValues(alpha: 0.25)
                  : const Color(0xFFD4FF00).withValues(alpha: 0.15),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Header: Cashfree Official Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2916),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFD4FF00).withValues(alpha: 0.4)),
                  ),
                  child: const Icon(Icons.security_rounded, color: Color(0xFFD4FF00), size: 16),
                ),
                const SizedBox(width: 8),
                const Text(
                  'CASHFREE PAYMENTS',
                  style: TextStyle(
                    fontFamily: 'Delight',
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
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
                    'SANDBOX',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF6EE7B7),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            // Animated Center Graphic
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (!_isSuccess) ...[
                    // Rotating outer dashed orbit
                    AnimatedBuilder(
                      animation: _rotationController,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _rotationController.value * 2 * math.pi,
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFD4FF00).withValues(alpha: 0.35),
                                width: 2,
                                strokeAlign: BorderSide.strokeAlignOutside,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    // Pulsing Glow Circle
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF1F2916),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFD4FF00).withValues(alpha: 0.3),
                                  blurRadius: 18,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    // Cashfree Center Icon
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.bolt_rounded, color: Color(0xFFD4FF00), size: 36),
                        Text(
                          'CASHFREE',
                          style: TextStyle(
                            fontFamily: 'Delight',
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFD4FF00),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Success Checkmark with elastic pop animation
                    ScaleTransition(
                      scale: _successScale,
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF10B981),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withValues(alpha: 0.5),
                              blurRadius: 24,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.black,
                          size: 52,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Amount Display
            Text(
              '₹${widget.amount.toInt()}',
              style: TextStyle(
                fontFamily: 'Delight',
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: _isSuccess ? const Color(0xFF10B981) : const Color(0xFFD4FF00),
              ),
            ),
            Text(
              'Court Fee for ${widget.courtName}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),

            const SizedBox(height: 18),

            // Animated Status Text
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF151B27),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isSuccess
                      ? const Color(0xFF10B981).withValues(alpha: 0.4)
                      : const Color(0xFF1E273A),
                ),
              ),
              child: Row(
                children: [
                  if (!_isSuccess) ...[
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFD4FF00),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ] else ...[
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      _stepText,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: _isSuccess ? const Color(0xFF34D399) : const Color(0xFFE2E8F0),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Step timeline dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final stepNum = index + 1;
                final isPassed = _step >= stepNum;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _step == stepNum ? 18 : 8,
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: isPassed
                        ? (_isSuccess ? const Color(0xFF10B981) : const Color(0xFFD4FF00))
                        : const Color(0xFF273248),
                  ),
                );
              }),
            ),

            if (_cfPaymentId.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Ref: $_cfPaymentId',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
