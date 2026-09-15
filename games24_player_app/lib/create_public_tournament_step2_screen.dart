import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

class CreatePublicTournamentStep2Screen extends StatefulWidget {
  const CreatePublicTournamentStep2Screen({super.key});

  @override
  State<CreatePublicTournamentStep2Screen> createState() => _CreatePublicTournamentStep2ScreenState();
}

class _CreatePublicTournamentStep2ScreenState extends State<CreatePublicTournamentStep2Screen> {
  bool _agreedToTerms = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildGlobalAppBar(),
      body: Column(
        children: [
          _buildSecondaryHeader(context),
          _buildProgressBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOverviewSection(),
                  const SizedBox(height: 32),
                  
                  _buildFinancialSection(),
                  const SizedBox(height: 32),
                  
                  _buildArenaSection(),
                  const SizedBox(height: 32),
                  
                  _buildRulesSummarySection(),
                  const SizedBox(height: 32),
                  
                  _buildTermsCheckbox(),
                  const SizedBox(height: 32),
                  
                  _buildCreateButton(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildGlobalAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false, // Custom back button used below
      title: const Text(
        'GAMES24',
        style: TextStyle(
          fontFamily: 'Delight',
          color: Color(0xFF166534), // Dark Green
          fontSize: 28,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.0,
          shadows: [
            Shadow(
              color: Colors.black12,
              offset: Offset(2, 2),
              blurRadius: 4,
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none_outlined, color: Colors.black87),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
        Container(
          width: 44,
          height: 44,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.green.shade200, width: 1.5),
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/logo.png', // Fallback to logo
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecondaryHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFF3F5F1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, size: 20, color: Colors.black87),
            ),
          ),
          Column(
            children: const [
              Text(
                'Create Public Tournament',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'STEP 2 OF 2 • REVIEW & CONFIRM',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: Color(0xFF166534), // Green text
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFF3F5F1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.help_outline, size: 20, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF166534),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF166534), // Also green for step 2
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE5F5EB),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'PUBLIC TOURNAMENT',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF166534),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F5F1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: const [
                  Text(
                    'Football',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.sports_soccer, size: 12, color: Colors.black87),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE5F5EB),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: const [
                  Icon(Icons.check_circle_outline, size: 12, color: Color(0xFF166534)),
                  SizedBox(width: 4),
                  Text(
                    'Instant Publish',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF166534),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Weekend Turf Clash Season 4',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F5F1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.calendar_month_outlined, size: 18, color: Color(0xFF166534)),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Match Date',
                        style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                      ),
                      Text(
                        'Sat, Oct 26, 2024',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F5F1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.account_tree_outlined, size: 18, color: Color(0xFF166534)),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Format',
                        style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                      ),
                      Text(
                        '16 Teams Knock...',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFinancialSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'Financial & Prize Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              'Currency: INR (₹)',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF3F5F1), width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Entry Fee',
                          style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5F5EB),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.payments_outlined, size: 16, color: Color(0xFF166534)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: const [
                        Text(
                          '₹500',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        Padding(
                          padding: EdgeInsets.only(bottom: 4.0, left: 2.0),
                          child: Text(
                            '/ team',
                            style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9F0), // Slight orange tint for grand prize
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFF0D4), width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Grand Prize',
                          style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEDD5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.emoji_events_outlined, size: 16, color: Color(0xFFD97706)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '₹10,000',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const Text(
                      '+ Trophy & Medals',
                      style: TextStyle(fontSize: 10, color: Color(0xFFD97706), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F5F1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.calculate_outlined, size: 18, color: Color(0xFF166534)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '16 Teams registered = ₹8,000 base pool',
                  style: TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Sponsor Boosted',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF166534),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildArenaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Allocated Arena',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Row(
              children: const [
                Text(
                  'Change Venue',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF166534),
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.edit, size: 12, color: Color(0xFF166534)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF3F5F1), width: 2),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  'https://picsum.photos/seed/turf1/100/100',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Grand Arena Turf',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Downtown Sports Complex • Court 3',
                      style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5F5EB),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.sports_soccer, size: 10, color: Color(0xFF166534)),
                              SizedBox(width: 4),
                              Text(
                                'FIFA Synthetic',
                                style: TextStyle(fontSize: 10, color: Color(0xFF166534)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.lightbulb_outline, size: 10, color: Color(0xFFD97706)),
                              SizedBox(width: 4),
                              Text(
                                'Floodlights',
                                style: TextStyle(fontSize: 10, color: Color(0xFFD97706)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRulesSummarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'Rules & Guidelines Summary',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              '5 configured',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildRuleItem('Reporting Time', '15 mins prior to kickoff time'),
        _buildRuleItem('Equipment', 'Proper turf boots & matching jerseys required'),
        _buildRuleItem('Fair Play', 'Zero tolerance policy for misconduct or abuse'),
        _buildRuleItem('Substitutions', 'Up to 5 rolling substitutions per match'),
        _buildRuleItem('Official Decision', 'Referee decision is final and binding'),
      ],
    );
  }

  Widget _buildRuleItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF166534), width: 1.5),
            ),
            child: const Icon(Icons.check, size: 10, color: Color(0xFF166534)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: description,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _agreedToTerms,
            onChanged: (value) {
              setState(() {
                _agreedToTerms = value ?? false;
              });
            },
            activeColor: const Color(0xFF166534),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), height: 1.4),
              children: [
                const TextSpan(text: 'I agree to '),
                TextSpan(
                  text: 'GAMES24 Public Tournament Terms & Guidelines',
                  style: const TextStyle(
                    color: Color(0xFF166534),
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()..onTap = () {
                    // Open terms
                  },
                ),
                const TextSpan(text: ', and confirm venue availability for all match slots.'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _agreedToTerms ? () {} : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF166534), // Dark Green
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF166534).withOpacity(0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Create Tournament 🚀',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
