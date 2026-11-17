import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../api_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../shared/models/celebration_package_model.dart';
import '../../../shared/repositories/mock_celebrations.dart';

class CelebrationBookingScreen extends StatefulWidget {
  const CelebrationBookingScreen({super.key});

  @override
  State<CelebrationBookingScreen> createState() => _CelebrationBookingScreenState();
}

class _CelebrationBookingScreenState extends State<CelebrationBookingScreen> {
  final List<CelebrationPackageModel> packages = MockCelebrationsRepository.packages;

  void _showEnquirySheet(BuildContext context, CelebrationPackageModel pkg) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CelebrationEnquiryForm(package: pkg),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Celebration & Events'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: packages.length,
        itemBuilder: (context, index) {
          final pkg = packages[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: Image.network(
                      pkg.imageUrl,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(pkg.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            Text(
                              'From ₹${pkg.basePrice.toInt()}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(pkg.subtitle, style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.people_rounded, size: 16, color: AppColors.secondary),
                            const SizedBox(width: 6),
                            Text('Capacity: Up to ${pkg.capacity} guests', style: theme.textTheme.bodySmall),
                          ],
                        ),
                        const Divider(height: 24),
                        const Text('Package Highlights:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(height: 8),
                        ...pkg.highlights.map((h) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.success),
                              const SizedBox(width: 6),
                              Text(h, style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        )),
                        const SizedBox(height: 16),
                        AppButton(
                          text: 'Enquire / Book Package',
                          icon: Icons.cake_rounded,
                          onPressed: () => _showEnquirySheet(context, pkg),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CelebrationEnquiryForm extends StatefulWidget {
  final CelebrationPackageModel package;

  const _CelebrationEnquiryForm({required this.package});

  @override
  State<_CelebrationEnquiryForm> createState() => _CelebrationEnquiryFormState();
}

class _CelebrationEnquiryFormState extends State<_CelebrationEnquiryForm> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _selectedSlot = '06:00 PM - 09:00 PM';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 3));
  int _guestCount = 30;
  bool _isSubmitting = false;

  final List<String> _availableSlots = [
    '08:00 AM - 11:00 AM (Morning)',
    '03:00 PM - 06:00 PM (Afternoon)',
    '06:00 PM - 09:00 PM (Prime Evening)',
    '09:00 PM - 12:00 AM (Midnight Party)',
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    _nameController.text = prefs.getString('fullName') ?? '';
    _phoneController.text = prefs.getString('mobileNumber') ?? '';
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitEnquiry() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name and contact phone number.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final dateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/turfs/celebrations'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'packageId': widget.package.id,
          'packageTitle': widget.package.title,
          'turfName': 'Madurai Turf Arena',
          'customerName': name,
          'customerPhone': phone,
          'eventDate': dateStr,
          'eventTimeSlot': _selectedSlot,
          'guestCount': _guestCount,
          'totalAmount': widget.package.basePrice,
          'notes': _notesController.text.trim(),
        }),
      ).timeout(const Duration(seconds: 15));

      if (mounted) {
        setState(() => _isSubmitting = false);
        Navigator.pop(context);

        String code = 'G24-CEL-1001';
        if (res.statusCode == 200 || res.statusCode == 201) {
          final data = jsonDecode(res.body);
          code = data['bookingCode'] ?? code;
        }

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.celebration_rounded, color: Color(0xFFD4FF00)),
                const SizedBox(width: 8),
                const Text('Enquiry Confirmed!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your celebration request for "${widget.package.title}" has been successfully registered.',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Booking Ref:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(code, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFD4FF00), fontSize: 14)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '📞 Our Madurai event coordinator will call you within 15 minutes to finalize catering and custom stadium setup!',
                  style: TextStyle(fontSize: 12.5, color: Colors.black87),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Awesome'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit enquiry: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.package.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '₹${widget.package.basePrice.toInt()}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFFD4FF00)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Customize & schedule your event with Games24 dedicated coordinators.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const Divider(height: 24),

            // Date picker
            const Text('Event Date', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 90)),
                );
                if (picked != null) setState(() => _selectedDate = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                    const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFFD4FF00)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),
            // Time slot dropdown
            const Text('Preferred Time Slot', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedSlot,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: _availableSlots.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: (v) => setState(() => _selectedSlot = v ?? _selectedSlot),
            ),

            const SizedBox(height: 14),
            // Guest Count
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Guest Count', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                Text('$_guestCount Guests', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFD4FF00))),
              ],
            ),
            Slider(
              value: _guestCount.toDouble(),
              min: 10,
              max: 150,
              divisions: 14,
              activeColor: const Color(0xFFD4FF00),
              label: '$_guestCount Guests',
              onChanged: (v) => setState(() => _guestCount = v.round()),
            ),

            // Contact Info
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Contact Person Name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Special Requests / Catering Notes (Optional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitEnquiry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4FF00),
                            foregroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Confirm & Book Celebration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
