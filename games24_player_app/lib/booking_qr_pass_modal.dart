import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class BookingQrPassModal extends StatelessWidget {
  final Map<String, dynamic> booking;

  const BookingQrPassModal({super.key, required this.booking});

  static void show(BuildContext context, Map<String, dynamic> booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BookingQrPassModal(booking: booking),
    );
  }

  String get qrPayload {
    final bookingId = (booking['id'] ?? booking['bookingId'] ?? 'BK-G24').toString();
    final turfId = booking['turfId'] ?? booking['verifiedAdminId'] ?? 1;
    final turfName = (booking['turfName'] ?? booking['courtName'] ?? 'Turf Arena').toString();
    final customerName = (booking['customerName'] ?? booking['userName'] ?? 'Player Customer').toString();
    final customerPhone = (booking['customerPhone'] ?? booking['userPhone'] ?? '').toString();
    final sport = (booking['sport'] ?? 'Football').toString();
    final courtName = (booking['courtName'] ?? 'Main Arena').toString();
    final date = (booking['date'] ?? '').toString();
    final timeSlot = (booking['timeSlot'] ?? '').toString();
    final amount = booking['amount'] ?? 1200;
    final paymentMethod = (booking['paymentMethod'] ?? 'UPI (GPay)').toString();

    return jsonEncode({
      'app': 'GAMES24',
      'type': 'TICKET_PASS',
      'bookingId': bookingId,
      'turfId': turfId,
      'turfName': turfName,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'sport': sport,
      'courtName': courtName,
      'date': date,
      'timeSlot': timeSlot,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'status': 'Confirmed',
      'issuedAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final bookingId = (booking['id'] ?? booking['bookingId'] ?? 'BK-G24').toString();
    final turfName = (booking['turfName'] ?? booking['courtName'] ?? 'Turf Arena').toString();
    final customerName = (booking['customerName'] ?? booking['userName'] ?? 'Player Customer').toString();
    final sport = (booking['sport'] ?? 'Football').toString();
    final courtName = (booking['courtName'] ?? 'Main Arena').toString();
    final dateStr = (booking['date'] ?? '').toString();
    final timeSlot = (booking['timeSlot'] ?? '').toString();
    final amount = (booking['amount'] ?? 1200).toString();
    final paymentMethod = (booking['paymentMethod'] ?? 'UPI').toString();

    final isCricket = sport.toLowerCase().contains('cricket');

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Top Status Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 14),
                  SizedBox(width: 5),
                  Text(
                    'OFFICIAL GATE ENTRY PASS',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF166534),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Ticket Board Card
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Ticket Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0C2B1E), Color(0xFF166534)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(19)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            isCricket ? '🏏' : '⚽',
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                turfName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '$sport • $courtName',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFBBF24),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            bookingId,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF78350F),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // QR Code Frame
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: QrImageView(
                            data: qrPayload,
                            version: QrVersions.auto,
                            size: 190.0,
                            backgroundColor: Colors.white,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: Color(0xFF166534),
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Color(0xFF0C2B1E),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.qr_code_scanner_rounded, size: 14, color: Color(0xFF166534)),
                            SizedBox(width: 5),
                            Text(
                              'Present this QR at turf gate for check-in',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF166534),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Perforated Divider
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: List.generate(
                        30,
                        (index) => Expanded(
                          child: Container(
                            height: 1.5,
                            color: index % 2 == 0 ? const Color(0xFFCBD5E1) : Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Booking Ticket Details
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildDetailRow('Passholder', customerName, Icons.person_rounded),
                        const SizedBox(height: 8),
                        _buildDetailRow('Date', dateStr, Icons.calendar_today_rounded),
                        const SizedBox(height: 8),
                        _buildDetailRow('Time Slot', timeSlot, Icons.access_time_rounded),
                        const SizedBox(height: 8),
                        _buildDetailRow('Payment Mode', '₹$amount • Paid Online ($paymentMethod)', Icons.verified_rounded, isSuccess: true),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Close Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF166534),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Done / Back to Bookings',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, {bool isSuccess = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: isSuccess ? const Color(0xFF16A34A) : const Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: isSuccess ? const Color(0xFF166534) : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}

