import 'main_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/utils/toast_utils.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final TextEditingController _msgController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _msgController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ToastUtils.showSuccess(context, '$label copied to clipboard');
  }

  void _submitMessage() {
    final sub = _subjectController.text.trim();
    final msg = _msgController.text.trim();
    if (sub.isEmpty || msg.isEmpty) {
      ToastUtils.showError(context, 'Please enter subject and message');
      return;
    }

    setState(() => _isSending = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() => _isSending = false);
      _subjectController.clear();
      _msgController.clear();
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF181818),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF262626)),
          ),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Color(0xFFD4FF00)),
              SizedBox(width: 8),
              Text('Message Sent!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'Thank you for contacting Games24 Support! Our team has received your ticket and will respond to your registered mobile number shortly.',
            style: TextStyle(fontSize: 13, height: 1.4, color: Color(0xFFA1A1AA)),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4FF00),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('OK', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      appBar: AppBar(
        title: const Text(
          'Support & Help Center',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF080808),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Welcome Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF141414),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF262626)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1F2916),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.support_agent_rounded, color: Color(0xFFD4FF00), size: 28),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '24/7 Player Support',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Have an issue with a booking, payment, or turf? We are here to help!',
                          style: TextStyle(fontSize: 12, color: Color(0xFFA1A1AA), height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildSectionHeader('QUICK CONTACT CHANNELS'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildContactCard(
                    icon: Icons.phone_in_talk_rounded,
                    title: 'Helpline',
                    subtitle: '+91 98765 43210',
                    color: const Color(0xFFD4FF00),
                    onTap: () => _copyToClipboard('+919876543210', 'Helpline Number'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildContactCard(
                    icon: Icons.chat_rounded,
                    title: 'WhatsApp',
                    subtitle: 'Quick Chat',
                    color: const Color(0xFF22C55E),
                    onTap: () => _copyToClipboard('+919876543210', 'WhatsApp Contact'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildContactCard(
              icon: Icons.email_rounded,
              title: 'Email Support',
              subtitle: 'support@games24.com',
              color: const Color(0xFF38BDF8),
              onTap: () => _copyToClipboard('support@games24.com', 'Support Email'),
            ),
            const SizedBox(height: 24),

            _buildSectionHeader('FREQUENTLY ASKED QUESTIONS'),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF141414),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF262626)),
              ),
              child: Column(
                children: [
                  _buildFaqItem(
                    question: 'How do I cancel or reschedule a turf slot?',
                    answer: 'Navigate to "My Bookings" from the Profile or Home screen, tap your upcoming booking, and select "Cancel Booking". Bookings can be cancelled up to 3 hours before the slot starts; online payments are refunded in full to the original payment method.',
                  ),
                  const Divider(height: 1, color: Color(0xFF262626)),
                  _buildFaqItem(
                    question: 'How do Open Challenges work?',
                    answer: 'When booking a turf, toggle on "Open for Challenge". Your match will appear on the Home Screen for other teams to see and request to join. You can review and accept opponent requests right in the app!',
                  ),
                  const Divider(height: 1, color: Color(0xFF262626)),
                  _buildFaqItem(
                    question: 'Can I pay at the turf venue using cash?',
                    answer: 'Yes! During checkout on the booking screen, choose the "Pay at Turf (Cash)" payment option. The slot is held instantly, and you can pay the venue manager on arrival.',
                  ),
                  const Divider(height: 1, color: Color(0xFF262626)),
                  _buildFaqItem(
                    question: 'How do I create and manage a tournament team?',
                    answer: 'Open the "Teams" screen from Profile or Navigation, tap "Create Squad", choose your sport and squad format, and invite your teammates using your unique squad passcode.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionHeader('SEND US A MESSAGE'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF141414),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF262626)),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _subjectController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Subject (e.g. Booking issue, Refund query)',
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF71717A)),
                      filled: true,
                      fillColor: const Color(0xFF1E1E1E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF262626)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF262626)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFD4FF00)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _msgController,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Describe your issue in detail...',
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF71717A)),
                      filled: true,
                      fillColor: const Color(0xFF1E1E1E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF262626)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF262626)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFD4FF00)),
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSending ? null : _submitMessage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4FF00),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isSending
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                          : const Text('Send Message', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Color(0xFFA1A1AA),
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF262626)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFFA1A1AA)), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem({required String question, required String answer}) {
    return ExpansionTile(
      iconColor: const Color(0xFFD4FF00),
      collapsedIconColor: const Color(0xFFA1A1AA),
      title: Text(
        question,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
      ),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        Text(
          answer,
          style: const TextStyle(fontSize: 12, height: 1.4, color: Color(0xFFA1A1AA)),
        ),
      ],
    );
  }
}
