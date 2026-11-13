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

  static String formatBookingId(dynamic raw) {
    if (raw == null) return 'G24-BK-0001';
    final str = raw.toString().trim();
    if (str.startsWith('G24-BK-')) return str;
    final numMatch = RegExp(r'(\d+)').allMatches(str).toList();
    if (numMatch.isNotEmpty) {
      final lastMatch = numMatch.last.group(0)!;
      return 'G24-BK-${lastMatch.padLeft(4, '0')}';
    }
    return 'G24-BK-$str';
  }

  String get displayBookingId {
    if (booking['bookingCode'] != null && booking['bookingCode'].toString().isNotEmpty) {
      return booking['bookingCode'].toString();
    }
    if (booking['bookingId'] != null && booking['bookingId'].toString().isNotEmpty) {
      return formatBookingId(booking['bookingId']);
    }
    return formatBookingId(booking['id']);
  }

  String get qrPayload {
    final bookingId = displayBookingId;
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
      'bookingCode': bookingId,
      'numericId': booking['id'],
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

  Map<String, dynamic>? _getBookingWindow(String dateStr, String timeSlot) {
    try {
      if (dateStr.trim().isEmpty || timeSlot.trim().isEmpty) return null;
      final dateParts = dateStr.trim().split(RegExp(r'[-/]'));
      if (dateParts.length < 3) return null;
      int? y, m, d;
      final p0 = int.tryParse(dateParts[0]);
      final p1 = int.tryParse(dateParts[1]);
      final p2 = int.tryParse(dateParts[2]);
      if (p0 == null || p1 == null || p2 == null) return null;
      if (p0 > 1000) {
        y = p0;
        m = p1;
        d = p2;
      } else if (p2 > 1000) {
        d = p0;
        m = p1;
        y = p2;
      } else {
        y = p0;
        m = p1;
        d = p2;
      }

      final subSlots = timeSlot
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      final firstSlot = subSlots.isNotEmpty ? subSlots.first : timeSlot;
      final lastSlot = subSlots.isNotEmpty ? subSlots.last : timeSlot;

      List<String> splitSlotRange(String s) {
        return s
            .split(RegExp(r'\s*[-–]\s*|\s+to\s+', caseSensitive: false))
            .map((p) => p.trim())
            .where((p) => p.isNotEmpty)
            .toList();
      }

      final startParts = splitSlotRange(firstSlot);
      final endParts = splitSlotRange(lastSlot);

      final startStr = startParts.isNotEmpty ? startParts.first : firstSlot;
      final endStr = endParts.length > 1
          ? endParts.last
          : (startParts.length > 1 ? startParts.last : null);

      bool hasPm(String s) => s.toLowerCase().contains('pm');
      bool hasAm(String s) => s.toLowerCase().contains('am');

      final endHasPm = endStr != null && hasPm(endStr);
      final startHasExplicitAmPm = hasPm(startStr) || hasAm(startStr);

      bool inheritPmForStart = false;
      if (endHasPm && !startHasExplicitAmPm) {
        final startDigit = int.tryParse(
            startStr.replaceAll(RegExp(r'[^\d:]'), '').split(':').first);
        final endDigit = int.tryParse(endStr
            .replaceAll(RegExp(r'[^\d:]'), '')
            .split(':')
            .first);
        if (startDigit != null && endDigit != null) {
          if (startDigit <= endDigit || endDigit == 12) {
            inheritPmForStart = true;
          }
        }
      }

      TimeOfDay? parseTod(String str, bool inheritPm) {
        bool isPm = hasPm(str);
        bool isAm = hasAm(str);
        if (!isPm && !isAm && inheritPm) {
          isPm = true;
        }

        final digits = str.replaceAll(RegExp(r'[^\d:]'), '');
        final parts = digits.split(':');
        if (parts.isEmpty) return null;
        var h = int.tryParse(parts[0]);
        final min = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
        if (h == null) return null;

        if (!isPm && !isAm) {
          if (h >= 1 && h <= 7) {
            h += 12;
          }
        } else {
          if (isPm && h < 12) h += 12;
          if (isAm && h == 12) h = 0;
        }

        return TimeOfDay(hour: h, minute: min);
      }

      final startTod = parseTod(startStr, inheritPmForStart);
      if (startTod == null) return null;
      final startDt = DateTime(y, m, d, startTod.hour, startTod.minute);
      DateTime endDt;
      final endTod = endStr != null ? parseTod(endStr, false) : null;
      if (endTod != null) {
        endDt = DateTime(y, m, d, endTod.hour, endTod.minute);
        if (endDt.isBefore(startDt) || endDt.isAtSameMomentAs(startDt)) {
          endDt = endDt.add(const Duration(days: 1));
        }
      } else {
        endDt = startDt.add(const Duration(hours: 1));
      }

      final checkInOpensAt = startDt.subtract(const Duration(minutes: 20));
      final checkInClosesAt = endDt.add(const Duration(minutes: 30));

      String formatTod(DateTime dt) {
        var h = dt.hour;
        final min = dt.minute;
        final ampm = h >= 12 ? 'PM' : 'AM';
        h = h % 12;
        if (h == 0) h = 12;
        final mm = min.toString().padLeft(2, '0');
        final hh = h.toString().padLeft(2, '0');
        return '$hh:$mm $ampm';
      }

      return {
        'opensAtDt': checkInOpensAt,
        'closesAtDt': checkInClosesAt,
        'opensAtStr': formatTod(checkInOpensAt),
        'startStr': formatTod(startDt),
        'endStr': formatTod(endDt),
      };
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingId = displayBookingId;
    final turfName = (booking['turfName'] ?? booking['courtName'] ?? 'Turf Arena').toString();
    final customerName = (booking['customerName'] ?? booking['userName'] ?? 'Player Customer').toString();
    final sport = (booking['sport'] ?? 'Football').toString();
    final courtName = (booking['courtName'] ?? 'Main Arena').toString();
    final dateStr = (booking['date'] ?? '').toString();
    final timeSlot = (booking['timeSlot'] ?? '').toString();
    final amount = (booking['amount'] ?? 1200).toString();
    final paymentMethod = (booking['paymentMethod'] ?? 'UPI').toString();
    final bookingStatus = (booking['status'] ?? 'Confirmed').toString();

    final isCricket = sport.toLowerCase().contains('cricket');
    final isCheckedIn = bookingStatus.toLowerCase() == 'checked in';
    final window = _getBookingWindow(dateStr, timeSlot);
    final now = DateTime.now();

    final bool isBeforeWindow = window != null && now.isBefore(window['opensAtDt'] as DateTime);
    final String opensAtStr = window != null ? (window['opensAtStr'] as String) : '';

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

            // Dynamic Top Status Pill
            if (isCheckedIn)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 16),
                    SizedBox(width: 6),
                    Text(
                      'ENTRY VERIFIED & CHECKED IN',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF154D36),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              )
            else if (isBeforeWindow)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.schedule_rounded, color: Color(0xFFB45309), size: 15),
                    const SizedBox(width: 6),
                    Text(
                      'CHECK-IN OPENS AT $opensAtStr (20 MIN BEFORE)',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF92400E),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF16A34A), size: 16),
                    SizedBox(width: 6),
                    Text(
                      'GATE CHECK-IN OPEN NOW',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF154D36),
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
                        colors: [Color(0xFF0C2B1E), Color(0xFF154D36)],
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
                          child: Icon(
                            isCricket ? Icons.sports_cricket_rounded : Icons.sports_soccer_rounded,
                            color: Colors.white,
                            size: 20,
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
                              color: Color(0xFF154D36),
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Color(0xFF0C2B1E),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (isCheckedIn)
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_rounded, size: 15, color: Color(0xFF154D36)),
                              SizedBox(width: 6),
                              Text(
                                'Pass verified at gate. Enjoy your game!',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF154D36),
                                ),
                              ),
                            ],
                          )
                        else if (isBeforeWindow)
                          Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.hourglass_top_rounded, size: 14, color: Color(0xFFB45309)),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Check-in unlocks at $opensAtStr (20m before match)',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFB45309),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              const Text(
                                'Gate scan only verifies within 20m of start time • Single-use pass',
                                style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                              ),
                            ],
                          )
                        else
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.qr_code_scanner_rounded, size: 14, color: Color(0xFF154D36)),
                              SizedBox(width: 5),
                              Text(
                                'Present this QR at turf gate for check-in',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF154D36),
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
                        const SizedBox(height: 4),
                        _buildDetailRow('Date', dateStr, Icons.calendar_today_rounded),
                        const SizedBox(height: 4),
                        if (timeSlot.contains(',')) ...[
                          _buildDetailRow(
                            'Total Booked',
                            '${timeSlot.split(',').length} Slots Selected',
                            Icons.layers_rounded,
                          ),
                          ...timeSlot.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList().asMap().entries.map((entry) {
                            return _buildDetailRow(
                              'Slot ${entry.key + 1}',
                              entry.value,
                              Icons.access_time_rounded,
                            );
                          }),
                        ] else ...[
                          _buildDetailRow('Slot Duration', timeSlot, Icons.access_time_rounded),
                        ],
                        if (window != null && window['startStr'] != null) ...[
                          const SizedBox(height: 4),
                          _buildDetailRow('First Match Start', window['startStr'].toString(), Icons.play_circle_outline_rounded),
                        ],
                        if (window != null && window['endStr'] != null) ...[
                          const SizedBox(height: 4),
                          _buildDetailRow('Session Ends', window['endStr'].toString(), Icons.stop_circle_outlined),
                        ],
                        const SizedBox(height: 4),
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
                  backgroundColor: const Color(0xFF154D36),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: isSuccess ? const Color(0xFF16A34A) : const Color(0xFF64748B)),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isSuccess ? const Color(0xFF154D36) : const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

