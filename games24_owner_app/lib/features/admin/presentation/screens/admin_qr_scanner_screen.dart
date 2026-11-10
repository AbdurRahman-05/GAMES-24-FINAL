import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../api_config.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../providers/admin_providers.dart';

class AdminQrScannerScreen extends ConsumerStatefulWidget {
  const AdminQrScannerScreen({super.key});

  @override
  ConsumerState<AdminQrScannerScreen> createState() =>
      _AdminQrScannerScreenState();
}

class _AdminQrScannerScreenState extends ConsumerState<AdminQrScannerScreen>
    with SingleTickerProviderStateMixin {
  late final MobileScannerController _scannerController;
  late final AnimationController _animController;
  late final Animation<double> _scanAnimation;
  final TextEditingController _manualPassIdController = TextEditingController();

  bool _isProcessing = false;
  bool _isTorchOn = false;
  Map<String, dynamic>? _scannedResult;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0.05, end: 0.95).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _scannerController.dispose();
    _manualPassIdController.dispose();
    super.dispose();
  }

  Future<void> _handleBarcodeDetected(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    for (final barcode in barcodes) {
      final raw = barcode.rawValue;
      if (raw != null && raw.trim().isNotEmpty) {
        await _processCheckIn(raw.trim());
        break;
      }
    }
  }

  Future<void> _processCheckIn(String tokenOrBookingId) async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    HapticFeedback.mediumImpact();

    try {
      final profile = ref.read(turfProfileProvider);
      final adminId = profile.verifiedAdminId ?? profile.adminUserId ?? 1;

      String resolvedBookingId = tokenOrBookingId.trim();
      try {
        final parsed = jsonDecode(tokenOrBookingId);
        if (parsed is Map) {
          resolvedBookingId = (parsed['bookingCode'] ?? parsed['bookingId'] ?? parsed['id'])?.toString() ?? resolvedBookingId;
        }
      } catch (_) {}

      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/turfs/$adminId/check-in'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'ticketToken': tokenOrBookingId,
          'bookingId': resolvedBookingId,
          'rawCode': tokenOrBookingId,
        }),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 || res.statusCode == 201) {
        setState(() {
          _scannedResult = data['booking'] != null
              ? Map<String, dynamic>.from(data['booking'])
              : {'id': resolvedBookingId, 'bookingCode': resolvedBookingId, 'status': 'Checked In'};
          _isProcessing = false;
        });

        // Trigger dashboard profile reload to update check-in stats
        if (profile.ownerPhone.isNotEmpty) {
          ref
              .read(turfProfileProvider.notifier)
              .fetchVerifiedAdminByPhone(profile.ownerPhone);
        }

        if (mounted) {
          ToastUtils.showSuccess(
            context,
            data['message'] ?? 'Ticket Pass Verified & Checked In! 🎟️',
          );
        }
      } else {
        setState(() {
          _errorMessage = data['message'] ?? 'Invalid or unverified ticket pass.';
          _isProcessing = false;
        });
        if (mounted) {
          ToastUtils.showError(
            context,
            data['message'] ?? 'Check-in validation failed.',
          );
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network connection error: $e';
        _isProcessing = false;
      });
      if (mounted) {
        ToastUtils.showError(context, 'Unable to connect to check-in server.');
      }
    }
  }

  void _resetScanner() {
    setState(() {
      _scannedResult = null;
      _errorMessage = null;
      _manualPassIdController.clear();
      _isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(turfProfileProvider);
    final activeBookings = profile.bookingHistory
        .where((b) => !b.isCancelled)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C2B1E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gate Entry QR Scanner',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'Realtime Player Pass Verification',
              style: TextStyle(
                color: Color(0xFF86EFAC),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Toggle Flashlight',
            icon: Icon(
              _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: _isTorchOn ? const Color(0xFFFBBF24) : Colors.white70,
            ),
            onPressed: () {
              _scannerController.toggleTorch();
              setState(() => _isTorchOn = !_isTorchOn);
            },
          ),
          IconButton(
            tooltip: 'Switch Camera',
            icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white),
            onPressed: () => _scannerController.switchCamera(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Scanner Viewfinder Card
            _buildScannerBox(),
            const SizedBox(height: 16),

            // Scan Result or Error Feedback Card
            if (_scannedResult != null)
              _buildVerificationResultCard(_scannedResult!)
            else if (_errorMessage != null)
              _buildErrorFeedbackCard(_errorMessage!)
            else ...[
              // Manual ID Entry Fallback Card
              _buildManualEntryCard(),
              const SizedBox(height: 20),

              // Quick Check-In List from Today's Bookings
              _buildTodayBookingsList(activeBookings),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScannerBox() {
    return Container(
      height: 260,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF154D36), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Live Camera Stream
          MobileScanner(
            controller: _scannerController,
            onDetect: _handleBarcodeDetected,
            errorBuilder: (context, error) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.videocam_off_rounded, color: Colors.white54, size: 40),
                      const SizedBox(height: 8),
                      Text(
                        'Camera unavailable on this device\nUse manual Ticket ID entry below',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Viewfinder Framing Overlay
          Center(
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _isProcessing ? const Color(0xFFFBBF24) : const Color(0xFF22C55E),
                  width: 2.5,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          // Animated Laser Scan Bar
          if (!_isProcessing && _scannedResult == null)
            AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return Positioned(
                  top: 35 + (_scanAnimation.value * 190),
                  left: 45,
                  right: 45,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF22C55E).withValues(alpha: 0.8),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

          // Processing Indicator
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.65),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF22C55E)),
                    SizedBox(height: 12),
                    Text(
                      'Validating Ticket Pass...',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),

          // Scanner Hint Pill
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.qr_code_scanner_rounded, size: 14, color: Color(0xFF86EFAC)),
                    SizedBox(width: 6),
                    Text(
                      'Align QR code inside box to check in',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualEntryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.pin_rounded, size: 16, color: Color(0xFF154D36)),
              SizedBox(width: 6),
              Text(
                'Manual Pass Verification',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _manualPassIdController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'Enter Pass ID (e.g. G24-BK-0001)',
                    hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF154D36), width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF154D36),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  final text = _manualPassIdController.text.trim();
                  if (text.isNotEmpty) {
                    _processCheckIn(text);
                  }
                },
                icon: const Icon(Icons.verified_user_rounded, size: 16),
                label: const Text('Verify', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationResultCard(Map<String, dynamic> booking) {
    final bookingId = booking['bookingCode']?.toString() ??
        booking['bookingId']?.toString() ??
        (booking['id'] != null ? 'G24-BK-${booking['id'].toString().padLeft(4, '0')}' : 'G24-BK-0001');
    final customer = booking['customerName']?.toString() ?? 'Player Customer';
    final phone = booking['customerPhone']?.toString() ?? '';
    final sport = booking['sport']?.toString() ?? 'Football';
    final court = booking['courtName']?.toString() ?? 'Main Turf Arena';
    final date = booking['date']?.toString() ?? '';
    final timeSlot = booking['timeSlot']?.toString() ?? '';
    final amount = booking['amount']?.toString() ?? '1200';
    final status = booking['status']?.toString() ?? 'Checked In';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF16A34A).withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFF16A34A),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ENTRY GRANTED ✅',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF15803D),
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'Status: $status • Valid Pass',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF166534), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '#$bookingId',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF15803D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFBBF7D0)),
          const SizedBox(height: 14),

          _buildDetailRow('Customer Name', customer),
          if (phone.isNotEmpty) _buildDetailRow('Contact Phone', phone),
          _buildDetailRow('Sport', sport),
          _buildDetailRow('Court / Arena', court),
          _buildDetailRow('Date & Slot', '$date • $timeSlot'),
          _buildDetailRow('Amount Paid', '₹$amount (Confirmed)'),

          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF154D36),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _resetScanner,
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
              label: const Text('Scan Next Ticket', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorFeedbackCard(String msg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  msg,
                  style: const TextStyle(
                    color: Color(0xFF991B1B),
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFDC2626),
                side: const BorderSide(color: Color(0xFFDC2626)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _resetScanner,
              child: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
        ],
      ),
    );
  }

  Widget _buildTodayBookingsList(List<TurfBookingHistoryItem> bookings) {
    if (bookings.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Quick Check-In (Recent Bookings)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              '${bookings.length} Available',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: bookings.length > 5 ? 5 : bookings.length,
          separatorBuilder: (ctx, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final b = bookings[index];
            final isCheckedIn = b.status.toLowerCase() == 'checked in';

            return InkWell(
              onTap: () => _processCheckIn(b.id),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCheckedIn ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isCheckedIn ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCheckedIn ? Icons.check_circle_rounded : Icons.confirmation_number_rounded,
                        size: 16,
                        color: isCheckedIn ? const Color(0xFF16A34A) : const Color(0xFF154D36),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                b.customerName,
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  b.id,
                                  style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${b.sport} • ${b.effectiveTimeSlot}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isCheckedIn ? const Color(0xFFDCFCE7) : const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isCheckedIn ? 'Checked In' : 'Tap Check-In',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isCheckedIn ? const Color(0xFF15803D) : Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
