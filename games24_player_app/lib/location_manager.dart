import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationManager {
  static final LocationManager _instance = LocationManager._internal();
  factory LocationManager() => _instance;

  LocationManager._internal() {
    loadLocation();
  }

  static const String _storageKey = 'user_selected_location';

  final ValueNotifier<String> locationNotifier =
      ValueNotifier<String>('All Madurai');

  String get currentLocation => locationNotifier.value;

  static const List<String> popularAreas = [
    'All Madurai',
    'Simmakkal',
    'KK Nagar',
    'Anna Nagar',
    'Mattuthavani',
    'Goripalayam',
    'Kalavasal',
    'Villapuram',
    'Teppakulam',
    'Thirunagar',
    'Koodal Nagar',
    'Othakadai',
    'Alagar Kovil Road',
    'Bypass Road',
  ];

  Future<void> loadLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_storageKey);
      if (saved != null && saved.trim().isNotEmpty) {
        locationNotifier.value = saved.trim();
      }
    } catch (_) {}
  }

  Future<void> setLocation(String newLocation) async {
    locationNotifier.value = newLocation.trim();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, newLocation.trim());
    } catch (_) {}
  }

  bool isMatchingLocation(String? itemLocation, [String? target]) {
    final selected = (target ?? currentLocation).trim().toLowerCase();
    if (selected.isEmpty ||
        selected == 'all' ||
        selected == 'all madurai' ||
        selected == 'madurai') {
      return true;
    }

    if (itemLocation == null || itemLocation.trim().isEmpty) return true;
    final item = itemLocation.trim().toLowerCase();

    return item.contains(selected) || selected.contains(item);
  }

  bool matchesTurf(Map<String, dynamic> turf, [String? target]) {
    final selected = (target ?? currentLocation).trim().toLowerCase();
    if (selected.isEmpty ||
        selected == 'all' ||
        selected == 'all madurai' ||
        selected == 'madurai') {
      return true;
    }

    final area = (turf['neighborhoodArea'] ?? '').toString().toLowerCase();
    final address = (turf['streetAddress'] ?? '').toString().toLowerCase();
    final loc = (turf['location'] ?? '').toString().toLowerCase();
    final combined = '$area $address $loc';

    return combined.contains(selected) ||
        (area.isNotEmpty && selected.contains(area));
  }

  static void showLocationPicker(BuildContext context, {VoidCallback? onSelected}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return _LocationPickerSheet(onSelected: onSelected);
      },
    );
  }
}

class _LocationPickerSheet extends StatefulWidget {
  final VoidCallback? onSelected;

  const _LocationPickerSheet({this.onSelected});

  @override
  State<_LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<_LocationPickerSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = LocationManager().currentLocation;
    final filtered = LocationManager.popularAreas.where((area) {
      if (_query.trim().isEmpty) return true;
      return area.toLowerCase().contains(_query.trim().toLowerCase());
    }).toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
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
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: Color(0xFF154D36),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Select Your Location',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),
                      Text(
                        'Discover nearby turfs & open challenge matches in Madurai',
                        style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search textfield
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF154D36), size: 20),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  hintText: 'Search locality / area in Madurai...',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Use GPS Location button
            InkWell(
              onTap: () {
                LocationManager().setLocation('Simmakkal');
                Navigator.pop(context);
                widget.onSelected?.call();
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.my_location_rounded, color: Color(0xFF154D36), size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Auto-Detect Current Area (GPS)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF154D36),
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF154D36)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            const Text(
              'POPULAR MADURAI LOCALITIES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF9CA3AF),
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 8),

            // Area List
            Expanded(
              child: ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFF3F4F6)),
                itemBuilder: (context, index) {
                  final area = filtered[index];
                  final isSelected = current.toLowerCase() == area.toLowerCase();

                  return Material(
                    color: Colors.transparent,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF154D36) : const Color(0xFFF3F4F6),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          area == 'All Madurai' ? Icons.map_rounded : Icons.location_on_outlined,
                          size: 16,
                          color: isSelected ? Colors.white : const Color(0xFF4B5563),
                        ),
                      ),
                      title: Text(
                        area,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? const Color(0xFF154D36) : const Color(0xFF1F2937),
                        ),
                      ),
                      subtitle: Text(
                        area == 'All Madurai' ? 'Shows all venues across city' : 'Madurai, Tamil Nadu',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle_rounded, color: Color(0xFF154D36), size: 20)
                          : const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 18),
                      onTap: () {
                        LocationManager().setLocation(area);
                        Navigator.pop(context);
                        widget.onSelected?.call();
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
