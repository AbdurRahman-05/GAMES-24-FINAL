import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

    final weekdayRateCtrl = TextEditingController(text: profile.weekdayRate.toStringAsFixed(0));
    final weekendRateCtrl = TextEditingController(text: profile.weekendRate.toStringAsFixed(0));
    final dayRateCtrl = TextEditingController(text: profile.dayRate.toStringAsFixed(0));
    final nightRateCtrl = TextEditingController(text: profile.nightRate.toStringAsFixed(0));

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
              Icon(Icons.schedule_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Operating Timings & All Time Costs',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
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

                  // 1. Weekday Timings & Rate Section
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
                            SizedBox(width: 6),
                            Text('Weekdays (Mon - Fri)',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
                          ],
                        ),
                        if (wkdayOpen != '24 Hours') ...[
                          const SizedBox(height: 10),
                          const Text('Opening Time', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
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
                          const Text('Closing Time', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
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
                        const SizedBox(height: 10),
                        const Text('Weekday Hourly Rate (₹/hr)', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: weekdayRateCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            prefixText: '₹ ',
                            prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2. Weekend Timings & Rate Section
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.secondary.withValues(alpha: 0.25)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.weekend_rounded, size: 16, color: AppColors.secondary),
                            SizedBox(width: 6),
                            Text('Weekends (Sat - Sun)',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.secondary)),
                          ],
                        ),
                        if (wkdayOpen != '24 Hours') ...[
                          const SizedBox(height: 10),
                          const Text('Opening Time', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
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
                          const Text('Closing Time', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
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
                        const SizedBox(height: 10),
                        const Text('Weekend Hourly Rate (₹/hr)', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: weekendRateCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            prefixText: '₹ ',
                            prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 3. Day Slot & Night Slot Rates (All Time Costs)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.wb_sunny_rounded, size: 16, color: Color(0xFFCA8A04)),
                            SizedBox(width: 6),
                            Text(
                              'Day & Night Slot Tariffs (All Time Costs)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Day Slot (₹/hr)', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                                  const Text('06:00 AM - 06:00 PM', style: TextStyle(fontSize: 9.5, color: Color(0xFF854D0E))),
                                  const SizedBox(height: 4),
                                  TextField(
                                    controller: dayRateCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      prefixText: '₹ ',
                                      prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFCA8A04)),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Night Slot (₹/hr)', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                                  const Text('06:00 PM - 12:00 AM', style: TextStyle(fontSize: 9.5, color: Color(0xFF4338CA))),
                                  const SizedBox(height: 4),
                                  TextField(
                                    controller: nightRateCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      prefixText: '₹ ',
                                      prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4338CA)),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    ),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onPressed: () {
                final wkR = double.tryParse(weekdayRateCtrl.text.trim()) ?? profile.weekdayRate;
                final wkendR = double.tryParse(weekendRateCtrl.text.trim()) ?? profile.weekendRate;
                final dRate = double.tryParse(dayRateCtrl.text.trim()) ?? profile.dayRate;
                final nRate = double.tryParse(nightRateCtrl.text.trim()) ?? profile.nightRate;

                ref.read(turfProfileProvider.notifier).updateOperatingHours(
                      weekdayOpening: wkdayOpen,
                      weekdayClosing: wkdayClose,
                      weekendOpening: wkendOpen,
                      weekendClosing: wkendClose,
                      weekdayRate: wkR,
                      weekendRate: wkendR,
                      dayRate: dRate,
                      nightRate: nRate,
                    );
                ref.read(adminSlotProvider.notifier).updateOperatingHours(wkdayOpen, wkdayClose, wkendOpen, wkendClose);
                Navigator.pop(ctx);
                ToastUtils.showSuccess(context, "Timings & all time costs updated successfully!");
              },
              child: const Text('Save Timings & Costs'),
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
        Expanded(
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing,
        ],
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
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Executive Partner Passport & Credentials Header
            _buildExecutivePassportHeader(profile),

            // 2. Full Venue Profile & Operations Hub Content
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF03160D), Color(0xFF082B1B), Color(0xFF0F3E29)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF041910),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Ambient background glow watermark
          Positioned(
            top: -40,
            right: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF10B981).withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Identity & Crest Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Modern Stadium Crest Squircle with Verified Seal
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 62,
                          height: 62,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF134530), Color(0xFF0B2F20)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: const Color(0xFF34D399).withValues(alpha: 0.6),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withValues(alpha: 0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.stadium_rounded,
                              size: 32,
                              color: Color(0xFFFBBF24),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -3,
                          right: -3,
                          child: Container(
                            padding: const EdgeInsets.all(3.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF03160D), width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.5),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 11,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),

                    // Venue Credentials & Title
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
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.4,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFF34D399).withValues(alpha: 0.45),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.verified_user_rounded, size: 11, color: Color(0xFF4ADE80)),
                                    SizedBox(width: 3.5),
                                    Text(
                                      'VERIFIED',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF4ADE80),
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Owner badge line
                          Row(
                            children: [
                              const Icon(Icons.person_outline_rounded, size: 12, color: Color(0xFF86EFAC)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Owner: ${profile.ownerName} • ${profile.ownerPhone}',
                                  style: const TextStyle(
                                    color: Color(0xFF86EFAC),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          // Location badge line
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded, size: 12, color: Color(0xFF34D399)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  profile.address.isNotEmpty ? profile.address : 'Madurai Turf Venue',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withValues(alpha: 0.7),
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
                const SizedBox(height: 16),

                // 4 Modern Modular Frosted KPI Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildCreativeMetricCard(
                        icon: Icons.stadium_rounded,
                        label: 'Arenas',
                        value: '${profile.courts.length}',
                        tag: 'Active',
                        accentColor: const Color(0xFF34D399),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildCreativeMetricCard(
                        icon: Icons.sports_soccer_rounded,
                        label: 'Sports',
                        value: '${profile.sports.length}',
                        tag: 'Offered',
                        accentColor: const Color(0xFF38BDF8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildCreativeMetricCard(
                        icon: Icons.currency_rupee_rounded,
                        label: 'GMV',
                        value: profile.revenueBadge.replaceAll(' GMV', ''),
                        tag: 'Target ${_formatTargetLabel(profile.monthlyRevenueTarget > 0 ? profile.monthlyRevenueTarget : 50000.0)}',
                        accentColor: const Color(0xFFFBBF24),
                        onTap: () => _showEditMonthlyTargetDialog(profile),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildCreativeMetricCard(
                        icon: isActive ? Icons.sensors_rounded : Icons.pause_circle_rounded,
                        label: 'Status',
                        value: isActive ? 'LIVE' : 'HOLD',
                        tag: isActive ? 'Player App' : 'Expired',
                        accentColor: isActive ? const Color(0xFF4ADE80) : const Color(0xFFF87171),
                        isLiveIndicator: isActive,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreativeMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required String tag,
    required Color accentColor,
    VoidCallback? onTap,
    bool isLiveIndicator = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.25),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLiveIndicator)
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.7),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    )
                  else
                    Icon(icon, size: 13, color: accentColor),
                  const SizedBox(width: 4),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: accentColor,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),
              Text(
                tag,
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
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
                                  Text(
                                    'GAMES24 VENUE LICENSE',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.8,
                                      color: Colors.white.withValues(alpha: 0.95),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.av_timer_rounded,
                                    size: 14,
                                    color: statusColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      days > 0 ? '$days Days Left' : 'Expired',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Renews: ${profile.subscriptionRenewDate}',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                                maxLines: 1,
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
                              '₹1,180/mo • Zero Player Fees',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () => _showSubscriptionPaymentBottomSheet(profile),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
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
                                size: 13,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isActive ? 'Invoices' : 'Pay ₹1,180',
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
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
                  const Expanded(
                    child: Text(
                      'Partner Subscription & Invoices',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    visualDensity: VisualDensity.compact,
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
                            const Flexible(
                              child: Text(
                                'Listing Plan Breakdown',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                                overflow: TextOverflow.ellipsis,
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
                      const Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.receipt_long_rounded,
                                color: AppColors.primary, size: 18),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Subscription History & Invoices',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
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

        // Monthly Revenue Target & Business Goal Card
        _buildMonthlyRevenueTargetCard(profile),
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
                InkWell(
                  onTap: () => _showEditTimingsDialog(profile),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
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
                                'Weekdays',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A)),
                              ),
                              const SizedBox(height: 1),
                              const Text(
                                'Mon - Fri',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF166534)),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                profile.weekdayOpeningTime == '24 Hours'
                                    ? 'Open 24 Hours'
                                    : '${profile.weekdayOpeningTime} - ${profile.weekdayClosingTime}',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.grey.shade700),
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
                ),
                const SizedBox(height: 8),

                // Weekend Row Card
                InkWell(
                  onTap: () => _showEditTimingsDialog(profile),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
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
                                'Weekends',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A)),
                              ),
                              const SizedBox(height: 1),
                              const Text(
                                'Sat - Sun',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF92400E)),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                profile.weekendOpeningTime == '24 Hours'
                                    ? 'Open 24 Hours'
                                    : '${profile.weekendOpeningTime} - ${profile.weekendClosingTime}',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.grey.shade700),
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
                ),
                const SizedBox(height: 8),

                // Day & Night Slots Summary Row
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _showEditTimingsDialog(profile),
                        borderRadius: BorderRadius.circular(10),
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
                                    const Text('Day Slot', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF854D0E))),
                                    const SizedBox(height: 1),
                                    const Text('06:00 AM - 06:00 PM', style: TextStyle(fontSize: 9, color: Color(0xFF92400E))),
                                    const SizedBox(height: 2),
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
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () => _showEditTimingsDialog(profile),
                        borderRadius: BorderRadius.circular(10),
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
                                    const Text('Night Slot', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF3730A3))),
                                    const SizedBox(height: 1),
                                    const Text('06:00 PM - 12:00 AM', style: TextStyle(fontSize: 9, color: Color(0xFF4338CA))),
                                    const SizedBox(height: 2),
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
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 1. SPORTS SUPPORTED SECTION (Unique & Creative Sport Showcase)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Flexible(
                      child: Text(
                        'Sports Supported',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                      ),
                      child: Text(
                        '${profile.sports.length} Offered',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.add_circle_outline_rounded, size: 14),
                label: const Text('Add', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _showAddSportDialog,
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (profile.sports.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Icon(Icons.sports_soccer_rounded, size: 36, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  const Text('No sports listed yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF64748B))),
                  const SizedBox(height: 4),
                  const Text('Tap "+ Add Sport" to list supported sports with pricing tiers', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            )
          else
            ...profile.sports.map((sport) => _buildCreativeSportCard(sport)),
          const SizedBox(height: 20),

          // 2. REGISTERED COURTS & VENUES (Arena Pitch Pass Design)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Flexible(
                      child: Text(
                        'Registered Arenas & Courts',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F766E).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF0F766E).withValues(alpha: 0.25)),
                      ),
                      child: Text(
                        '${profile.courts.length} Active',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F766E),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.add_location_alt_outlined, size: 14),
                label: const Text('Add', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E).withValues(alpha: 0.12),
                  foregroundColor: const Color(0xFF0F766E),
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _showAddVenueCourtDialog(profile),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (profile.courts.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Icon(Icons.stadium_rounded, size: 36, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  const Text('No arenas or courts registered', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF64748B))),
                  const SizedBox(height: 4),
                  const Text('Add pitches and courts so players can book specific turfs', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            )
          else
            ...profile.courts.map((court) => _buildCreativeCourtCard(profile, court)),
          const SizedBox(height: 20),

          // 3. AMENITIES & FACILITIES (Curated Amenity Badges with Manage Dialog)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Flexible(
                      child: Text(
                        'Amenities & Facilities',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                      ),
                      child: Text(
                        '${profile.facilities.length} Active',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.tune_rounded, size: 14),
                label: const Text('Manage', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _showEditAmenitiesDialog(profile),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (profile.facilities.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Icon(Icons.check_circle_outline_rounded, size: 32, color: Colors.grey.shade400),
                  const SizedBox(height: 6),
                  const Text('No amenities selected', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF64748B))),
                  const SizedBox(height: 2),
                  const Text('Tap "Manage" to select facilities like Parking, Floodlights, Restrooms', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: profile.facilities.map((facility) => _buildAmenityBadge(facility)).toList(),
            ),
          const SizedBox(height: 24),
        ],
      );
  }

  // --- CREATIVE UI HELPERS FOR PROFILE OVERVIEW ---

  Widget _buildCreativeSportCard(TurfSportItem sport) {
    final theme = _getSportTheme(sport.name);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.accent.withValues(alpha: 0.22), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: theme.accent.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showEditSportRateDialog(sport),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              // Sport Header Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.lightBg, Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: theme.gradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: theme.gradient.first.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(theme.icon, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  sport.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: Color(0xFF0F172A),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.accent.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: theme.accent.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  'OFFERED',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: theme.accent,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${sport.courtsAvailable > 0 ? sport.courtsAvailable : 1} Arena(s) Linked • Full Pitch',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${sport.hourlyRate.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const Text(
                            '/hour base',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: Colors.grey.shade100),
              // Pricing Breakdown Strip & Quick Edit
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 12, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Wkday: ₹${sport.weekdayRate.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.stars_rounded, size: 13, color: Color(0xFFD97706)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Wkend: ₹${sport.weekendRate.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF92400E)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: theme.accent.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.edit_outlined, size: 15, color: theme.accent),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreativeCourtCard(TurfProfileState profile, TurfCourtVenueItem court) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Arena Header Strip
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F766E).withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.stadium_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              court.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: Color(0xFF0F172A),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF86EFAC)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(radius: 2.5, backgroundColor: Color(0xFF16A34A)),
                                SizedBox(width: 4),
                                Text(
                                  'ACTIVE',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF15803D),
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                court.sport.isNotEmpty ? court.sport : 'Multi-Sport',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF475569),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                court.surface.isNotEmpty ? court.surface : 'Synthetic Turf',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${court.hourlyRate.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                      const Text(
                        '/hour',
                        style: TextStyle(
                          color: Color(0xFF065F46),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.schedule_rounded, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Operating Hours: ${court.timings.isNotEmpty ? court.timings : '06:00 AM - 11:00 PM'}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade100),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.edit_rounded, size: 14),
                  label: const Text('Edit Arena', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    backgroundColor: AppColors.primary.withValues(alpha: 0.04),
                  ),
                  onPressed: () => _showEditVenueCourtDialog(profile, court),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.delete_outline_rounded, size: 14),
                  label: const Text('Remove', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    backgroundColor: AppColors.error.withValues(alpha: 0.04),
                  ),
                  onPressed: () {
                    ref.read(turfProfileProvider.notifier).removeCourtVenue(court.id);
                    ToastUtils.showSuccess(context, "Removed arena: ${court.name}");
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenityBadge(String facility) {
    final info = _getAmenityInfo(facility);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: info.bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: info.color.withValues(alpha: 0.28), width: 1),
        boxShadow: [
          BoxShadow(
            color: info.color.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4.5),
            decoration: BoxDecoration(
              color: info.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(info.icon, size: 13, color: info.color),
          ),
          const SizedBox(width: 7),
          Text(
            facility,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF10B981)),
        ],
      ),
    );
  }

  void _showEditAmenitiesDialog(TurfProfileState profile) {
    final allKnownAmenities = [
      'Drinking Water',
      'Parking',
      'Restroom',
      'Floodlights',
      'Changing Room',
      'First Aid',
      'Cafeteria',
      'High-Speed WiFi',
      'Lockers',
      'Spectator Seating',
      'Equipment Rental',
    ];

    final selectedFacilities = List<String>.from(profile.facilities);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.tune_rounded, color: AppColors.primary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Manage Venue Amenities',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select the facilities and amenities available to players at your turf:',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    ...allKnownAmenities.map((amenity) {
                      final isChecked = selectedFacilities.contains(amenity);
                      final info = _getAmenityInfo(amenity);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isChecked ? info.bgColor : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isChecked
                                ? info.color.withValues(alpha: 0.4)
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: CheckboxListTile(
                          value: isChecked,
                          activeColor: info.color,
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          secondary: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isChecked ? info.color.withValues(alpha: 0.2) : Colors.grey.shade200,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(info.icon, size: 16, color: isChecked ? info.color : Colors.grey),
                          ),
                          title: Text(
                            amenity,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isChecked ? FontWeight.w700 : FontWeight.w500,
                              color: isChecked ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                            ),
                          ),
                          onChanged: (val) {
                            setDialogState(() {
                              if (val == true) {
                                if (!selectedFacilities.contains(amenity)) {
                                  selectedFacilities.add(amenity);
                                }
                              } else {
                                selectedFacilities.remove(amenity);
                              }
                            });
                          },
                        ),
                      );
                    }),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onPressed: () {
                  ref.read(turfProfileProvider.notifier).updateFacilities(selectedFacilities);
                  Navigator.pop(ctx);
                  ToastUtils.showSuccess(context, 'Amenities updated successfully!');
                },
                child: const Text('Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMonthlyRevenueTargetCard(TurfProfileState profile) {
    final target = profile.monthlyRevenueTarget > 0 ? profile.monthlyRevenueTarget : 50000.0;
    final currentRev = profile.monthRevenue;
    final progress = (target > 0 ? (currentRev / target) : 0.0).clamp(0.0, 1.0);
    final pct = (progress * 100).toInt();
    final remaining = (target - currentRev).clamp(0.0, double.infinity);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF041910), Color(0xFF0B2F20), Color(0xFF134530)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF34D399).withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showEditMonthlyTargetDialog(profile),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF34D399).withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.track_changes_rounded, size: 16, color: Color(0xFF34D399)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'MONTHLY TARGET',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                    color: Color(0xFFCBD5E1),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$pct% Reached • ${remaining > 0 ? "₹${NumberFormat('#,##,###').format(remaining.toInt())} left" : "Goal Met! 🎉"}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: pct >= 100 ? const Color(0xFF4ADE80) : const Color(0xFF86EFAC),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF34D399).withValues(alpha: 0.18),
                        foregroundColor: const Color(0xFF4ADE80),
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _showEditMonthlyTargetDialog(profile),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_rounded, size: 13),
                          SizedBox(width: 4),
                          Text('Set', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              currentRev > 0 ? '₹${NumberFormat('#,##,###').format(currentRev.toInt())}' : '₹0',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          const Text(
                            'Current Month GMV',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF94A3B8),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Goal: ',
                            style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '₹${NumberFormat('#,##,###').format(target.toInt())}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress > 0 ? progress.clamp(0.05, 1.0) : 0.05,
                    minHeight: 7,
                    backgroundColor: Colors.white.withValues(alpha: 0.14),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4ADE80)),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${profile.monthTotalBookings} bookings recorded this month',
                        style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.65), fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Target ${_formatTargetLabel(target)}',
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF4ADE80)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditMonthlyTargetDialog(TurfProfileState profile) {
    final currentTarget = profile.monthlyRevenueTarget > 0 ? profile.monthlyRevenueTarget : 50000.0;
    final controller = TextEditingController(text: currentTarget.toInt().toString());
    final quickPresets = [25000, 50000, 75000, 100000, 150000, 200000];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.track_changes_rounded, color: AppColors.primary, size: 24),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Set Monthly Target',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Set your monthly revenue milestone to track your venue performance and occupancy goals.',
                    style: TextStyle(fontSize: 12.5, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    decoration: InputDecoration(
                      labelText: 'Monthly Revenue Target',
                      prefixText: '₹ ',
                      prefixStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary),
                      helperText: 'E.g., 50000 for ₹50k, 100000 for ₹1 Lakh',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Quick Presets:',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: quickPresets.map((preset) {
                      final isSelected = controller.text.trim() == preset.toString();
                      return InkWell(
                        onTap: () {
                          setDialogState(() {
                            controller.text = preset.toString();
                            controller.selection = TextSelection.fromPosition(
                              TextPosition(offset: controller.text.length),
                            );
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.primary.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Text(
                            _formatTargetLabel(preset.toDouble()),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: isSelected ? Colors.white : AppColors.primary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
                onPressed: () {
                  final text = controller.text.trim().replaceAll(',', '').replaceAll('₹', '');
                  final val = double.tryParse(text);
                  if (val == null || val <= 0) {
                    ToastUtils.showError(context, 'Please enter a valid target amount');
                    return;
                  }
                  ref.read(turfProfileProvider.notifier).updateMonthlyRevenueTarget(val);
                  Navigator.pop(ctx);
                  ToastUtils.showSuccess(
                    context,
                    'Monthly target updated to ${_formatTargetLabel(val)}!',
                  );
                },
                child: const Text('Save Target'),
              ),
            ],
          );
        },
      ),
    );
  }

}

String _formatTargetLabel(double target) {
  if (target >= 100000) {
    final lakhs = target / 100000.0;
    return lakhs == lakhs.roundToDouble()
        ? '₹${lakhs.toInt()}L'
        : '₹${lakhs.toStringAsFixed(1)}L';
  } else if (target >= 1000) {
    final k = target / 1000.0;
    return k == k.roundToDouble()
        ? '₹${k.toInt()}k'
        : '₹${k.toStringAsFixed(1)}k';
  }
  return '₹${target.toInt()}';
}

class _SportTheme {
  final IconData icon;
  final List<Color> gradient;
  final Color accent;
  final Color lightBg;

  const _SportTheme({
    required this.icon,
    required this.gradient,
    required this.accent,
    required this.lightBg,
  });
}

_SportTheme _getSportTheme(String name) {
  final lower = name.toLowerCase().trim();
  if (lower.contains('cricket')) {
    return const _SportTheme(
      icon: Icons.sports_cricket_rounded,
      gradient: [Color(0xFF065F46), Color(0xFF10B981)],
      accent: Color(0xFF059669),
      lightBg: Color(0xFFECFDF5),
    );
  } else if (lower.contains('foot') || lower.contains('soccer')) {
    return const _SportTheme(
      icon: Icons.sports_soccer_rounded,
      gradient: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
      accent: Color(0xFF2563EB),
      lightBg: Color(0xFFEFF6FF),
    );
  } else if (lower.contains('badminton')) {
    return const _SportTheme(
      icon: Icons.sports_tennis_rounded,
      gradient: [Color(0xFFB45309), Color(0xFFF59E0B)],
      accent: Color(0xFFD97706),
      lightBg: Color(0xFFFFFBEB),
    );
  } else if (lower.contains('tennis') || lower.contains('padel') || lower.contains('pickle')) {
    return const _SportTheme(
      icon: Icons.sports_tennis_rounded,
      gradient: [Color(0xFF0F766E), Color(0xFF14B8A6)],
      accent: Color(0xFF0D9488),
      lightBg: Color(0xFFF0FDFA),
    );
  } else if (lower.contains('basket')) {
    return const _SportTheme(
      icon: Icons.sports_basketball_rounded,
      gradient: [Color(0xFFC2410C), Color(0xFFF97316)],
      accent: Color(0xFFEA580C),
      lightBg: Color(0xFFFFF7ED),
    );
  } else if (lower.contains('volley')) {
    return const _SportTheme(
      icon: Icons.sports_volleyball_rounded,
      gradient: [Color(0xFF9A3412), Color(0xFFFB923C)],
      accent: Color(0xFFEA580C),
      lightBg: Color(0xFFFFF7ED),
    );
  }
  return const _SportTheme(
    icon: Icons.sports_rounded,
    gradient: [Color(0xFF1E293B), Color(0xFF475569)],
    accent: Color(0xFF334155),
    lightBg: Color(0xFFF8FAFC),
  );
}

class _AmenityInfo {
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _AmenityInfo({
    required this.icon,
    required this.color,
    required this.bgColor,
  });
}

_AmenityInfo _getAmenityInfo(String name) {
  final lower = name.toLowerCase().trim();
  if (lower.contains('water')) {
    return const _AmenityInfo(
      icon: Icons.water_drop_rounded,
      color: Color(0xFF0284C7),
      bgColor: Color(0xFFF0F9FF),
    );
  } else if (lower.contains('park')) {
    return const _AmenityInfo(
      icon: Icons.local_parking_rounded,
      color: Color(0xFF4F46E5),
      bgColor: Color(0xFFEEF2FF),
    );
  } else if (lower.contains('restroom') || lower.contains('washroom') || lower.contains('toilet')) {
    return const _AmenityInfo(
      icon: Icons.wc_rounded,
      color: Color(0xFF7C3AED),
      bgColor: Color(0xFFF5F3FF),
    );
  } else if (lower.contains('light') || lower.contains('flood')) {
    return const _AmenityInfo(
      icon: Icons.highlight_rounded,
      color: Color(0xFFD97706),
      bgColor: Color(0xFFFFFBEB),
    );
  } else if (lower.contains('changing') || lower.contains('room')) {
    return const _AmenityInfo(
      icon: Icons.checkroom_rounded,
      color: Color(0xFF0D9488),
      bgColor: Color(0xFFF0FDFA),
    );
  } else if (lower.contains('aid') || lower.contains('medical')) {
    return const _AmenityInfo(
      icon: Icons.medical_services_rounded,
      color: Color(0xFFE11D48),
      bgColor: Color(0xFFFFF1F2),
    );
  } else if (lower.contains('wifi') || lower.contains('internet')) {
    return const _AmenityInfo(
      icon: Icons.wifi_rounded,
      color: Color(0xFF2563EB),
      bgColor: Color(0xFFEFF6FF),
    );
  } else if (lower.contains('cafe') || lower.contains('canteen') || lower.contains('snack')) {
    return const _AmenityInfo(
      icon: Icons.local_cafe_rounded,
      color: Color(0xFFEA580C),
      bgColor: Color(0xFFFFF7ED),
    );
  } else if (lower.contains('locker')) {
    return const _AmenityInfo(
      icon: Icons.lock_rounded,
      color: Color(0xFF475569),
      bgColor: Color(0xFFF8FAFC),
    );
  } else if (lower.contains('seat') || lower.contains('dugout') || lower.contains('stand')) {
    return const _AmenityInfo(
      icon: Icons.chair_rounded,
      color: Color(0xFF059669),
      bgColor: Color(0xFFECFDF5),
    );
  }
  return const _AmenityInfo(
    icon: Icons.verified_rounded,
    color: Color(0xFF059669),
    bgColor: Color(0xFFF0FDF4),
  );
}
