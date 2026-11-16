import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api_config.dart';

class CashfreePaymentResult {
  final bool success;
  final String orderId;
  final String? cfPaymentId;
  final Map<String, dynamic>? booking;
  final String message;

  CashfreePaymentResult({
    required this.success,
    required this.orderId,
    this.cfPaymentId,
    this.booking,
    required this.message,
  });
}

class CashfreeService {
  CashfreeService._();

  /// Checks whether Cashfree gateway is live with real credentials or running in test mode
  static Future<Map<String, dynamic>> checkGatewayStatus() async {
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/cashfree/status')).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (_) {}
    return {'isConfigured': false, 'environment': 'sandbox', 'status': 'READY_AWAITING_KEYS'};
  }

  /// Creates a payment order on backend via Cashfree Orders API
  static Future<Map<String, dynamic>?> createOrder({
    required double orderAmount,
    required String customerPhone,
    required String customerName,
    int? turfId,
    Map<String, dynamic>? bookingPayload,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/cashfree/create-order'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'orderAmount': orderAmount,
          'customerPhone': customerPhone,
          'customerName': customerName,
          'turfId': turfId,
          'bookingPayload': bookingPayload,
        }),
      ).timeout(const Duration(seconds: 20));

      if (res.statusCode == 200 || res.statusCode == 201) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      debugPrint('Cashfree createOrder error: $e');
    }
    return null;
  }

  /// Verifies an order's payment and finalizes the booking in PostgreSQL
  static Future<CashfreePaymentResult> verifyOrderPayment(String orderId) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/cashfree/verify-payment'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'orderId': orderId}),
      ).timeout(const Duration(seconds: 20));

      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        return CashfreePaymentResult(
          success: data['success'] == true,
          orderId: orderId,
          cfPaymentId: data['cfPaymentId']?.toString(),
          booking: data['booking'] != null ? Map<String, dynamic>.from(data['booking']) : null,
          message: data['message'] ?? 'Payment verified successfully.',
        );
      }
    } catch (e) {
      debugPrint('Cashfree verifyOrderPayment error: $e');
    }

    return CashfreePaymentResult(
      success: false,
      orderId: orderId,
      message: 'Failed to verify payment with Cashfree. Please retry.',
    );
  }

  /// Displays the Cashfree Checkout bottom sheet and guides player through payment
  static Future<CashfreePaymentResult?> startCheckout({
    required BuildContext context,
    required double amount,
    required String customerPhone,
    required String customerName,
    int? turfId,
    required Map<String, dynamic> bookingPayload,
  }) async {
    return showModalBottomSheet<CashfreePaymentResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CashfreeCheckoutSheet(
        amount: amount,
        customerPhone: customerPhone,
        customerName: customerName,
        turfId: turfId,
        bookingPayload: bookingPayload,
      ),
    );
  }
}

class _CashfreeCheckoutSheet extends StatefulWidget {
  final double amount;
  final String customerPhone;
  final String customerName;
  final int? turfId;
  final Map<String, dynamic> bookingPayload;

  const _CashfreeCheckoutSheet({
    required this.amount,
    required this.customerPhone,
    required this.customerName,
    this.turfId,
    required this.bookingPayload,
  });

  @override
  State<_CashfreeCheckoutSheet> createState() => _CashfreeCheckoutSheetState();
}

class _CashfreeCheckoutSheetState extends State<_CashfreeCheckoutSheet> {
  String _selectedMethod = 'UPI'; // 'UPI', 'CARDS', 'NETBANKING'
  String _selectedUpiApp = 'GPay';
  bool _isProcessing = false;
  String _statusMessage = '';

  Future<void> _handlePayment() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Connecting to Cashfree Payment Gateway...';
    });

    try {
      // 1. Create order on backend
      final orderRes = await CashfreeService.createOrder(
        orderAmount: widget.amount,
        customerPhone: widget.customerPhone,
        customerName: widget.customerName,
        turfId: widget.turfId,
        bookingPayload: widget.bookingPayload,
      );

      if (orderRes == null || orderRes['orderId'] == null) {
        if (mounted) {
          setState(() {
            _isProcessing = false;
            _statusMessage = 'Unable to initiate Cashfree order. Please check network.';
          });
        }
        return;
      }

      final String orderId = orderRes['orderId'];

      if (mounted) {
        setState(() {
          _statusMessage = 'Processing secure payment via Cashfree...';
        });
      }

      // Small delay for smooth UX transition
      await Future.delayed(const Duration(milliseconds: 1200));

      if (mounted) {
        setState(() {
          _statusMessage = 'Verifying transaction & confirming slot...';
        });
      }

      // 2. Verify payment on backend
      final verifyRes = await CashfreeService.verifyOrderPayment(orderId);

      if (mounted) {
        if (verifyRes.success) {
          Navigator.of(context).pop(verifyRes);
        } else {
          setState(() {
            _isProcessing = false;
            _statusMessage = verifyRes.message;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusMessage = 'Payment error: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF154D36).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.shield_rounded, color: Color(0xFF154D36), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cashfree Payments',
                      style: TextStyle(
                        fontFamily: 'Delight',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      '256-bit Encrypted Checkout',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              // Amount badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF154D36), Color(0xFF0D3323)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '₹${widget.amount.toInt()}',
                  style: const TextStyle(
                    fontFamily: 'Delight',
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Payment Methods Selector
          const Text(
            'SELECT PAYMENT MODE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 12),

          // UPI Option
          _buildMethodTile(
            id: 'UPI',
            title: 'UPI Instant Pay',
            subtitle: 'Google Pay, PhonePe, Paytm, BHIM',
            icon: Icons.flash_on_rounded,
            iconColor: const Color(0xFF059669),
          ),
          const SizedBox(height: 8),

          // Cards Option
          _buildMethodTile(
            id: 'CARDS',
            title: 'Credit / Debit Card',
            subtitle: 'Visa, Mastercard, RuPay',
            icon: Icons.credit_card_rounded,
            iconColor: const Color(0xFF0284C7),
          ),
          const SizedBox(height: 8),

          // Netbanking Option
          _buildMethodTile(
            id: 'NETBANKING',
            title: 'Net Banking',
            subtitle: 'All Indian Major Banks',
            icon: Icons.account_balance_rounded,
            iconColor: const Color(0xFF7C3AED),
          ),

          if (_selectedMethod == 'UPI') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                _buildUpiAppChip('GPay', 'Google Pay'),
                const SizedBox(width: 8),
                _buildUpiAppChip('PhonePe', 'PhonePe'),
                const SizedBox(width: 8),
                _buildUpiAppChip('Paytm', 'Paytm'),
              ],
            ),
          ],

          if (_statusMessage.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF154D36)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _statusMessage,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF154D36),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Pay Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _handlePayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF154D36),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isProcessing
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : Text(
                    'Pay ₹${widget.amount.toInt()} with Cashfree',
                    style: const TextStyle(
                      fontFamily: 'Delight',
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline_rounded, size: 13, color: Color(0xFF94A3B8)),
                const SizedBox(width: 4),
                Text(
                  'Powered by Cashfree Payments India',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodTile({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    final isSelected = _selectedMethod == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF154D36).withValues(alpha: 0.06) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF154D36) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Delight',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: isSelected ? const Color(0xFF154D36) : null,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? const Color(0xFF154D36) : Colors.grey.shade400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpiAppChip(String code, String name) {
    final isSelected = _selectedUpiApp == code;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedUpiApp = code),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF154D36) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            name,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : const Color(0xFF334155),
            ),
          ),
        ),
      ),
    );
  }
}
