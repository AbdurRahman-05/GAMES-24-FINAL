import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'match_score_manager.dart';

class ContactsPickerSheet extends StatefulWidget {
  final List<PlayerItem> alreadySelected;
  final String sport;
  final ValueChanged<List<PlayerItem>> onImport;

  const ContactsPickerSheet({
    super.key,
    required this.alreadySelected,
    this.sport = 'Football',
    required this.onImport,
  });

  static void show(
    BuildContext context, {
    required List<PlayerItem> alreadySelected,
    String sport = 'Football',
    required ValueChanged<List<PlayerItem>> onImport,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ContactsPickerSheet(
        alreadySelected: alreadySelected,
        sport: sport,
        onImport: onImport,
      ),
    );
  }

  @override
  State<ContactsPickerSheet> createState() => _ContactsPickerSheetState();
}

class _ContactsPickerSheetState extends State<ContactsPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedIds = {};
  final Map<String, String> _customRoles = {};
  List<PlayerItem> _contacts = [];
  String _filter = 'All'; // 'All', 'Physical', 'Selected'

  bool _isLoading = true;
  bool _permissionDenied = false;
  bool _isPermanentlyDenied = false;
  int _physicalCount = 0;

  @override
  void initState() {
    super.initState();
    _loadContacts(requestPermission: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts({bool requestPermission = true}) async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    List<PlayerItem> physicalList = [];
    bool hasPermission = false;

    try {
      if (requestPermission) {
        final status = await FlutterContacts.permissions.request(PermissionType.read);
        hasPermission = (status == PermissionStatus.granted || status == PermissionStatus.limited);
        _isPermanentlyDenied = (status == PermissionStatus.permanentlyDenied);
      } else {
        hasPermission = await FlutterContacts.permissions.has(PermissionType.read);
      }

      if (hasPermission) {
        final deviceContacts = await FlutterContacts.getAll(
          properties: {ContactProperty.name, ContactProperty.phone},
        );

        final Set<String> seen = {};
        for (final c in deviceContacts) {
          final name = (c.displayName != null && c.displayName!.trim().isNotEmpty)
              ? c.displayName!.trim()
              : ('${c.name?.first ?? ''} ${c.name?.last ?? ''}').trim();
          if (name.isEmpty) continue;

          for (final ph in c.phones) {
            final raw = ph.number.trim();
            final norm = raw.replaceAll(RegExp(r'[^0-9+]'), '');
            if (norm.length >= 7 && !seen.contains(norm)) {
              seen.add(norm);
              physicalList.add(PlayerItem(
                id: 'contact_ph_${c.id ?? physicalList.length}',
                name: name,
                phone: raw,
                role: _getDefaultRoleForSport(widget.sport),
                isPhysicalContact: true,
              ));
              break;
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching physical contacts: $e");
    }

    _permissionDenied = !hasPermission;
    _physicalCount = physicalList.length;

    // Load any custom contacts saved locally
    List<PlayerItem> customList = [];
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedStr = prefs.getString('custom_mobile_contacts');
      if (savedStr != null && savedStr.isNotEmpty) {
        final List list = jsonDecode(savedStr);
        customList = list
            .map((e) => PlayerItem.fromJson(Map<String, dynamic>.from(e)))
            .where((p) => !MatchScoreManager.isDemoPlayer(p))
            .toList();
      }
    } catch (e) {
      debugPrint("Error loading custom contacts: $e");
    }

    final combined = <PlayerItem>[];
    final Set<String> addedPhones = {};

    // 1. Add physical device contacts first
    for (final c in physicalList) {
      final norm = c.phone.replaceAll(RegExp(r'[^0-9+]'), '');
      if (!addedPhones.contains(norm)) {
        addedPhones.add(norm);
        combined.add(c);
      }
    }

    // 2. Add saved custom contacts
    for (final c in customList) {
      final norm = c.phone.replaceAll(RegExp(r'[^0-9+]'), '');
      if (!addedPhones.contains(norm)) {
        addedPhones.add(norm);
        combined.add(c);
      }
    }

    if (mounted) {
      setState(() {
        _contacts = combined;
        _isLoading = false;
        for (final p in widget.alreadySelected) {
          final found = _contacts.firstWhere(
            (c) =>
                c.phone.replaceAll(RegExp(r'[^0-9+]'), '') ==
                    p.phone.replaceAll(RegExp(r'[^0-9+]'), '') ||
                c.name.toLowerCase() == p.name.toLowerCase(),
            orElse: () => p,
          );
          _selectedIds.add(found.id);
          _customRoles[found.id] = p.role;
        }
      });
    }
  }

  /// Opens the native physical phone contact picker UI
  Future<void> _pickNativeContact() async {
    try {
      final c = await FlutterContacts.native.showPicker(
        properties: {ContactProperty.name, ContactProperty.phone},
      );
      if (c != null) {
        final name = (c.displayName != null && c.displayName!.trim().isNotEmpty)
            ? c.displayName!.trim()
            : ('${c.name?.first ?? ''} ${c.name?.last ?? ''}').trim();
        final phone = c.phones.isNotEmpty ? c.phones.first.number.trim() : '';

        if (name.isNotEmpty && phone.isNotEmpty) {
          final newItem = PlayerItem(
            id: 'native_${c.id ?? DateTime.now().millisecondsSinceEpoch}',
            name: name,
            phone: phone,
            role: _getDefaultRoleForSport(widget.sport),
            isPhysicalContact: true,
          );

          await _saveCustomContact(newItem);

          if (!mounted) return;
          setState(() {
            _contacts.removeWhere((item) =>
                item.phone.replaceAll(RegExp(r'[^0-9+]'), '') ==
                phone.replaceAll(RegExp(r'[^0-9+]'), ''));
            _contacts.insert(0, newItem);
            _selectedIds.add(newItem.id);
            _customRoles[newItem.id] = newItem.role;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Imported "$name" ($phone) from phone!'),
                backgroundColor: const Color(0xFFD4FF00),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Selected contact does not have a valid phone number.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Error opening native contact picker: $e");
      _showAddManualContactDialog();
    }
  }

  Future<void> _saveCustomContact(PlayerItem item) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedStr = prefs.getString('custom_mobile_contacts');
      List<PlayerItem> custom = [];
      if (savedStr != null && savedStr.isNotEmpty) {
        final List list = jsonDecode(savedStr);
        custom = list
            .map((e) => PlayerItem.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      custom.removeWhere((c) =>
          c.phone.replaceAll(RegExp(r'[^0-9+]'), '') ==
          item.phone.replaceAll(RegExp(r'[^0-9+]'), ''));
      custom.insert(0, item);
      await prefs.setString(
        'custom_mobile_contacts',
        jsonEncode(custom.map((c) => c.toJson()).toList()),
      );
    } catch (e) {
      debugPrint("Error saving custom contact: $e");
    }
  }

  void _showAddManualContactDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String role = _getDefaultRoleForSport(widget.sport);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: const Color(0xFF141414),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFF262626))),
          title: const Row(
            children: [
              Icon(Icons.person_add_alt_1, color: Color(0xFFD4FF00)),
              SizedBox(width: 8),
              Text('Add New Teammate', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Full Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 6),
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'e.g. Rahul Sharma',
                  hintStyle: const TextStyle(color: Color(0xFF71717A)),
                  filled: true,
                  fillColor: const Color(0xFF1F1F1F),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF262626))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF262626))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFD4FF00))),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Phone Number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 6),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: '+91 98765 43210',
                  hintStyle: const TextStyle(color: Color(0xFF71717A)),
                  filled: true,
                  fillColor: const Color(0xFF1F1F1F),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF262626))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF262626))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFD4FF00))),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Squad Role', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: role,
                dropdownColor: const Color(0xFF1F1F1F),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF1F1F1F),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF262626))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF262626))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFD4FF00))),
                ),
                items: _getRoleOptionsForSport(widget.sport)
                    .map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 13, color: Colors.white))))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setDlgState(() => role = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFFA1A1AA))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4FF00),
                foregroundColor: Colors.black,
              ),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final phone = phoneCtrl.text.trim();
                if (name.isEmpty || phone.isEmpty) return;

                final newContact = PlayerItem(
                  id: 'contact_${DateTime.now().millisecondsSinceEpoch}',
                  name: name,
                  phone: phone,
                  role: role,
                  isPhysicalContact: false,
                );

                await _saveCustomContact(newContact);
                if (ctx.mounted) Navigator.pop(ctx);
                if (!mounted) return;

                setState(() {
                  _contacts.insert(0, newContact);
                  _selectedIds.add(newContact.id);
                  _customRoles[newContact.id] = role;
                });
              },
              child: const Text('Add & Select', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }

  String _getDefaultRoleForSport(String sport) {
    final s = sport.toLowerCase();
    if (s.contains('cricket')) return 'All-Rounder';
    if (s.contains('badminton') || s.contains('tennis')) return 'Player';
    return 'Striker';
  }

  List<String> _getRoleOptionsForSport(String sport) {
    final s = sport.toLowerCase();
    if (s.contains('cricket')) {
      return ['Captain', 'Vice Captain', 'Batsman', 'Fast Bowler', 'Spinner', 'Wicket Keeper', 'All-Rounder'];
    }
    if (s.contains('badminton') || s.contains('tennis') || s.contains('pickle')) {
      return ['Captain', 'Partner', 'Singles Player', 'Doubles Specialist'];
    }
    return ['Captain', 'Vice Captain', 'Striker', 'Winger', 'Midfielder', 'Defender', 'Goalkeeper'];
  }

  void _showRolePickerForContact(PlayerItem contact) {
    final roles = _getRoleOptionsForSport(widget.sport);
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Role for ${contact.name}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
              ),
              const Divider(height: 24, color: Color(0xFF262626)),
              ...roles.map((r) => ListTile(
                    title: Text(r, style: const TextStyle(color: Colors.white, fontSize: 14)),
                    trailing: (_customRoles[contact.id] ?? contact.role) == r
                        ? const Icon(Icons.check, color: Color(0xFFD4FF00))
                        : null,
                    onTap: () {
                      setState(() {
                        _customRoles[contact.id] = r;
                      });
                      Navigator.pop(ctx);
                    },
                  )),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = _contacts.where((c) {
      if (query.isNotEmpty) {
        final matchesName = c.name.toLowerCase().contains(query);
        final matchesPhone = c.phone.replaceAll(' ', '').contains(query.replaceAll(' ', ''));
        if (!matchesName && !matchesPhone) return false;
      }
      if (_filter == 'Selected') {
        return _selectedIds.contains(c.id);
      }
      if (_filter == 'Physical') {
        return c.isPhysicalContact;
      }
      return true;
    }).toList();

    final selectedCount = _selectedIds.length;
    final physicalCount = _contacts.where((c) => c.isPhysicalContact).length;

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: Color(0xFF141414),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF333333),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Top title bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 16, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F2916),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.phone_android_rounded, color: Color(0xFFD4FF00), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Import Phone Contacts',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          _isLoading
                              ? 'Connecting to phone contacts...'
                              : '$physicalCount physical device contact${physicalCount == 1 ? '' : 's'} available',
                          style: const TextStyle(fontSize: 11, color: Color(0xFFA1A1AA)),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF262626)),

          // Permission banner / Status indicator
          if (_permissionDenied)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2A1515),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF5C2424)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Contacts Permission Needed',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFFCA5A5)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isPermanentlyDenied
                              ? 'Permission denied. Open App Settings to enable contact reading.'
                              : 'Grant access to view and import your real phone contacts.',
                          style: const TextStyle(fontSize: 11, color: Color(0xFFF87171)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      if (_isPermanentlyDenied) {
                        await FlutterContacts.permissions.openSettings();
                      } else {
                        await _loadContacts(requestPermission: true);
                      }
                    },
                    child: Text(
                      _isPermanentlyDenied ? 'Settings' : 'Grant',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1F2916),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF2E4020)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFFD4FF00), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _physicalCount > 0
                          ? 'Physical device contacts synced ($_physicalCount contacts ready)'
                          : 'Contacts access granted. You can also pick directly from your phone.',
                      style: const TextStyle(fontSize: 11, color: Color(0xFFD4FF00), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

          // Two Primary Action Buttons: Native System Contact Picker & Add Custom
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4FF00),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _pickNativeContact,
                    icon: const Icon(Icons.contacts_rounded, size: 16, color: Colors.black),
                    label: const Text(
                      'Open Phone Book',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.black),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFD4FF00),
                      side: const BorderSide(color: Color(0xFFD4FF00)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _showAddManualContactDialog,
                    icon: const Icon(Icons.person_add_alt, size: 16),
                    label: const Text(
                      '+ Add New',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search contacts by name or phone...',
                hintStyle: const TextStyle(color: Color(0xFF71717A)),
                prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFFA1A1AA)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18, color: Color(0xFFA1A1AA)),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF1F1F1F),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF262626)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF262626)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFD4FF00)),
                ),
              ),
            ),
          ),

          // Quick filter pills
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                FilterChip(
                  label: Text('All (${_contacts.length})'),
                  selected: _filter == 'All',
                  selectedColor: const Color(0xFFD4FF00),
                  backgroundColor: const Color(0xFF1E1E1E),
                  side: BorderSide(color: _filter == 'All' ? const Color(0xFFD4FF00) : const Color(0xFF262626)),
                  labelStyle: TextStyle(
                    fontSize: 11,
                    color: _filter == 'All' ? Colors.black : const Color(0xFFA1A1AA),
                    fontWeight: _filter == 'All' ? FontWeight.w900 : FontWeight.normal,
                  ),
                  onSelected: (_) => setState(() => _filter = 'All'),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text('Device ($physicalCount)'),
                  selected: _filter == 'Physical',
                  selectedColor: const Color(0xFFD4FF00),
                  backgroundColor: const Color(0xFF1E1E1E),
                  side: BorderSide(color: _filter == 'Physical' ? const Color(0xFFD4FF00) : const Color(0xFF262626)),
                  labelStyle: TextStyle(
                    fontSize: 11,
                    color: _filter == 'Physical' ? Colors.black : const Color(0xFFA1A1AA),
                    fontWeight: _filter == 'Physical' ? FontWeight.w900 : FontWeight.normal,
                  ),
                  onSelected: (_) => setState(() => _filter = 'Physical'),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text('Selected ($selectedCount)'),
                  selected: _filter == 'Selected',
                  selectedColor: const Color(0xFFD4FF00),
                  backgroundColor: const Color(0xFF1E1E1E),
                  side: BorderSide(color: _filter == 'Selected' ? const Color(0xFFD4FF00) : const Color(0xFF262626)),
                  labelStyle: TextStyle(
                    fontSize: 11,
                    color: _filter == 'Selected' ? Colors.black : const Color(0xFFA1A1AA),
                    fontWeight: _filter == 'Selected' ? FontWeight.w900 : FontWeight.normal,
                  ),
                  onSelected: (_) => setState(() => _filter = 'Selected'),
                ),
              ],
            ),
          ),

          // Contacts List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFFD4FF00)),
                        SizedBox(height: 12),
                        Text(
                          'Reading phone contacts...',
                          style: TextStyle(fontSize: 13, color: Color(0xFFA1A1AA)),
                        ),
                      ],
                    ),
                  )
                : filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.search_off, size: 40, color: Color(0xFFA1A1AA)),
                              const SizedBox(height: 8),
                              const Text('No contacts found.', style: TextStyle(color: Color(0xFFA1A1AA))),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD4FF00),
                                  foregroundColor: Colors.black,
                                ),
                                onPressed: _pickNativeContact,
                                icon: const Icon(Icons.contacts, size: 16, color: Colors.black),
                                label: const Text('Pick from System Contacts', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        itemCount: filtered.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFF262626)),
                        itemBuilder: (context, index) {
                          final contact = filtered[index];
                          final isSelected = _selectedIds.contains(contact.id);
                          final assignedRole = _customRoles[contact.id] ?? contact.role;

                          return InkWell(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedIds.remove(contact.id);
                                } else {
                                  _selectedIds.add(contact.id);
                                }
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  // Avatar initials
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: isSelected ? const Color(0xFFD4FF00) : const Color(0xFF262626),
                                    child: Text(
                                      contact.avatarInitials,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                        color: isSelected ? Colors.black : Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Name & phone
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          contact.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Text(
                                              contact.phone,
                                              style: const TextStyle(fontSize: 12, color: Color(0xFFA1A1AA)),
                                            ),
                                            if (contact.isPhysicalContact) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF1F2916),
                                                  borderRadius: BorderRadius.circular(4),
                                                  border: Border.all(color: const Color(0xFF2E4020)),
                                                ),
                                                child: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.phone_iphone, size: 9, color: Color(0xFFD4FF00)),
                                                    SizedBox(width: 2),
                                                    Text(
                                                      'Device',
                                                      style: TextStyle(
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.bold,
                                                        color: Color(0xFFD4FF00),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Role badge
                                  GestureDetector(
                                    onTap: () => _showRolePickerForContact(contact),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isSelected ? const Color(0xFF1F2916) : const Color(0xFF1E1E1E),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isSelected ? const Color(0xFFD4FF00) : const Color(0xFF2E2E32),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            assignedRole,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: isSelected ? const Color(0xFFD4FF00) : const Color(0xFFA1A1AA),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.arrow_drop_down,
                                            size: 14,
                                            color: isSelected ? const Color(0xFFD4FF00) : const Color(0xFFA1A1AA),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Checkbox
                                  Checkbox(
                                    value: isSelected,
                                    activeColor: const Color(0xFFD4FF00),
                                checkColor: Colors.black,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    side: const BorderSide(color: Color(0xFF3F3F46)),
                                    onChanged: (val) {
                                      setState(() {
                                        if (val == true) {
                                          _selectedIds.add(contact.id);
                                        } else {
                                          _selectedIds.remove(contact.id);
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // Bottom confirmation bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF141414),
              border: Border(top: BorderSide(color: Color(0xFF262626))),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF2E2E32)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        setState(() {
                          if (_selectedIds.length == _contacts.length) {
                            _selectedIds.clear();
                          } else {
                            _selectedIds.addAll(_contacts.map((c) => c.id));
                          }
                        });
                      },
                      child: Text(
                        _selectedIds.length == _contacts.length ? 'Deselect All' : 'Select All',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4FF00),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: selectedCount == 0
                          ? null
                          : () {
                              final chosen = _contacts.where((c) => _selectedIds.contains(c.id)).map((c) {
                                final role = _customRoles[c.id] ?? c.role;
                                return PlayerItem(
                                  id: c.id,
                                  name: c.name,
                                  phone: c.phone,
                                  role: role,
                                  avatarInitials: c.avatarInitials,
                                  isPhysicalContact: c.isPhysicalContact,
                                );
                              }).toList();

                              widget.onImport(chosen);
                              Navigator.pop(context);
                            },
                      icon: const Icon(Icons.group_add_rounded, size: 18, color: Colors.black),
                      label: Text(
                        'Import ($selectedCount) to Squad',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
