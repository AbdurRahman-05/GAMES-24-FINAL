import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:games24_owner_app/core/utils/toast_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../providers/admin_providers.dart';
import 'package:image_picker/image_picker.dart';

class TurfOwnerProfileScreen extends ConsumerStatefulWidget {
  const TurfOwnerProfileScreen({super.key});

  @override
  ConsumerState<TurfOwnerProfileScreen> createState() =>
      _TurfOwnerProfileScreenState();
}

class _TurfOwnerProfileScreenState
    extends ConsumerState<TurfOwnerProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _bookingFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showEditProfileDialog(TurfProfileState profile) {
    final ownerNameCtrl = TextEditingController(text: profile.ownerName);
    final phoneCtrl = TextEditingController(text: profile.ownerPhone);
    final emailCtrl = TextEditingController(text: profile.ownerEmail);
    final venueNameCtrl = TextEditingController(text: profile.venueName);
    final addressCtrl = TextEditingController(text: profile.address);
    final areaCtrl = TextEditingController(text: profile.area);
    final dayRateCtrl = TextEditingController(text: profile.dayRate.toStringAsFixed(0));
    final nightRateCtrl = TextEditingController(text: profile.nightRate.toStringAsFixed(0));
    final weekdayRateCtrl = TextEditingController(text: profile.weekdayRate.toStringAsFixed(0));
    final weekendRateCtrl = TextEditingController(text: profile.weekendRate.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.edit_note_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Edit Turf Profile Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Basic Contact & Venue Info',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
              const SizedBox(height: 12),
              AppTextField(label: 'Owner Full Name', controller: ownerNameCtrl),
              const SizedBox(height: 10),
              AppTextField(label: 'Phone Number', controller: phoneCtrl, keyboardType: TextInputType.phone),
              const SizedBox(height: 10),
              AppTextField(label: 'Email Address', controller: emailCtrl, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 10),
              AppTextField(label: 'Turf / Venue Business Name', controller: venueNameCtrl),
              const SizedBox(height: 10),
              AppTextField(label: 'Full Address', controller: addressCtrl),
              const SizedBox(height: 10),
              AppTextField(label: 'Area / Landmark', controller: areaCtrl),
              const SizedBox(height: 16),

              const Text('Hourly Rates Setup (₹)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Day Rate (₹/hr)',
                      controller: dayRateCtrl,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppTextField(
                      label: 'Night Rate (₹/hr)',
                      controller: nightRateCtrl,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Weekday Rate (₹/hr)',
                      controller: weekdayRateCtrl,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppTextField(
                      label: 'Weekend Rate (₹/hr)',
                      controller: weekendRateCtrl,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Explicit Locked KYC Banner inside Edit Dialog
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_rounded, color: Colors.amber, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'KYC details (Aadhaar, PAN, GSTIN) are verified & locked for compliance. Edit them via Super Admin.',
                        style: TextStyle(fontSize: 11, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await ref.read(turfProfileProvider.notifier).updateProfileDetails(
                    ownerName: ownerNameCtrl.text.trim(),
                    ownerPhone: phoneCtrl.text.trim(),
                    ownerEmail: emailCtrl.text.trim(),
                    venueName: venueNameCtrl.text.trim(),
                    address: addressCtrl.text.trim(),
                    area: areaCtrl.text.trim(),
                    dayRate: double.tryParse(dayRateCtrl.text) ?? profile.dayRate,
                    nightRate: double.tryParse(nightRateCtrl.text) ?? profile.nightRate,
                    weekdayRate: double.tryParse(weekdayRateCtrl.text) ?? profile.weekdayRate,
                    weekendRate: double.tryParse(weekendRateCtrl.text) ?? profile.weekendRate,
                  );
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ToastUtils.showSuccess(context, "Turf Profile & Hourly Rates updated successfully in database!");
              }
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _showEditTimingsDialog(TurfProfileState profile) {
    String wkdayOpen = profile.weekdayOpeningTime;
    String wkdayClose = profile.weekdayClosingTime;
    String wkendOpen = profile.weekendOpeningTime;
    String wkendClose = profile.weekendClosingTime;

    final openOptions = ['24 Hours', '05:00 AM', '06:00 AM', '07:00 AM', '08:00 AM', '09:00 AM'];
    final closeOptions = ['24 Hours', '09:00 PM', '10:00 PM', '11:00 PM', '11:30 PM', '12:00 AM', '01:00 AM (Overnight)'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.access_time_filled_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Edit Operating Timings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: wkdayOpen == '24 Hours',
                        activeColor: AppColors.primary,
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              if (val) {
                                wkdayOpen = '24 Hours';
                                wkdayClose = '24 Hours';
                                wkendOpen = '24 Hours';
                                wkendClose = '24 Hours';
                              } else {
                                wkdayOpen = '06:00 AM';
                                wkdayClose = '11:00 PM';
                                wkendOpen = '05:00 AM';
                                wkendClose = '11:30 PM';
                              }
                            });
                          }
                        },
                      ),
                      const Text(
                        'Open 24 Hours (All Day)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (wkdayOpen != '24 Hours') ...[
                    // Weekday Section
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
                              SizedBox(width: 6),
                              Text('Weekday Timings (Mon - Fri)',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text('Opening Time', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          const SizedBox(height: 4),
                          DropdownButtonFormField<String>(
                            initialValue: openOptions.contains(wkdayOpen) ? wkdayOpen : openOptions[2],
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: openOptions
                                .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13))))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setDialogState(() => wkdayOpen = val);
                            },
                          ),
                          const SizedBox(height: 10),
                          const Text('Closing Time', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          const SizedBox(height: 4),
                          DropdownButtonFormField<String>(
                            initialValue: closeOptions.contains(wkdayClose) ? wkdayClose : closeOptions[3],
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: closeOptions
                                .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13))))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setDialogState(() => wkdayClose = val);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Weekend Section
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.weekend_rounded, size: 16, color: AppColors.secondary),
                              SizedBox(width: 6),
                              Text('Weekend Timings (Sat - Sun)',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.secondary)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text('Opening Time', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          const SizedBox(height: 4),
                          DropdownButtonFormField<String>(
                            initialValue: openOptions.contains(wkendOpen) ? wkendOpen : openOptions[1],
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: openOptions
                                .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13))))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setDialogState(() => wkendOpen = val);
                            },
                          ),
                          const SizedBox(height: 10),
                          const Text('Closing Time', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          const SizedBox(height: 4),
                          DropdownButtonFormField<String>(
                            initialValue: closeOptions.contains(wkendClose) ? wkendClose : closeOptions[4],
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: closeOptions
                                .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13))))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setDialogState(() => wkendClose = val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                ref.read(turfProfileProvider.notifier).updateOperatingHours(
                      weekdayOpening: wkdayOpen,
                      weekdayClosing: wkdayClose,
                      weekendOpening: wkendOpen,
                      weekendClosing: wkendClose,
                    );
                ref.read(adminSlotProvider.notifier).updateOperatingHours(wkdayOpen, wkdayClose, wkendOpen, wkendClose);
                Navigator.pop(ctx);
                ToastUtils.showSuccess(context, "Weekday & Weekend timings updated!");
              },
              child: const Text('Update Timings'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSportDialog() {
    final nameCtrl = TextEditingController();
    final rateCtrl = TextEditingController(text: '1200');
    final weekdayRateCtrl = TextEditingController(text: '1200');
    final weekendRateCtrl = TextEditingController(text: '1600');
    final nightRateCtrl = TextEditingController(text: '1400');
    final courtsCtrl = TextEditingController(text: '1');

    final popularSports = ['Cricket', 'Football', 'Pickleball', 'Badminton', 'Others'];
    String selectedSportName = popularSports.first;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.sports_soccer_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Add New Sport & Set Rates',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Sport Category:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: selectedSportName,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: popularSports
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedSportName = val;
                          nameCtrl.text = val;
                        });
                      }
                    },
                  ),
                  if (selectedSportName == 'Others') ...[
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'Custom Sport Name',
                      controller: nameCtrl,
                      hint: 'Enter your custom sport',
                    ),
                  ],
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Base Standard Hourly Rate (₹)',
                    controller: rateCtrl,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Weekday Rate (₹)',
                          controller: weekdayRateCtrl,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AppTextField(
                          label: 'Weekend Rate (₹)',
                          controller: weekendRateCtrl,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  AppTextField(
                    label: 'Night Floodlight Rate (₹)',
                    controller: nightRateCtrl,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Number of Courts/Pitches',
                    controller: courtsCtrl,
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final sportName = nameCtrl.text.trim().isEmpty ? selectedSportName : nameCtrl.text.trim();
                final rate = double.tryParse(rateCtrl.text) ?? 1000.0;
                final wkdayRate = double.tryParse(weekdayRateCtrl.text) ?? rate;
                final wkendRate = double.tryParse(weekendRateCtrl.text) ?? rate;
                final nightRate = double.tryParse(nightRateCtrl.text) ?? rate;
                final courtsCount = int.tryParse(courtsCtrl.text) ?? 1;

                ref.read(turfProfileProvider.notifier).addSport(
                      TurfSportItem(
                        name: sportName,
                        hourlyRate: rate,
                        weekdayRate: wkdayRate,
                        weekendRate: wkendRate,
                        nightRate: nightRate,
                        courtsAvailable: courtsCount,
                      ),
                    );
                Navigator.pop(ctx);
                ToastUtils.showSuccess(context, "Added $sportName with custom sport rates!");
              },
              child: const Text('Add Sport'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditSportRateDialog(TurfSportItem sport) {
    final baseRateCtrl = TextEditingController(text: sport.hourlyRate.toStringAsFixed(0));
    final weekdayRateCtrl = TextEditingController(text: sport.weekdayRate.toStringAsFixed(0));
    final weekendRateCtrl = TextEditingController(text: sport.weekendRate.toStringAsFixed(0));
    final nightRateCtrl = TextEditingController(text: sport.nightRate.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.sports_soccer_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Edit ${sport.name} Rates',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Set custom hourly rates for ${sport.name}:',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Base Standard Rate (₹/hr)',
                  controller: baseRateCtrl,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'Weekday Rate (₹/hr)',
                        controller: weekdayRateCtrl,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppTextField(
                        label: 'Weekend Rate (₹/hr)',
                        controller: weekendRateCtrl,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                AppTextField(
                  label: 'Night Floodlight Rate (₹/hr)',
                  controller: nightRateCtrl,
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final bRate = double.tryParse(baseRateCtrl.text) ?? sport.hourlyRate;
              final wkRate = double.tryParse(weekdayRateCtrl.text) ?? bRate;
              final wkendRate = double.tryParse(weekendRateCtrl.text) ?? bRate;
              final nRate = double.tryParse(nightRateCtrl.text) ?? bRate;

              ref.read(turfProfileProvider.notifier).updateSportRate(
                    sport.name,
                    hourlyRate: bRate,
                    weekdayRate: wkRate,
                    weekendRate: wkendRate,
                    nightRate: nRate,
                  );
              Navigator.pop(ctx);
              ToastUtils.showSuccess(context, "Updated rates for ${sport.name}!");
            },
            child: const Text('Save Sport Rates'),
          ),
        ],
      ),
    );
  }

  void _showAddVenueCourtDialog(TurfProfileState profile) {
    final courtNameCtrl = TextEditingController();
    final surfaceCtrl = TextEditingController(text: 'FIFA Quality Synthetic Turf');
    final rateCtrl = TextEditingController(text: profile.dayRate.toStringAsFixed(0));
    String selectedSport = profile.sports.isNotEmpty ? profile.sports.first.name : 'Football';
    String dropdownValue = selectedSport;
    String customSportValue = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.add_business_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Add New Sport Venue / Court',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextField(
                  label: 'Court / Pitch Name',
                  hint: 'e.g. Court 3 Pickleball, Arena B 5v5',
                  controller: courtNameCtrl,
                ),
                const SizedBox(height: 12),
                const Text('Sport Type:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: dropdownValue,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    ...profile.sports.map((s) => DropdownMenuItem(value: s.name, child: Text(s.name))),
                    const DropdownMenuItem(value: 'Others', child: Text('Others (Type your own)')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() {
                        dropdownValue = val;
                        if (val != 'Others') selectedSport = val;
                      });
                    }
                  },
                ),
                if (dropdownValue == 'Others') ...[
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Custom Sport Name',
                    controller: TextEditingController(text: customSportValue), 
                    onChanged: (val) {
                      customSportValue = val;
                      selectedSport = val;
                    },
                  ),
                ],
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Surface Specification',
                  controller: surfaceCtrl,
                  hint: 'e.g. Teakwood Mat, Synthetic Grass, Acrylic Court',
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Standard Hourly Rate (₹)',
                  controller: rateCtrl,
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final courtName = courtNameCtrl.text.trim().isEmpty
                    ? 'New Court ($selectedSport)'
                    : courtNameCtrl.text.trim();
                final hourlyRate = double.tryParse(rateCtrl.text) ?? 1000.0;

                final newCourt = TurfCourtVenueItem(
                  id: 'CR-${DateTime.now().millisecondsSinceEpoch}',
                  name: courtName,
                  sport: selectedSport,
                  surface: surfaceCtrl.text.trim(),
                  hourlyRate: hourlyRate,
                  timings: profile.weekdayOpeningTime == '24 Hours'
                      ? '24 Hours Open'
                      : '${profile.weekdayOpeningTime} - ${profile.weekdayClosingTime}',
                );

                ref.read(turfProfileProvider.notifier).addCourtVenue(newCourt);
                Navigator.pop(ctx);
                ToastUtils.showSuccess(context, "Added new court: $courtName");
              },
              child: const Text('Save Venue Court'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditVenueCourtDialog(TurfProfileState profile, TurfCourtVenueItem court) {
    final courtNameCtrl = TextEditingController(text: court.name);
    final surfaceCtrl = TextEditingController(text: court.surface);
    final rateCtrl = TextEditingController(text: court.hourlyRate.toStringAsFixed(0));
    final descCtrl = TextEditingController(text: court.description);
    final sportIcons = {
      'Football': Icons.sports_soccer_rounded,
      'Box Cricket': Icons.sports_cricket_rounded,
      'Badminton': Icons.sports_tennis_rounded,
      'Basketball': Icons.sports_basketball_rounded,
      'Tennis': Icons.sports_tennis_rounded,
    };
    Map<String, bool> courtSports = {};
    for (var s in profile.sports) {
      courtSports[s.name] = court.sport.split(', ').contains(s.name);
    }
    for (var s in court.sport.split(', ')) {
      if (s.isNotEmpty && !courtSports.containsKey(s)) {
        courtSports[s] = true;
      }
    }
    
    List<String> defaultAmenities = [
      'Floodlights (1200 Lux)',
      'Changing Rooms and Showers',
      'Free Parking',
      'First Aid Kit',
      'Refreshment Lounge',
      'CCTV Security',
      'Drinking Water',
      'Clean Washrooms',
    ];
    Map<String, bool> courtAmenities = {};
    for (var a in defaultAmenities) {
      courtAmenities[a] = court.amenities.contains(a);
    }
    for (var a in court.amenities) {
      if (!courtAmenities.containsKey(a)) courtAmenities[a] = true;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => DraggableScrollableSheet(
          initialChildSize: 0.95,
          minChildSize: 0.5,
          maxChildSize: 0.98,
          builder: (context, scrollCtrl) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 4),
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.edit_rounded, color: AppColors.secondary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Edit Court: ${court.name}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Text('Update court details, images & amenities', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                        tooltip: 'Remove Court',
                        onPressed: () {
                          Navigator.pop(ctx);
                          ref.read(turfProfileProvider.notifier).removeCourtVenue(court.id);
                          ToastUtils.showSuccess(context, "Removed court: ${court.name}");
                        },
                      ),
                      IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                    children: [
                      _sheetSectionLabel(Icons.stadium_rounded, 'Court Details'),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Court / Pitch Name',
                        controller: courtNameCtrl,
                      ),
                      const SizedBox(height: 12),
                      _sheetSectionLabel(
                        Icons.sports_rounded, 
                        'Sports Available', 
                        trailing: const Text('Select all supported', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: courtSports.keys.map<Widget>((sport) {
                          final isSelected = courtSports[sport]!;
                          return InkWell(
                            onTap: () => setDialogState(() => courtSports[sport] = !isSelected),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.lightGreen.shade200 : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(sportIcons[sport] ?? Icons.sports_rounded, size: 16, color: isSelected ? Colors.green.shade800 : Colors.grey.shade600),
                                  const SizedBox(width: 6),
                                  Text(
                                    sport,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected ? Colors.green.shade800 : Colors.grey.shade700,
                                    ),
                                  ),
                                  if (isSelected) ...[
                                    const SizedBox(width: 4),
                                    Icon(Icons.check_rounded, size: 16, color: Colors.green.shade800),
                                  ]
                                ],
                              ),
                            ),
                          );
                        }).toList()
                          ..add(
                            ActionChip(
                              avatar: const Icon(Icons.add, size: 16, color: Colors.black87),
                              label: const Text('Add Sport', style: TextStyle(color: Colors.black87)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.black87)),
                              backgroundColor: Colors.white,
                              onPressed: () {
                                final ctrl = TextEditingController();
                                showDialog(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    title: const Text('Add Sport'),
                                    content: TextField(
                                      controller: ctrl,
                                      decoration: const InputDecoration(hintText: 'Sport Name'),
                                    ),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
                                      ElevatedButton(
                                        onPressed: () {
                                          if (ctrl.text.isNotEmpty) {
                                            setDialogState(() => courtSports[ctrl.text] = true);
                                          }
                                          Navigator.pop(c);
                                        },
                                        child: const Text('Add'),
                                      )
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              label: 'Surface Specification',
                              controller: surfaceCtrl,
                              hint: 'e.g. Teakwood Mat',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppTextField(
                              label: 'Standard Hourly Rate (₹)',
                              controller: rateCtrl,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      _sheetSectionLabel(Icons.description_rounded, 'Court Description'),
                      const SizedBox(height: 10),
                      TextField(
                        controller: descCtrl, maxLines: 4, maxLength: 300,
                        decoration: InputDecoration(
                          hintText: 'Optional details about the court...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                          contentPadding: const EdgeInsets.all(14),
                          counterStyle: const TextStyle(fontSize: 10),
                        ),
                      ),
                      const SizedBox(height: 16),

                      _sheetSectionLabel(Icons.checklist_rounded, 'Amenities & Features'),
                      const SizedBox(height: 4),
                      const Text('Select all amenities available at this court.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      const SizedBox(height: 10),
                      ...courtAmenities.keys.map((amenity) => CheckboxListTile(
                        value: courtAmenities[amenity],
                        onChanged: (val) => setDialogState(() => courtAmenities[amenity] = val ?? false),
                        title: Text(amenity, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        activeColor: AppColors.primary,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      )),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ActionChip(
                          avatar: const Icon(Icons.add, size: 16),
                          label: const Text('Add Other Amenity'),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade400)),
                          backgroundColor: Colors.white,
                          onPressed: () {
                            final ctrl = TextEditingController();
                            showDialog(
                              context: context,
                              builder: (c) => AlertDialog(
                                title: const Text('Add Amenity'),
                                content: TextField(
                                  controller: ctrl,
                                  decoration: const InputDecoration(hintText: 'Amenity Name'),
                                ),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
                                  ElevatedButton(
                                    onPressed: () {
                                      if (ctrl.text.isNotEmpty) {
                                        setDialogState(() => courtAmenities[ctrl.text] = true);
                                      }
                                      Navigator.pop(c);
                                    },
                                    child: const Text('Add'),
                                  )
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      _sheetSectionLabel(Icons.photo_library_rounded, 'Court Photo Gallery'),
                      const SizedBox(height: 4),
                      const Text('Add up to 5 court images. The first image will be used as the cover photo.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      const SizedBox(height: 12),
                      _buildImagePreviewCard(
                        TextEditingController(text: 'https://images.unsplash.com/photo-1575361204480-aadea25e6e68?w=800'),
                        'Cover Photo',
                        isCover: true,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildImagePreviewCard(
                              TextEditingController(text: court.imageUrls.length > 1 ? court.imageUrls[1] : ''),
                              'Gallery Photo 2',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildImagePreviewCard(
                              TextEditingController(text: court.imageUrls.length > 2 ? court.imageUrls[2] : ''),
                              'Gallery Photo 3',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildImagePreviewCard(
                              TextEditingController(text: court.imageUrls.length > 3 ? court.imageUrls[3] : ''),
                              'Gallery Photo 4 (Optional)',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildImagePreviewCard(
                              TextEditingController(text: court.imageUrls.length > 4 ? court.imageUrls[4] : ''),
                              'Gallery Photo 5 (Optional)',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.save_rounded),
                          label: const Text('Save Court Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () {
                            final courtName = courtNameCtrl.text.trim().isEmpty ? court.name : courtNameCtrl.text.trim();
                            final hourlyRate = double.tryParse(rateCtrl.text) ?? court.hourlyRate;

                            final updatedCourt = TurfCourtVenueItem(
                              id: court.id,
                              name: courtName,
                              sport: courtSports.entries.where((e) => e.value).map((e) => e.key).join(', '),
                              surface: surfaceCtrl.text.trim().isEmpty ? court.surface : surfaceCtrl.text.trim(),
                              hourlyRate: hourlyRate,
                              timings: profile.weekdayOpeningTime == '24 Hours'
                                  ? '24 Hours Open'
                                  : '${profile.weekdayOpeningTime} - ${profile.weekdayClosingTime}',
                              description: descCtrl.text.trim(),
                              amenities: courtAmenities.entries.where((e) => e.value).map((e) => e.key).toList(),
                            );

                            ref.read(turfProfileProvider.notifier).updateCourtVenue(updatedCourt);
                            Navigator.pop(ctx);
                            ToastUtils.showSuccess(context, "Updated court: $courtName");
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditTurfDialog() {
    final descCtrl = TextEditingController(
        text: 'Premium FIFA-quality synthetic turf with floodlights for night play. Ideal for 5v5, 7v7 football and box cricket matches. Clean facilities, ample parking, and refreshment lounge available.');
    final img1Ctrl = TextEditingController(
        text: 'https://images.unsplash.com/photo-1518605368461-1e1e38ce8ba9?auto=format&fit=crop&w=800&q=80');
    final img2Ctrl = TextEditingController(
        text: 'https://images.unsplash.com/photo-1522778119026-d647f0596c20?auto=format&fit=crop&w=800&q=80');
    final img3Ctrl = TextEditingController(
        text: 'https://images.unsplash.com/photo-1551280388-1c4b787595b9?auto=format&fit=crop&w=800&q=80');
    final img4Ctrl = TextEditingController(text: '');
    final img5Ctrl = TextEditingController(text: '');
    final surfaceCtrl = TextEditingController(text: 'FIFA 2-Star Synthetic Grass (50mm)');
    final dimensionCtrl = TextEditingController(text: '120 x 80 Feet');
    Map<String, bool> amenities = {
      'Floodlights (1200 Lux)': true,
      'Changing Rooms and Showers': true,
      'Free Parking': true,
      'First Aid Kit': true,
      'Refreshment Lounge': false,
      'CCTV Security': true,
      'Drinking Water': true,
      'Clean Washrooms': true,
    };
    Map<String, bool> selectedSports = {
      'Football': true,
      'Box Cricket': true,
      'Badminton': false,
      'Basketball': false,
      'Tennis': false,
    };
    final sportIcons = {
      'Football': Icons.sports_soccer_rounded,
      'Box Cricket': Icons.sports_cricket_rounded,
      'Badminton': Icons.sports_tennis_rounded,
      'Basketball': Icons.sports_basketball_rounded,
      'Tennis': Icons.sports_tennis_rounded,
    };
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.95,
          minChildSize: 0.5,
          maxChildSize: 0.98,
          builder: (context, scrollCtrl) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 4),
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.stadium_rounded, color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Edit Turf Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            Text('Update images, description & amenities', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                    children: [
                      _sheetSectionLabel(Icons.photo_library_rounded, 'Turf Photo Gallery'),
                      const SizedBox(height: 4),
                      const Text('Add up to 5 turf images. The first image will be used as the cover photo.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      const SizedBox(height: 12),
                      _buildImagePreviewCard(img1Ctrl, 'Cover Photo (Slot 1)', isCover: true),
                      const SizedBox(height: 10),
                      Row(children: [Expanded(child: _buildImagePreviewCard(img2Ctrl, 'Photo 2')), const SizedBox(width: 8), Expanded(child: _buildImagePreviewCard(img3Ctrl, 'Photo 3'))]),
                      const SizedBox(height: 10),
                      Row(children: [Expanded(child: _buildImagePreviewCard(img4Ctrl, 'Photo 4 (Optional)')), const SizedBox(width: 8), Expanded(child: _buildImagePreviewCard(img5Ctrl, 'Photo 5 (Optional)'))]),
                      const SizedBox(height: 24),
                      _sheetSectionLabel(
                        Icons.sports_rounded, 
                        'Sports Available', 
                        trailing: const Text('Select all supported', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: selectedSports.keys.map<Widget>((sport) {
                          final isSelected = selectedSports[sport]!;
                          return InkWell(
                            onTap: () => setSheetState(() => selectedSports[sport] = !isSelected),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.lightGreen.shade200 : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(sportIcons[sport], size: 16, color: isSelected ? Colors.green.shade800 : Colors.grey.shade600),
                                  const SizedBox(width: 6),
                                  Text(
                                    sport,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected ? Colors.green.shade800 : Colors.grey.shade700,
                                    ),
                                  ),
                                  if (isSelected) ...[
                                    const SizedBox(width: 4),
                                    Icon(Icons.check_rounded, size: 16, color: Colors.green.shade800),
                                  ]
                                ],
                              ),
                            ),
                          );
                        }).toList()
                          ..add(
                            ActionChip(
                              avatar: const Icon(Icons.add, size: 16, color: Colors.black87),
                              label: const Text('Add Sport', style: TextStyle(color: Colors.black87)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.black87)),
                              backgroundColor: Colors.white,
                              onPressed: () {
                                final ctrl = TextEditingController();
                                showDialog(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    title: const Text('Add Sport'),
                                    content: TextField(
                                      controller: ctrl,
                                      decoration: const InputDecoration(hintText: 'Sport Name'),
                                    ),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
                                      ElevatedButton(
                                        onPressed: () {
                                          if (ctrl.text.isNotEmpty) {
                                            setSheetState(() => selectedSports[ctrl.text] = true);
                                          }
                                          Navigator.pop(c);
                                        },
                                        child: const Text('Add'),
                                      )
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                      ),
                      const SizedBox(height: 24),
                      _sheetSectionLabel(Icons.description_rounded, 'Turf Description'),
                      const SizedBox(height: 10),
                      TextField(
                        controller: descCtrl, maxLines: 5, maxLength: 500,
                        decoration: InputDecoration(
                          hintText: 'Describe your turf - facilities, surface quality, team sizes, ambiance...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                          contentPadding: const EdgeInsets.all(14),
                          counterStyle: const TextStyle(fontSize: 10),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _sheetSectionLabel(Icons.grass_rounded, 'Surface & Dimensions'),
                      const SizedBox(height: 10),
                      TextField(
                        controller: surfaceCtrl,
                        decoration: InputDecoration(
                          labelText: 'Surface Type & Quality',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: dimensionCtrl,
                        decoration: InputDecoration(
                          labelText: 'Turf Dimensions',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _sheetSectionLabel(Icons.checklist_rounded, 'Amenities & Features'),
                      const SizedBox(height: 4),
                      const Text('Select all amenities available at your turf.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      const SizedBox(height: 10),
                      ...amenities.keys.map((amenity) => CheckboxListTile(
                        value: amenities[amenity],
                        onChanged: (val) => setSheetState(() => amenities[amenity] = val ?? false),
                        title: Text(amenity, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        activeColor: AppColors.primary,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      )),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.save_rounded),
                          label: const Text('Save Turf Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            ToastUtils.showSuccess(context, "Turf details updated successfully!");
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sheetSectionLabel(IconData icon, String label, {Widget? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
          ],
        ),
        ?trailing,
      ],
    );
  }

  Widget _buildImagePreviewCard(TextEditingController ctrl, String label, {bool isCover = false}) {
    return StatefulBuilder(
      builder: (context, setCardState) {
        final hasUrl = ctrl.text.trim().isNotEmpty;
        return GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: Text('Upload/Set $label'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        final ImagePicker picker = ImagePicker();
                        final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                        if (image != null) {
                          ctrl.text = image.path;
                          if (context.mounted) {
                            Navigator.pop(ctx);
                            setCardState(() {});
                          }
                        }
                      },
                      icon: const Icon(Icons.folder_open_rounded),
                      label: const Text('Choose from Folder'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade200,
                        foregroundColor: Colors.black87,
                        elevation: 0,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('OR', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    TextField(
                      controller: ctrl, autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Enter image URL (https://...)', 
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                    onPressed: () { Navigator.pop(ctx); setCardState(() {}); },
                    child: const Text('Save Image'),
                  ),
                ],
              ),
            );
          },
          child: Container(
            height: isCover ? 180 : 110,
            decoration: BoxDecoration(
              color: hasUrl ? Colors.grey.shade200 : AppColors.primary.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isCover && !hasUrl ? AppColors.primary.withValues(alpha: 0.4) : Colors.grey.shade300, width: isCover && !hasUrl ? 1.5 : 1),
              image: hasUrl ? DecorationImage(image: NetworkImage(ctrl.text.trim()), fit: BoxFit.cover, onError: (e, st) {}) : null,
            ),
            child: hasUrl
                ? Stack(children: [
                    Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent, Colors.transparent]))),
                    if (isCover) Positioned(top: 12, left: 12, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: const Color(0xFF1B4D3E), borderRadius: BorderRadius.circular(20)), child: const Text('COVER', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)))),
                    Positioned(bottom: 12, right: 12, child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), shape: BoxShape.circle), child: const Icon(Icons.edit_rounded, color: Colors.white, size: 16))),
                  ])
                : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.add_photo_alternate_rounded, color: const Color(0xFF6B8B78), size: 32),
                    const SizedBox(height: 8),
                    Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF6B8B78), fontWeight: FontWeight.w500), textAlign: TextAlign.center),
                    const SizedBox(height: 4),
                    Text('Tap to add', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ]),
          ),
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = ref.watch(turfProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Turf Owner Profile & Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            tooltip: 'Edit Profile Details',
            onPressed: () => _showEditProfileDialog(profile),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            tooltip: 'Logout to Login Screen',
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('owner_logged_in', false);
              await prefs.remove('owner_phone');
              await prefs.remove('verified_admin_data');
              await prefs.remove('owner_venue_name');
              ref.read(isAdminModeProvider.notifier).setMode(false);
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Profile Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.12),
                  AppColors.secondary.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.primary,
                      child: const Icon(Icons.stadium_rounded, size: 40, color: Colors.white),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  profile.venueName,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.verified_rounded, size: 12, color: AppColors.success),
                                    SizedBox(width: 4),
                                    Text('Verified KYC',
                                        style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.success)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('Owner: ${profile.ownerName} • ${profile.ownerPhone}',
                              style: theme.textTheme.bodySmall),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded, size: 13, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  profile.address,
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Quick Actions Button Bar
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.edit, size: 14),
                        label: const Text('Edit Details', style: TextStyle(fontSize: 11)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                        onPressed: () => _showEditProfileDialog(profile),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.stadium_rounded, size: 14),
                        label: const Text('Edit Turf', style: TextStyle(fontSize: 11)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                        onPressed: _showEditTurfDialog,
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.access_time_rounded, size: 14),
                        label: Text(
                            profile.openingTime == '24 Hours'
                                ? 'Timings (24 Hours Open)'
                                : 'Timings (${profile.openingTime} - ${profile.closingTime})',
                            style: const TextStyle(fontSize: 11)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                        onPressed: () => _showEditTimingsDialog(profile),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.sports_soccer_rounded, size: 14),
                        label: const Text('Add Sport', style: TextStyle(fontSize: 11)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                        onPressed: _showAddSportDialog,
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.add_business_rounded, size: 14),
                        label: const Text('Add Venue Court', style: TextStyle(fontSize: 11)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                        onPressed: () => _showAddVenueCourtDialog(profile),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tab Bar
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: AppColors.primary,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(icon: Icon(Icons.storefront_rounded), text: 'Venue Overview'),
              Tab(icon: Icon(Icons.receipt_long_rounded), text: 'Booking History'),
              Tab(icon: Icon(Icons.security_rounded), text: 'KYC Details (Locked)'),
            ],
          ),

          // Tab Contents
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Venue Overview & Courts
                _buildVenueOverviewTab(profile),

                // Tab 2: Booking History
                _buildBookingHistoryTab(profile),

                // Tab 3: KYC Details (Locked / Non-Editable)
                _buildKycDetailsTab(profile),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionOverviewCard(TurfProfileState profile) {
    final isActive = profile.isSubscriptionActive;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Exact card matching the user's uploaded screenshot (media_1794034190203_d397473f.png)
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: (isActive ? Colors.green : Colors.red).withValues(alpha: 0.05),
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isActive ? Icons.verified_rounded : Icons.warning_amber_rounded,
                      color: isActive ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isActive ? 'Platform Subscription: Active' : 'Subscription Expired • Turf Hidden',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: isActive ? const Color(0xFF166534) : const Color(0xFF991B1B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isActive
                              ? 'Turf is LIVE on Player App • ₹1,000 + 18% GST (₹1,180/mo)'
                              : 'Turf is HIDDEN from players. Pay ₹1,000 + GST to go live.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isActive ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Renews: ${profile.subscriptionRenewDate}',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isActive ? const Color(0xFF374151) : const Color(0xFFDC2626),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isActive ? const Color(0xFF166534) : const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    onPressed: () => _showSubscriptionPaymentDialog(profile),
                    child: Text(
                      isActive ? 'Subscription Details' : 'Pay ₹1,180 & Go Live ⚡',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Testing state pills for easy demonstration
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              const Text('Demo Test: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(width: 4),
              _buildDemoPill(profile, '30d Active', 30),
              const SizedBox(width: 6),
              _buildDemoPill(profile, '2d Ending', 2),
              const SizedBox(width: 6),
              _buildDemoPill(profile, '0d Blocked', 0),
            ],
          ),
        ),

        // Subscription Payment History section
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Subscription Payment History',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF166534).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${profile.subscriptionHistory.length} Paid',
                      style: const TextStyle(color: Color(0xFF166534), fontSize: 10.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              if (profile.subscriptionHistory.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Text('No previous subscription payments recorded.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ),
                )
              else
                ...profile.subscriptionHistory.map((item) => _buildSubscriptionHistoryTile(item)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDemoPill(TurfProfileState profile, String label, int days) {
    final isSelected = (days == 30 && profile.subscriptionDaysRemaining > 3 && profile.isSubscriptionActive) ||
        (days == 2 && profile.isSubscriptionEndingSoon) ||
        (days == 0 && profile.isSubscriptionBlocked);

    return InkWell(
      onTap: () {
        ref.read(turfProfileProvider.notifier).setSubscriptionDays(days);
        if (days == 0) {
          ToastUtils.showWarning(context, 'Set to 0 Days Expired: Owner access blocked & turf hidden from players.');
        } else if (days == 2) {
          ToastUtils.showWarning(context, 'Set to 2 Days Left: Warning banner will now show on Home page.');
        } else {
          ToastUtils.showSuccess(context, 'Set to 30 Days Active: Normal live status (home page banner hidden).');
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : const Color(0xFF4B5563),
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionHistoryTile(SubscriptionPaymentItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF16A34A)),
                    const SizedBox(width: 6),
                    Text(
                      item.id,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF111827)),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.status.toUpperCase(),
                    style: const TextStyle(color: Color(0xFF166534), fontSize: 9.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Date: ${item.date}', style: const TextStyle(fontSize: 11, color: Color(0xFF4B5563))),
                    const SizedBox(height: 2),
                    Text('Valid: ${item.validPeriod}', style: const TextStyle(fontSize: 10.5, color: Colors.grey)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${item.totalAmount.toInt()}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF166534)),
                    ),
                    const Text('₹1000 + 18% GST', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ],
            ),
            const Divider(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Receipt: #${item.receiptNumber}',
                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF6B7280), fontFamily: 'monospace'),
                ),
                InkWell(
                  onTap: () => _showReceiptDetailsDialog(item),
                  child: const Text(
                    'View Receipt 📄',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showReceiptDetailsDialog(SubscriptionPaymentItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.receipt_long_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Tax Invoice Receipt', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Receipt Number: ${item.receiptNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 4),
            Text('Payment Date: ${item.date}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text('Payment Mode: ${item.paymentMethod}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Platform Subscription Fee', style: TextStyle(fontSize: 12)),
                Text('₹1,000.00', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('CGST (9%)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text('₹90.00', style: TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('SGST (9%)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text('₹90.00', style: TextStyle(fontSize: 12)),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Paid', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                Text('₹${item.totalAmount.toInt()}.00', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF166534))),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Games24 Platform Services Ltd.\nGSTIN: 33AAACG2424F1Z9\nHSN/SAC: 998314',
                style: TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSubscriptionPaymentDialog(TurfProfileState profile) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF166534).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFF166534), size: 22),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Partner Subscription',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Zero fee for players — owners pay a monthly ₹1,000 + 18% GST (₹1,180) platform subscription to keep their venue discoverable.',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: const [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Monthly Listing Fee', style: TextStyle(fontSize: 12, color: Color(0xFF4B5563))),
                      Text('₹1,000.00', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('GST (18% Applicable)', style: TextStyle(fontSize: 12, color: Color(0xFF4B5563))),
                      Text('₹180.00', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Amount Payable', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                      Text('₹1,180 / month', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF166534))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF166534),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.payment_rounded, size: 18),
                label: Text(
                  profile.isSubscriptionActive ? 'Renew Platform Plan (₹1,180)' : 'Pay ₹1,180 & Go Live ⚡',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  final success = await ref.read(turfProfileProvider.notifier).payPlatformSubscription();
                  if (mounted) {
                    if (success) {
                      ToastUtils.showSuccess(
                        context,
                        'Monthly subscription of ₹1,180 paid! Your turf is LIVE on Games24 Player App.',
                      );
                    } else {
                      ToastUtils.showError(context, 'Payment failed. Please retry.');
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildVenueOverviewTab(TurfProfileState profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Monthly Platform Subscription Card
          _buildSubscriptionOverviewCard(profile),
          const SizedBox(height: 16),

          // Timings & Pricing Summary Card
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.schedule_rounded, color: AppColors.primary, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Operating Timings & Schedule',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                      onPressed: () => _showEditTimingsDialog(profile),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 4),

                // Weekday Row Card
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded, size: 18, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Weekdays (Mon - Fri)',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
                            Text(
                                profile.weekdayOpeningTime == '24 Hours'
                                    ? 'Open 24 Hours'
                                    : '${profile.weekdayOpeningTime} to ${profile.weekdayClosingTime}',
                                style: const TextStyle(fontSize: 11, color: Colors.black87)),
                          ],
                        ),
                      ),
                      Text(
                        '₹${profile.weekdayRate.toStringAsFixed(0)}/hr',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Weekend Row Card
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.weekend_rounded, size: 18, color: AppColors.secondary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Weekends (Sat - Sun)',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.secondary)),
                            Text(
                                profile.weekendOpeningTime == '24 Hours'
                                    ? 'Open 24 Hours'
                                    : '${profile.weekendOpeningTime} to ${profile.weekendClosingTime}',
                                style: const TextStyle(fontSize: 11, color: Colors.black87)),
                          ],
                        ),
                      ),
                      Text(
                        '₹${profile.weekendRate.toStringAsFixed(0)}/hr',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.secondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Day & Night Slots Summary Row
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.wb_sunny_rounded, size: 15, color: Colors.amber),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Day Slot Rate', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                  Text('₹${profile.dayRate.toStringAsFixed(0)}/hr',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.indigo.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.nightlight_round, size: 15, color: Colors.indigo),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Night Slot Rate', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                  Text('₹${profile.nightRate.toStringAsFixed(0)}/hr',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Sports Supported Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Sports Supported', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              TextButton.icon(
                icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                label: const Text('Add Sport'),
                onPressed: _showAddSportDialog,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: profile.sports.map((sport) {
              return InkWell(
                onTap: () => _showEditSportRateDialog(sport),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.sports_rounded, size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${sport.name} • ₹${sport.hourlyRate.toStringAsFixed(0)}/hr',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary),
                          ),
                          Text(
                            'Wkday ₹${sport.weekdayRate.toStringAsFixed(0)} | Wkend ₹${sport.weekendRate.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 9, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.edit_rounded, size: 12, color: AppColors.primary),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Sport Venues & Courts List
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Registered Courts & Venues',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.add_location_alt_outlined, size: 16),
                label: const Text('Add Court'),
                onPressed: () => _showAddVenueCourtDialog(profile),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...profile.courts.map((court) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.stadium, color: AppColors.secondary, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(court.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 2),
                                Text('Sport: ${court.sport} • ${court.surface}',
                                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                const SizedBox(height: 2),
                                Text('Timings: ${court.timings}',
                                    style: const TextStyle(fontSize: 10, color: AppColors.primary)),
                              ],
                            ),
                          ),
                          Text(
                            '₹${court.hourlyRate.toStringAsFixed(0)}/hr',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            icon: const Icon(Icons.edit_rounded, size: 14),
                            label: const Text('Edit Turf', style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => _showEditVenueCourtDialog(profile, court),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.delete_outline_rounded, size: 14),
                            label: const Text('Remove', style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {
                              ref.read(turfProfileProvider.notifier).removeCourtVenue(court.id);
                              ToastUtils.showSuccess(context, "Removed court: ${court.name}");
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 16),

          // Facilities List
          const Text('Amenities & Facilities', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: profile.facilities.map((facility) {
              return Chip(
                avatar: const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.success),
                label: Text(facility, style: const TextStyle(fontSize: 11)),
                backgroundColor: Colors.grey.withValues(alpha: 0.08),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingHistoryTab(TurfProfileState profile) {
    final filteredBookings = profile.bookingHistory.where((b) {
      if (_bookingFilter == 'All') return true;
      return b.status.toLowerCase() == _bookingFilter.toLowerCase();
    }).toList();

    return Column(
      children: [
        // Filter Chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'Confirmed', 'Completed', 'Cancelled'].map((status) {
                final isSelected = _bookingFilter == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(status),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    onSelected: (selected) {
                      if (selected) setState(() => _bookingFilter = status);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // Booking History List
        Expanded(
          child: filteredBookings.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('No bookings found for this filter.', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
                  itemCount: filteredBookings.length,
                  itemBuilder: (context, index) {
                    final item = filteredBookings[index];
                    Color statusColor = AppColors.success;
                    if (item.status == 'Confirmed') statusColor = AppColors.primary;
                    if (item.status == 'Cancelled') statusColor = AppColors.error;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(item.id,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: Colors.grey)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    item.status.toUpperCase(),
                                    style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.person_rounded, size: 16, color: AppColors.primary),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '${item.customerName} (${item.customerPhone})',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.sports_rounded, size: 15, color: Colors.grey),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '${item.sport} • ${item.courtName}',
                                    style: const TextStyle(fontSize: 11.5),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.access_time_rounded, size: 15, color: Colors.grey),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    item.dateTimeSlot,
                                    style: const TextStyle(fontSize: 11),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '₹${item.amount.toStringAsFixed(0)} (${item.paymentMethod})',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
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

  Widget _buildKycDetailsTab(TurfProfileState profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Explicit Non-Editable Security Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock_rounded, color: AppColors.warning, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🔒 KYC & Tax Identity Locked',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.warning, fontSize: 13),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Aadhaar, PAN Card, and GSTIN details were verified during registration and are strictly locked for financial compliance. Contact Super Admin to request updates.',
                        style: TextStyle(fontSize: 11, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // GSTIN Business Number Card (LOCKED)
          _buildLockedKycCard(
            title: 'GSTIN Business Registration Number',
            value: profile.gstin,
            icon: Icons.receipt_rounded,
            badge: 'Verified Business GST',
          ),
          const SizedBox(height: 12),

          // PAN Card Number Card (LOCKED)
          _buildLockedKycCard(
            title: 'Owner PAN Card Number',
            value: profile.pan,
            icon: Icons.badge_rounded,
            badge: 'PAN Verified',
          ),
          const SizedBox(height: 12),

          // Aadhaar Card Number Card (LOCKED)
          _buildLockedKycCard(
            title: 'Owner Aadhaar Identity Number',
            value: profile.aadhaar,
            icon: Icons.credit_card_rounded,
            badge: 'Aadhaar Verified',
          ),
          const SizedBox(height: 12),

          // Payout Bank Account Details (LOCKED)
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.account_balance_rounded, color: AppColors.primary),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Automated Weekly Payout Bank Account',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const Divider(),
                _buildReadOnlyField('Bank Account Number', profile.bankAccount),
                const SizedBox(height: 8),
                _buildReadOnlyField('IFSC Code', profile.ifsc),
                const SizedBox(height: 8),
                _buildReadOnlyField('Payout UPI ID', profile.upiId),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedKycCard({
    required String title,
    required String value,
    required IconData icon,
    required String badge,
  }) {
    return AppCard(
      color: Colors.grey.withValues(alpha: 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(icon, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.lock, size: 13, color: Colors.grey),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, size: 12, color: AppColors.success),
                    const SizedBox(width: 4),
                    Text(
                      badge,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Row(
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(width: 4),
            const Icon(Icons.lock_outline, size: 12, color: Colors.grey),
          ],
        ),
      ],
    );
  }
}
