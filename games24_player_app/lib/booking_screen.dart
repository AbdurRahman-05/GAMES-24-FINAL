import 'package:flutter/material.dart';
import 'package:games24_player_app/challenge_manager.dart';

class BookingScreen extends StatefulWidget {
  final String turfName;
  final String imageUrl;
  final String price;
  final String location;
  final List<String> sports;

  const BookingScreen({
    super.key,
    required this.turfName,
    required this.imageUrl,
    required this.price,
    required this.location,
    required this.sports,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  int _selectedDateIndex = 1; // Default to 'Sat 11'
  String _selectedSport = 'Football';
  final Set<String> _selectedTimeSlots = {'05:00 PM'};
  bool _isOpenForChallenge = false;
  final TextEditingController _teamNameController = TextEditingController();

  @override
  void dispose() {
    _teamNameController.dispose();
    super.dispose();
  }

  final List<Map<String, String>> _dates = [
    {'day': 'Fri', 'date': '10'},
    {'day': 'Sat', 'date': '11'},
    {'day': 'Sun', 'date': '12'},
    {'day': 'Mon', 'date': '13'},
    {'day': 'Tue', 'date': '14'},
  ];

  final List<Map<String, dynamic>> _morningSlots = [
    {'time': '06:00 AM', 'status': 'available'},
    {'time': '07:00 AM', 'status': 'available'},
    {'time': '08:00 AM', 'status': 'booked'},
  ];

  final List<Map<String, dynamic>> _afternoonSlots = [
    {'time': '01:00 PM', 'status': 'booked'},
    {'time': '02:00 PM', 'status': 'available'},
    {'time': '03:00 PM', 'status': 'available'},
  ];

  final List<Map<String, dynamic>> _eveningSlots = [
    {'time': '04:00 PM', 'status': 'booked'},
    {'time': '05:00 PM', 'status': 'available'},
    {'time': '06:00 PM', 'status': 'available'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.sports.isNotEmpty) {
      _selectedSport = widget.sports.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.turfName,
          style: const TextStyle(
            color: Color(0xFF111827),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.black87),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Color(0xFFBE123C)),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroImage(),
            const SizedBox(height: 24),
            _buildDateSelector(),
            const SizedBox(height: 24),
            _buildSportSelector(),
            const SizedBox(height: 24),
            _buildTimeSlots(),
            const SizedBox(height: 24),
            _buildChallengeOption(),
            const SizedBox(height: 32),
            _buildBookingSummary(),
            const SizedBox(height: 100), // Space for bottom button
          ],
        ),
      ),
      bottomSheet: _buildBottomButton(),
    );
  }

  Widget _buildHeroImage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: DecorationImage(
            image: NetworkImage(widget.imageUrl),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.8),
              ],
            ),
          ),
          padding: const EdgeInsets.all(16),
          alignment: Alignment.bottomLeft,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF166534), // Dark Green
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.verified, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'Verified Turf • FIFA Certified Grass',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Downtown Sports Complex, Court 3',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Indoor • Floodlights • Changing Rooms Available',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Select Date',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
              ),
              Row(
                children: [
                  const Text(
                    'October 2024',
                    style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (picked != null) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Selected ${picked.day}/${picked.month}/${picked.year}')));
                      }
                    },
                    child: const Icon(Icons.calendar_month, color: Color(0xFF166534), size: 20),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 72,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _dates.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final date = _dates[index];
              final isSelected = _selectedDateIndex == index;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDateIndex = index;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 56,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF0F6D38) : const Color(0xFFF3F5F1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        date['day']!,
                        style: TextStyle(
                          fontSize: 13,
                          color: isSelected ? Colors.white70 : const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        date['date']!,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : const Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSportSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Select Sport',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 36,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: widget.sports.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final sport = widget.sports[index];
              final isSelected = _selectedSport == sport;
              IconData iconData = Icons.sports_soccer;
              if (sport.toLowerCase().contains('cricket')) iconData = Icons.sports_cricket;
              if (sport.toLowerCase().contains('badminton')) iconData = Icons.sports_tennis;
              if (sport.toLowerCase().contains('basketball')) iconData = Icons.sports_basketball;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedSport = sport;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF0F6D38) : const Color(0xFFF3F5F1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(iconData, size: 14, color: isSelected ? Colors.white : const Color(0xFF4B5563)),
                      const SizedBox(width: 6),
                      Text(
                        sport,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? Colors.white : const Color(0xFF4B5563),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSlots() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Available Slots',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
              ),
              Row(
                children: [
                  _buildLegendItem('Available', const Color(0xFFE5F5EB)),
                  const SizedBox(width: 8),
                  _buildLegendItem('Selected', const Color(0xFF0F6D38)),
                  const SizedBox(width: 8),
                  _buildLegendItem('Booked', const Color(0xFFD1D5DB)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSlotSection('MORNING', _morningSlots),
          const SizedBox(height: 16),
          _buildSlotSection('AFTERNOON', _afternoonSlots),
          const SizedBox(height: 16),
          _buildSlotSection('EVENING (PEAK)', _eveningSlots),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }

  Widget _buildSlotSection(String title, List<Map<String, dynamic>> slots) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF9CA3AF), letterSpacing: 1.0),
        ),
        const SizedBox(height: 12),
        Row(
          children: slots.map((slot) {
            final isBooked = slot['status'] == 'booked';
            final isSelected = _selectedTimeSlots.contains(slot['time']);
            
            Color bgColor = const Color(0xFFF3F5F1); // Available
            Color textColor = const Color(0xFF111827);
            Color borderColor = Colors.transparent;

            if (isBooked) {
              bgColor = const Color(0xFFFEE2E2); // Light red
              textColor = const Color(0xFFDC2626); // Red letters
            } else if (isSelected) {
              bgColor = const Color(0xFF0F6D38); // Dark Green
              textColor = Colors.white;
              borderColor = const Color(0xFF166534);
            }

            return Expanded(
              child: GestureDetector(
                onTap: isBooked ? null : () {
                  setState(() {
                    if (_selectedTimeSlots.contains(slot['time'])) {
                      _selectedTimeSlots.remove(slot['time']);
                    } else {
                      _selectedTimeSlots.add(slot['time']);
                    }
                  });
                },
                child: Container(
                  height: 52,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        slot['time'],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                      if (isBooked) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Booked',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildChallengeOption() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFBE123C).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.sports_kabaddi, color: Color(0xFFBE123C), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Open for Team Challenge',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Let other teams challenge you',
                        style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isOpenForChallenge,
                  activeColor: const Color(0xFF166534),
                  onChanged: (val) {
                    setState(() {
                      _isOpenForChallenge = val;
                    });
                  },
                ),
              ],
            ),
          ),
          if (_isOpenForChallenge) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: TextField(
                controller: _teamNameController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Enter Your Team Name',
                  hintStyle: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBookingSummary() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F5F1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFBBE5CA),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.receipt_long, color: Color(0xFF0F6D38), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Booking Summary',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                      ),
                      Text(
                        '${widget.turfName} • Court 3',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFBBE5CA),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_selectedTimeSlots.length}\nHour${_selectedTimeSlots.length != 1 ? 's' : ''}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF0F6D38), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSummaryRow('Date', 'Sat, Oct 11, 2024'),
            const SizedBox(height: 8),
            _buildSummaryRow('Time', _selectedTimeSlots.isEmpty ? 'None selected' : _selectedTimeSlots.join(', ')),
            const SizedBox(height: 8),
            _buildSummaryRow('Sport', _selectedSport),
            const SizedBox(height: 8),
            _buildSummaryRow('Subtotal', '₹${int.parse(widget.price.replaceAll(RegExp(r'[^0-9]'), '')) * _selectedTimeSlots.length}'),
            const SizedBox(height: 8),
            _buildSummaryRow('Taxes & Platform Fee', '₹90'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Final Total',
                  style: TextStyle(fontSize: 14, color: Color(0xFF4B5563)),
                ),
                Text(
                  '₹${int.parse(widget.price.replaceAll(RegExp(r'[^0-9]'), '')) * _selectedTimeSlots.length + 90}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F6D38),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 13, color: Color(0xFF111827), fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              if (_isOpenForChallenge) {
                if (_teamNameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter your team name')),
                  );
                  return;
                }
                final dateStr = _dates[_selectedDateIndex];
                final teamName = _teamNameController.text.trim();
                final initials = teamName.length >= 2 ? teamName.substring(0, 2).toUpperCase() : teamName.toUpperCase();
                ChallengeManager().addChallenge(
                  Challenge(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    turfName: widget.turfName,
                    date: '${dateStr['day']}, Oct ${dateStr['date']}',
                    time: _selectedTimeSlots.join(', '),
                    sport: _selectedSport,
                    challengerName: teamName,
                    challengerTeamInitials: initials,
                    challengerColor: const Color(0xFF166534),
                    isCreator: true,
                  ),
                );
              }
              if (_selectedTimeSlots.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one slot')));
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Booking Confirmed!')),
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF166534), // Dark Green
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Confirm Booking',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Text(
                  '- ₹${int.parse(widget.price.replaceAll(RegExp(r'[^0-9]'), '')) * _selectedTimeSlots.length + 90}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
