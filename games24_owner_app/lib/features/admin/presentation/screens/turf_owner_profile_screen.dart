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
    extends ConsumerState<TurfOwnerProfileScreen> {

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
    final rateCtrl = TextEditingController();
    final weekdayRateCtrl = TextEditingController();
    final weekendRateCtrl = TextEditingController();
    final nightRateCtrl = TextEditingController();
    final courtsCtrl = TextEditingController();

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
                    hint: 'e.g. 1200',
                    controller: rateCtrl,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Weekday Rate (₹)',
                          hint: 'e.g. 1200',
                          controller: weekdayRateCtrl,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AppTextField(
                          label: 'Weekend Rate (₹)',
                          hint: 'e.g. 1600',
                          controller: weekendRateCtrl,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  AppTextField(
                    label: 'Night Floodlight Rate (₹)',
                    hint: 'e.g. 1400',
                    controller: nightRateCtrl,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Number of Courts/Pitches',
                    hint: 'e.g. 1',
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
    final nextNum = profile.courts.length + 1;
    final courtNameCtrl = TextEditingController(text: '${profile.venueName} - Court $nextNum');
    final surfaceCtrl = TextEditingController(text: 'Synthetic Turf');
    final rateCtrl = TextEditingController(text: '1200');
    final Set<String> selectedSports = {'Cricket', 'Football'};
    final availableSports = ['Cricket', 'Football', 'Pickle ball', 'Badminton', 'Tennis', 'Volleyball'];
    for (final s in profile.sports) {
      if (!availableSports.contains(s.name)) {
        availableSports.add(s.name);
      }
    }

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
                  hint: 'e.g. Box Arena, Pitch 2, Main Ground',
                  controller: courtNameCtrl,
                ),
                const SizedBox(height: 12),
                const Text('Supported Sports (Multi-Select):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                const Text(
                  'Cricket and Football can share the same ground. Badminton and Pickleball require dedicated courts.',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: availableSports.map((sport) {
                    final isChecked = selectedSports.contains(sport);
                    return FilterChip(
                      label: Text(sport),
                      selected: isChecked,
                      selectedColor: AppColors.primary,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isChecked ? Colors.white : const Color(0xFF334155),
                      ),
                      backgroundColor: const Color(0xFFF1F5F9),
                      onSelected: (selected) {
                        setDialogState(() {
                          if (selected) {
                            selectedSports.add(sport);
                          } else {
                            if (selectedSports.length > 1) {
                              selectedSports.remove(sport);
                            }
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Surface Specification',
                  controller: surfaceCtrl,
                  hint: 'e.g. Teakwood Mat, Synthetic Grass, Acrylic Court',
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Standard Hourly Rate (₹)',
                  hint: 'e.g. 1000',
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
                final sportsList = selectedSports.toList();
                final courtName = courtNameCtrl.text.trim().isEmpty
                    ? 'Court $nextNum (${sportsList.join(" • ")})'
                    : courtNameCtrl.text.trim();
                final hourlyRate = double.tryParse(rateCtrl.text) ?? 1000.0;

                final newCourt = TurfCourtVenueItem(
                  id: 'CR-${DateTime.now().millisecondsSinceEpoch}',
                  name: courtName,
                  sport: sportsList.join(' • '),
                  sports: sportsList,
                  surface: surfaceCtrl.text.trim().isNotEmpty ? surfaceCtrl.text.trim() : 'Synthetic Turf',
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
      useRootNavigator: true,
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

                            final sportsList = courtSports.entries.where((e) => e.value).map((e) => e.key).toList();
                            final updatedCourt = TurfCourtVenueItem(
                              id: court.id,
                              name: courtName,
                              sport: sportsList.join(' • '),
                              sports: sportsList,
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
    final profile = ref.watch(turfProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildProAppBar(context, profile),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Executive Partner Passport & Credentials Header
            _buildExecutivePassportHeader(profile),

            // 2. Full Venue Profile & Operations Hub Content
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              child: _buildVenueOverviewContent(profile),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildProAppBar(BuildContext context, TurfProfileState profile) {
    return AppBar(
      backgroundColor: const Color(0xFF072115),
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 0,
      toolbarHeight: 60,
      shape: const Border(
        bottom: BorderSide(color: Color(0xFF1E3A2F), width: 1),
      ),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 15),
        ),
        tooltip: 'Back to Dashboard',
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/admin/dashboard');
          }
        },
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Flexible(
                child: Text(
                  'VENUE OPERATIONS & PASSPORT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF154D36),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF34D399).withValues(alpha: 0.4)),
                ),
                child: const Text(
                  'PRO',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF4ADE80),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${profile.venueName} • Madurai Regional Hub',
            style: const TextStyle(
              color: Color(0xFF86EFAC),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      actions: [
        IconButton(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          icon: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: const Icon(Icons.settings_rounded, color: Colors.white, size: 18),
          ),
          tooltip: 'Venue Settings & Operations',
          onPressed: () => context.push('/admin/settings'),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildExecutivePassportHeader(TurfProfileState profile) {
    final isActive = profile.isSubscriptionActive;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF04140D), Color(0xFF0C2B1E), Color(0xFF154D36)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Credentials Badge & Venue Identity Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Glowing Stadium Avatar Crest with Floating Verified Seal
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E3A2F), Color(0xFF0F2E22)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFBBF24), width: 2.2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFBBF24).withValues(alpha: 0.3),
                          blurRadius: 14,
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: const Color(0xFF154D36).withValues(alpha: 0.5),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.stadium_rounded, size: 34, color: Color(0xFFFBBF24)),
                    ),
                  ),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Color(0xFF16A34A),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.verified_rounded,
                        size: 15,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),

              // Title and Credentials
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            profile.venueName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.4,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0F3825), Color(0xFF16A34A)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF4ADE80).withValues(alpha: 0.5)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.shield_rounded, size: 10, color: Color(0xFF86EFAC)),
                              SizedBox(width: 3),
                              Text(
                                'VERIFIED',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Owner: ${profile.ownerName} • ${profile.ownerPhone}',
                      style: const TextStyle(
                        color: Color(0xFF86EFAC),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 12, color: Color(0xFF4ADE80)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            profile.address.isNotEmpty ? profile.address : 'Madurai Turf Venue',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
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

          // 4 Interactive Bento KPI Cards Grid
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildBentoPod(
                    icon: Icons.stadium_rounded,
                    label: 'Arenas',
                    value: '${profile.courts.length}',
                    subtitle: 'Active',
                    color: const Color(0xFF4ADE80),
                  ),
                ),
                _buildHeaderDivider(),
                Expanded(
                  child: _buildBentoPod(
                    icon: Icons.sports_soccer_rounded,
                    label: 'Sports',
                    value: '${profile.sports.length}',
                    subtitle: 'Offered',
                    color: const Color(0xFF38BDF8),
                  ),
                ),
                _buildHeaderDivider(),
                Expanded(
                  child: _buildBentoPod(
                    icon: Icons.currency_rupee_rounded,
                    label: 'GMV',
                    value: profile.revenueBadge.replaceAll(' GMV', ''),
                    subtitle: 'Month',
                    color: const Color(0xFFFBBF24),
                  ),
                ),
                _buildHeaderDivider(),
                Expanded(
                  child: _buildBentoPod(
                    icon: isActive ? Icons.sensors_rounded : Icons.pause_circle_rounded,
                    label: 'Status',
                    value: isActive ? 'LIVE' : 'HOLD',
                    subtitle: isActive ? 'Player App' : 'Expired',
                    color: isActive ? const Color(0xFF4ADE80) : const Color(0xFFF87171),
                    isLiveDot: isActive,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBentoPod({
    required IconData icon,
    required String label,
    required String value,
    required String subtitle,
    required Color color,
    bool isLiveDot = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLiveDot) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.6),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
            ] else ...[
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 3),
            ],
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    color: color,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderDivider() {
    return Container(
      width: 1,
      height: 28,
      color: Colors.white.withValues(alpha: 0.12),
      margin: const EdgeInsets.symmetric(horizontal: 2),
    );
  }

  Widget _buildSubscriptionOverviewCard(TurfProfileState profile) {
    final isActive = profile.isSubscriptionActive;
    final isEndingSoon = profile.isSubscriptionEndingSoon;
    final days = profile.subscriptionDaysRemaining;

    final Color statusColor = isActive
        ? (isEndingSoon ? const Color(0xFFF59E0B) : const Color(0xFF10B981))
        : const Color(0xFFEF4444);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isActive
              ? [
                  const Color(0xFF041910),
                  const Color(0xFF0B2F20),
                  const Color(0xFF134530),
                ]
              : [
                  const Color(0xFF1E0A0A),
                  const Color(0xFF321313),
                  const Color(0xFF4A1818),
                ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isActive
              ? (isEndingSoon ? const Color(0xFFFBBF24).withValues(alpha: 0.6) : const Color(0xFF34D399).withValues(alpha: 0.5))
              : const Color(0xFFF87171).withValues(alpha: 0.5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isActive ? const Color(0xFF059669) : Colors.red).withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Icon(
                isActive ? Icons.verified_rounded : Icons.shield_outlined,
                size: 140,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row: Accredited Seal + Status Tag
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                                border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                              ),
                              child: Icon(
                                isActive ? Icons.verified_user_rounded : Icons.gpp_bad_rounded,
                                color: statusColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          'GAMES24 VENUE LICENSE',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.8,
                                            color: Colors.white.withValues(alpha: 0.95),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                                        ),
                                        child: Text(
                                          isActive ? (isEndingSoon ? 'EXPIRING' : 'ACTIVE') : 'EXPIRED',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.4,
                                            color: statusColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isActive
                                        ? 'Verified Operator Accreditation • Live on Player App'
                                        : 'Listing Paused • Arena hidden from players',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withValues(alpha: 0.65),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Countdown & Progress Meter
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.av_timer_rounded,
                                  size: 14,
                                  color: statusColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  days > 0 ? '$days Days Remaining' : 'Expired 0 Days Left',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            Flexible(
                              child: Text(
                                'Renews: ${profile.subscriptionRenewDate}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: (days / 30.0).clamp(0.0, 1.0),
                            minHeight: 6,
                            backgroundColor: Colors.white.withValues(alpha: 0.12),
                            valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Tariff & Action Button Row (Fixed overflow, opens bottom sheet)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '₹1,000 + 18% GST',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '₹1,180/mo total • Zero Player Fees',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => _showSubscriptionPaymentBottomSheet(profile),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isActive
                                  ? [const Color(0xFF10B981), const Color(0xFF059669)]
                                  : [const Color(0xFFEF4444), const Color(0xFFB91C1C)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: (isActive ? const Color(0xFF059669) : Colors.red).withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isActive ? Icons.receipt_long_rounded : Icons.bolt_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                isActive ? 'License & Invoices' : 'Pay ₹1,180 & Go Live',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
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
          ],
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
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF16A34A)),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          item.id,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF111827)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date: ${item.date}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF4B5563)),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Valid: ${item.validPeriod}',
                        style: const TextStyle(fontSize: 10.5, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
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
                Flexible(
                  child: Text(
                    'Receipt: #${item.receiptNumber}',
                    style: const TextStyle(fontSize: 10.5, color: Color(0xFF6B7280), fontFamily: 'monospace'),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
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
                Expanded(child: Text('Platform Subscription Fee', style: TextStyle(fontSize: 12))),
                Text('₹1,000.00', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Expanded(child: Text('CGST (9%)', style: TextStyle(fontSize: 12, color: Colors.grey))),
                Text('₹90.00', style: TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Expanded(child: Text('SGST (9%)', style: TextStyle(fontSize: 12, color: Colors.grey))),
                Text('₹90.00', style: TextStyle(fontSize: 12)),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(child: Text('Total Paid', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
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

  void _showSubscriptionPaymentBottomSheet(TurfProfileState profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF166534).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.workspace_premium_rounded,
                            color: Color(0xFF166534), size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Partner Subscription & Invoices',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                children: [
                  // 1. Subscription Plan Summary & Renewal Form (Responsive, no overflow)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Listing Plan Breakdown',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: profile.isSubscriptionActive
                                    ? const Color(0xFFDCFCE7)
                                    : const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                profile.isSubscriptionActive ? 'ACTIVE' : 'EXPIRED',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: profile.isSubscriptionActive
                                      ? const Color(0xFF15803D)
                                      : const Color(0xFFB91C1C),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Zero fee for players — owners pay a monthly ₹1,000 + 18% GST (₹1,180) platform subscription to keep their venue discoverable.',
                          style: TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF64748B),
                              height: 1.4),
                        ),
                        const SizedBox(height: 14),

                        // Tariff Breakdown Box (Responsive, no overflow)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: const [
                                  Expanded(
                                    child: Text(
                                      'Monthly Listing Fee',
                                      style: TextStyle(
                                          fontSize: 12, color: Color(0xFF475569)),
                                    ),
                                  ),
                                  Text(
                                    '₹1,000.00',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF0F172A)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: const [
                                  Expanded(
                                    child: Text(
                                      'GST (18% Applicable)',
                                      style: TextStyle(
                                          fontSize: 12, color: Color(0xFF475569)),
                                    ),
                                  ),
                                  Text(
                                    '₹180.00',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF0F172A)),
                                  ),
                                ],
                              ),
                              const Divider(height: 16),
                              Row(
                                children: const [
                                  Expanded(
                                    child: Text(
                                      'Total Amount Payable',
                                      style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F172A)),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    '₹1,180 / mo',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF166534)),
                                  ),
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
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.payment_rounded, size: 18),
                            label: Text(
                              profile.isSubscriptionActive
                                  ? 'Renew Platform Plan (₹1,180)'
                                  : 'Pay ₹1,180 & Go Live ⚡',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            onPressed: () async {
                              Navigator.pop(ctx);
                              final success = await ref
                                  .read(turfProfileProvider.notifier)
                                  .payPlatformSubscription();
                              if (mounted) {
                                if (success) {
                                  ToastUtils.showSuccess(
                                    context,
                                    'Monthly subscription of ₹1,180 paid! Your turf is LIVE on Games24 Player App.',
                                  );
                                } else {
                                  ToastUtils.showError(
                                      context, 'Payment failed. Please retry.');
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. Subscription History & Invoices Section (From Under)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.receipt_long_rounded,
                              color: AppColors.primary, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Subscription History & Invoices',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${profile.subscriptionHistory.length} Paid',
                          style: const TextStyle(
                              color: Color(0xFF166534),
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (profile.subscriptionHistory.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Center(
                        child: Text(
                          'No previous subscription payments recorded.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ...profile.subscriptionHistory
                        .map((item) => _buildSubscriptionHistoryTile(item)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildVenueOverviewContent(TurfProfileState profile) {
    return Column(
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF154D36),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.calendar_month_rounded, size: 16, color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Weekdays (Mon - Fri)',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              profile.weekdayOpeningTime == '24 Hours'
                                  ? 'Open 24 Hours'
                                  : '${profile.weekdayOpeningTime} - ${profile.weekdayClosingTime}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF166534)),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF154D36),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '₹${profile.weekdayRate.toStringAsFixed(0)}/hr',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Weekend Row Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB45309),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.weekend_rounded, size: 16, color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Weekends (Sat - Sun)',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              profile.weekendOpeningTime == '24 Hours'
                                  ? 'Open 24 Hours'
                                  : '${profile.weekendOpeningTime} - ${profile.weekendClosingTime}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF92400E)),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB45309),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '₹${profile.weekendRate.toStringAsFixed(0)}/hr',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.white),
                        ),
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
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFEFCE8), Color(0xFFFEF08A)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFDE047)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFCA8A04),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.wb_sunny_rounded, size: 14, color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Day Slot', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF854D0E))),
                                  Text(
                                    '₹${profile.dayRate.toStringAsFixed(0)}/hr',
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF713F12)),
                                  ),
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
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFC7D2FE)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4338CA),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.nightlight_round, size: 14, color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Night Slot', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF3730A3))),
                                  Text(
                                    '₹${profile.nightRate.toStringAsFixed(0)}/hr',
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF312E81)),
                                  ),
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
      );
  }

}
