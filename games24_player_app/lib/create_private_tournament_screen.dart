import 'package:flutter/material.dart';
import 'package:games24_player_app/create_private_tournament_step2_screen.dart';

class CreatePrivateTournamentScreen extends StatefulWidget {
  const CreatePrivateTournamentScreen({super.key});

  @override
  State<CreatePrivateTournamentScreen> createState() => _CreatePrivateTournamentScreenState();
}

class _CreatePrivateTournamentScreenState extends State<CreatePrivateTournamentScreen> {
  String _selectedSport = 'Football';
  bool _rulesExpanded = true;

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
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Tournament Name'),
                  _buildTextField('e.g., Weekend Turf Clash Season 4'),
                  const SizedBox(height: 20),
                  
                  _buildLabel('Access Code / Tournament PIN'),
                  _buildTextFieldWithIcon('e.g., SECUREPIN2024', Icons.lock_outline),
                  const SizedBox(height: 20),
                  
                  _buildLabel('Select Sport'),
                  _buildSportSelector(),
                  const SizedBox(height: 20),
                  
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Prize Pool'),
                            _buildTextField('\$ 5,000 + Trophy'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Entry Fee'),
                            _buildTextField('\$ 50 / team'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Max Teams'),
                            _buildDropdown('16 Teams'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Match Date'),
                            _buildDateField('mm/dd/yyyy'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  _buildRulesSection(),
                  const SizedBox(height: 24),
                  
                  _buildVenueCard(),
                  const SizedBox(height: 32),
                  
                  _buildNextButton(),
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
      automaticallyImplyLeading: false, // We have a custom back button below
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
                'Create Private Tournament',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Invite-only & Secure',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
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
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTextField(String hint) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5F1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildTextFieldWithIcon(String hint, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5F1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
          prefixIcon: Icon(icon, color: const Color(0xFF6B7280), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildDropdown(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5F1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(value, style: const TextStyle(fontSize: 14, color: Colors.black87)),
          const Icon(Icons.keyboard_arrow_down, color: Colors.black87, size: 20),
        ],
      ),
    );
  }

  Widget _buildDateField(String hint) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5F1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(hint, style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
          const Icon(Icons.calendar_today_outlined, color: Colors.black87, size: 18),
        ],
      ),
    );
  }

  Widget _buildSportSelector() {
    return Row(
      children: [
        Expanded(child: _buildSportButton('Football', Icons.sports_soccer)),
        const SizedBox(width: 8),
        Expanded(child: _buildSportButton('Cricket', Icons.sports_cricket)),
        const SizedBox(width: 8),
        Expanded(child: _buildSportButton('Badminton', Icons.sports_tennis)),
      ],
    );
  }

  Widget _buildSportButton(String sport, IconData icon) {
    final isSelected = _selectedSport == sport;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSport = sport;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F6D38) : const Color(0xFFF3F5F1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.black87,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              sport,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRulesSection() {
    return Material(
      color: const Color(0xFFF3F5F1),
      borderRadius: BorderRadius.circular(16),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _rulesExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              _rulesExpanded = expanded;
            });
          },
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB).withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.rule, color: Color(0xFF166534), size: 20),
          ),
          title: const Text(
            'Private Tournament Rules',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          subtitle: const Text(
            'Secure access & organizer requirements\nReview standard tournament expectations',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
          iconColor: Colors.black87,
          collapsedIconColor: Colors.black87,
          childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          children: [
            _buildRuleCard(
              icon: Icons.key_outlined,
              title: 'Access Code Security',
              description: 'Do not share access codes publicly; only invited teams can join.',
            ),
            const SizedBox(height: 8),
            _buildRuleCard(
              icon: Icons.person_add_alt_1_outlined,
              title: 'Organizer Approval',
              description: 'Tournament creator manually approves all participating teams.',
            ),
            const SizedBox(height: 8),
            _buildRuleCard(
              icon: Icons.location_off_outlined,
              title: 'Confidential Venue',
              description: 'Exact venue coordinates and locker room details are revealed only after registration approval.',
            ),
            const SizedBox(height: 8),
            _buildRuleCard(
              icon: Icons.shield_outlined,
              title: 'Private Fair Play',
              description: 'Strict code of conduct applies to all invited guests and participants.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleCard({required IconData icon, required String title, required String description}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF166534)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVenueCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5F1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              'https://picsum.photos/seed/turf1/100/100',
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.location_on_outlined, size: 12, color: Color(0xFF166534)),
                    SizedBox(width: 4),
                    Text(
                      'Primary Venue Linked',
                      style: TextStyle(fontSize: 10, color: Color(0xFF166534), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Grand Arena Tur...',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                const Text(
                  'Downtown Sport...',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: const Text(
              'Change',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF166534),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreatePrivateTournamentStep2Screen()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0F6D38),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Next Step',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
