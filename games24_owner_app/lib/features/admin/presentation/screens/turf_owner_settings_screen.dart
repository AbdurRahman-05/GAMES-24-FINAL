import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../providers/admin_providers.dart';

class TurfOwnerSettingsScreen extends ConsumerStatefulWidget {
  const TurfOwnerSettingsScreen({super.key});

  @override
  ConsumerState<TurfOwnerSettingsScreen> createState() =>
      _TurfOwnerSettingsScreenState();
}

class _TurfOwnerSettingsScreenState
    extends ConsumerState<TurfOwnerSettingsScreen> {
  bool _pushNotifications = true;
  bool _audioCheckInAlerts = true;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(turfProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF072115),
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 60,
        titleSpacing: 0,
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
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 15),
          ),
          tooltip: 'Back to Profile',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/admin/profile');
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'VENUE SETTINGS & OPERATIONS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              '${profile.venueName.isNotEmpty ? profile.venueName : 'Venue'} • Operations Hub',
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
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        physics: const BouncingScrollPhysics(),
        children: [
          // 1. Executive Venue Passport Badge Card
          _buildVenuePassportCard(profile),
          const SizedBox(height: 20),

          // 2. Section: Venue Configuration (Moved from Carousel)
          _buildSectionHeader('VENUE CONFIGURATION & RATES'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildActionTile(
                  icon: Icons.tune_rounded,
                  accentColor: const Color(0xFF154D36),
                  bgColor: const Color(0xFFDCFCE7),
                  title: 'Edit Venue & Owner Profile',
                  onTap: () => _showEditProfileDialog(profile),
                ),
                const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
                _buildActionTile(
                  icon: Icons.schedule_rounded,
                  accentColor: const Color(0xFFB45309),
                  bgColor: const Color(0xFFFEF3C7),
                  title: 'Operating Timings & Tariffs',
                  onTap: () => _showEditTimingsDialog(profile),
                ),
                const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
                _buildActionTile(
                  icon: Icons.stadium_rounded,
                  accentColor: const Color(0xFF334155),
                  bgColor: const Color(0xFFF1F5F9),
                  title: 'Turf Specifications & Amenities',
                  onTap: _showEditTurfDialog,
                ),
                const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
                _buildActionTile(
                  icon: Icons.track_changes_rounded,
                  accentColor: const Color(0xFF047857),
                  bgColor: const Color(0xFFECFDF5),
                  title: 'Monthly Revenue Target (Goal)',
                  onTap: () => _showEditMonthlyTargetDialog(profile),
                ),
                const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
                _buildActionTile(
                  icon: Icons.sports_soccer_rounded,
                  accentColor: const Color(0xFF0369A1),
                  bgColor: const Color(0xFFE0F2FE),
                  title: 'Add New Sport Offering',
                  onTap: _showAddSportDialog,
                ),
                const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
                _buildActionTile(
                  icon: Icons.add_business_rounded,
                  accentColor: const Color(0xFF6D28D9),
                  bgColor: const Color(0xFFEDE9FE),
                  title: 'Add Arena / Court',
                  onTap: () => _showAddVenueCourtDialog(profile),
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. Section: Matchday & Gate Operations
          _buildSectionHeader('MATCHDAY & PLATFORM OPERATIONS'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildActionTile(
                  icon: Icons.qr_code_scanner_rounded,
                  accentColor: const Color(0xFF15803D),
                  bgColor: const Color(0xFFDCFCE7),
                  title: 'Gate Pass QR Scanner',
                  onTap: () => context.push('/admin/qr-scanner'),
                ),
                const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
                _buildActionTile(
                  icon: Icons.verified_user_rounded,
                  accentColor: const Color(0xFFCA8A04),
                  bgColor: const Color(0xFFFEF9C3),
                  title: 'Games24 Platform License & Invoices',
                  onTap: () => _showSubscriptionPaymentBottomSheet(profile),
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 4. Section: Legal Compliance & Archives (Moved from Profile tab bar)
          _buildSectionHeader('LEGAL COMPLIANCE & ARCHIVES'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildActionTile(
                  icon: Icons.shield_rounded,
                  accentColor: const Color(0xFF0F766E),
                  bgColor: const Color(0xFFCCFBF1),
                  title: 'KYC & Tax Identity Records',
                  onTap: () => _showKycDetailsBottomSheet(profile),
                ),
                const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
                _buildActionTile(
                  icon: Icons.receipt_long_rounded,
                  accentColor: const Color(0xFF1D4ED8),
                  bgColor: const Color(0xFFDBEAFE),
                  title: 'Booking History & Audit Archive',
                  onTap: () => _showBookingArchiveBottomSheet(profile),
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 5. Section: Preferences
          _buildSectionHeader('PREFERENCES & ALERTS'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                SwitchListTile(
                  activeTrackColor: const Color(0xFF154D36),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  secondary: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE9FE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.notifications_active_rounded,
                        color: Color(0xFF7C3AED), size: 16),
                  ),
                  title: const Text(
                    'Booking Push Notifications',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  value: _pushNotifications,
                  onChanged: (val) {
                    setState(() => _pushNotifications = val);
                    ToastUtils.showSuccess(context,
                        val ? 'Push alerts enabled' : 'Push alerts disabled');
                  },
                ),
                const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
                SwitchListTile(
                  activeTrackColor: const Color(0xFF154D36),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  secondary: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.volume_up_rounded,
                        color: Color(0xFF0284C7), size: 16),
                  ),
                  title: const Text(
                    'Check-In Audio Chime',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  value: _audioCheckInAlerts,
                  onChanged: (val) {
                    setState(() => _audioCheckInAlerts = val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 5. Section: Security & Logout
          _buildLogoutCard(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Color(0xFF64748B),
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildVenuePassportCard(TurfProfileState profile) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF04140D), Color(0xFF0C2B1E), Color(0xFF154D36)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF34D399).withValues(alpha: 0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF154D36).withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -15,
            child: Icon(
              Icons.stadium_rounded,
              size: 110,
              color: Colors.white.withValues(alpha: 0.04),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEAB308), Color(0xFFCA8A04)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Center(
                    child: Icon(Icons.stadium_rounded,
                        color: Colors.white, size: 26),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              profile.venueName.isNotEmpty
                                  ? profile.venueName
                                  : 'Games24 Turf',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.verified_rounded,
                              color: Color(0xFF34D399), size: 16),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Owner: ${profile.ownerName} • ${profile.ownerPhone}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        profile.address.isNotEmpty
                            ? profile.address
                            : 'Madurai, Tamil Nadu',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 10.5,
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
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color accentColor,
    required Color bgColor,
    required String title,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: isLast ? Radius.zero : const Radius.circular(16),
        bottom: isLast ? const Radius.circular(16) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accentColor, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 12, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutCard() {
    return InkWell(
      onTap: _confirmLogout,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFECACA), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.logout_rounded,
                  color: Color(0xFFDC2626), size: 18),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Logout of Partner Hub',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                  SizedBox(height: 1),
                  Text(
                    'Securely sign out and exit this session',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF991B1B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 13, color: Color(0xFFDC2626)),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // OPERATIONAL CONFIGURATION DIALOGS
  // -------------------------------------------------------------

  void _showEditProfileDialog(TurfProfileState profile) {
    final ownerNameCtrl = TextEditingController(text: profile.ownerName);
    final phoneCtrl = TextEditingController(text: profile.ownerPhone);
    final emailCtrl = TextEditingController(text: profile.ownerEmail);
    final venueNameCtrl = TextEditingController(text: profile.venueName);
    final addressCtrl = TextEditingController(text: profile.address);
    final areaCtrl = TextEditingController(text: profile.area);
    final dayRateCtrl =
        TextEditingController(text: profile.dayRate.toStringAsFixed(0));
    final nightRateCtrl =
        TextEditingController(text: profile.nightRate.toStringAsFixed(0));
    final weekdayRateCtrl =
        TextEditingController(text: profile.weekdayRate.toStringAsFixed(0));
    final weekendRateCtrl =
        TextEditingController(text: profile.weekendRate.toStringAsFixed(0));

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
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.primary)),
              const SizedBox(height: 12),
              AppTextField(label: 'Owner Full Name', controller: ownerNameCtrl),
              const SizedBox(height: 10),
              AppTextField(
                  label: 'Phone Number',
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 10),
              AppTextField(
                  label: 'Email Address',
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 10),
              AppTextField(
                  label: 'Turf / Venue Business Name',
                  controller: venueNameCtrl),
              const SizedBox(height: 10),
              AppTextField(label: 'Full Address', controller: addressCtrl),
              const SizedBox(height: 10),
              AppTextField(label: 'Area / Landmark', controller: areaCtrl),
              const SizedBox(height: 16),
              const Text('Hourly Rates Setup (₹)',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.primary)),
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final newOwnerName = ownerNameCtrl.text.trim();
              final newPhone = phoneCtrl.text.trim();
              final newEmail = emailCtrl.text.trim();
              final newVenueName = venueNameCtrl.text.trim();
              final newAddress = addressCtrl.text.trim();
              final newArea = areaCtrl.text.trim();
              final dayR = double.tryParse(dayRateCtrl.text.trim()) ??
                  profile.dayRate;
              final nightR = double.tryParse(nightRateCtrl.text.trim()) ??
                  profile.nightRate;
              final wkdayR = double.tryParse(weekdayRateCtrl.text.trim()) ??
                  profile.weekdayRate;
              final wkendR = double.tryParse(weekendRateCtrl.text.trim()) ??
                  profile.weekendRate;

              await ref
                  .read(turfProfileProvider.notifier)
                  .updateProfileDetails(
                    ownerName: newOwnerName,
                    ownerPhone: newPhone,
                    ownerEmail: newEmail,
                    venueName: newVenueName,
                    address: newAddress,
                    area: newArea,
                    dayRate: dayR,
                    nightRate: nightR,
                    weekdayRate: wkdayR,
                    weekendRate: wkendR,
                  );

              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ToastUtils.showSuccess(
                    context, 'Turf Profile details updated successfully!');
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

    final openOptions = [
      '24 Hours',
      '05:00 AM',
      '06:00 AM',
      '07:00 AM',
      '08:00 AM',
      '09:00 AM'
    ];
    final closeOptions = [
      '24 Hours',
      '09:00 PM',
      '10:00 PM',
      '11:00 PM',
      '11:30 PM',
      '12:00 AM',
      '01:00 AM (Overnight)'
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (wkdayOpen != '24 Hours') ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Weekdays (Mon - Fri)',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                  fontSize: 13)),
                          const SizedBox(height: 10),
                          Column(
                            children: [
                              DropdownButtonFormField<String>(
                                isExpanded: true,
                                initialValue:
                                    openOptions.contains(wkdayOpen)
                                        ? wkdayOpen
                                        : openOptions[1],
                                decoration: InputDecoration(
                                  labelText: 'Opens at',
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                  border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(10)),
                                ),
                                items: openOptions
                                    .map((t) => DropdownMenuItem(
                                        value: t,
                                        child: Text(t,
                                            style: const TextStyle(fontSize: 13),
                                            overflow: TextOverflow.ellipsis)))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setDialogState(() => wkdayOpen = val);
                                  }
                                },
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                isExpanded: true,
                                initialValue:
                                    closeOptions.contains(wkdayClose)
                                        ? wkdayClose
                                        : closeOptions[2],
                                decoration: InputDecoration(
                                  labelText: 'Closes at',
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                  border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(10)),
                                ),
                                items: closeOptions
                                    .map((t) => DropdownMenuItem(
                                        value: t,
                                        child: Text(t,
                                            style: const TextStyle(fontSize: 13),
                                            overflow: TextOverflow.ellipsis)))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setDialogState(() => wkdayClose = val);
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.secondary.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Weekends (Sat - Sun)',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.secondary,
                                  fontSize: 13)),
                          const SizedBox(height: 10),
                          Column(
                            children: [
                              DropdownButtonFormField<String>(
                                isExpanded: true,
                                initialValue:
                                    openOptions.contains(wkendOpen)
                                        ? wkendOpen
                                        : openOptions[0],
                                decoration: InputDecoration(
                                  labelText: 'Opens at',
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                  border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(10)),
                                ),
                                items: openOptions
                                    .map((t) => DropdownMenuItem(
                                        value: t,
                                        child: Text(t,
                                            style: const TextStyle(fontSize: 13),
                                            overflow: TextOverflow.ellipsis)))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setDialogState(() => wkendOpen = val);
                                  }
                                },
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                isExpanded: true,
                                initialValue:
                                    closeOptions.contains(wkendClose)
                                        ? wkendClose
                                        : closeOptions[3],
                                decoration: InputDecoration(
                                  labelText: 'Closes at',
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                  border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(10)),
                                ),
                                items: closeOptions
                                    .map((t) => DropdownMenuItem(
                                        value: t,
                                        child: Text(t,
                                            style: const TextStyle(fontSize: 13),
                                            overflow: TextOverflow.ellipsis)))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setDialogState(() => wkendClose = val);
                                  }
                                },
                              ),
                            ],
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                ref.read(turfProfileProvider.notifier).updateOperatingHours(
                      weekdayOpening: wkdayOpen,
                      weekdayClosing: wkdayClose,
                      weekendOpening: wkendOpen,
                      weekendClosing: wkendClose,
                    );
                ref.read(adminSlotProvider.notifier).updateOperatingHours(
                    wkdayOpen, wkdayClose, wkendOpen, wkendClose);
                Navigator.pop(ctx);
                ToastUtils.showSuccess(context, 'Operating timings updated!');
              },
              child: const Text('Save Timings'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSportDialog() {
    final popularSports = [
      'Cricket',
      'Football',
      'Pickleball',
      'Badminton',
      'Others'
    ];
    String selectedSportName = popularSports.first;
    final rateCtrl = TextEditingController(text: '1200');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.sports_soccer_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Add New Sport Offering',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Sport:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: selectedSportName,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: popularSports
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() => selectedSportName = val);
                  }
                },
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Base Rate per Hour (₹)',
                controller: rateCtrl,
                keyboardType: TextInputType.number,
              ),
            ],
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                final rate = double.tryParse(rateCtrl.text.trim()) ?? 1200.0;
                ref.read(turfProfileProvider.notifier).addSport(
                      TurfSportItem(
                        name: selectedSportName,
                        hourlyRate: rate,
                        weekdayRate: rate,
                        weekendRate: rate * 1.2,
                        nightRate: rate * 1.1,
                        courtsAvailable: 1,
                      ),
                    );
                Navigator.pop(ctx);
                ToastUtils.showSuccess(
                    context, 'Added $selectedSportName to venue offerings!');
              },
              child: const Text('Add Sport'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddVenueCourtDialog(TurfProfileState profile) {
    final courtNameCtrl = TextEditingController();
    final sizeCtrl = TextEditingController(text: '7-a-side (90x60 ft)');
    final surfaceCtrl =
        TextEditingController(text: 'FIFA Pro 50mm Monofilament');
    final rateCtrl = TextEditingController(text: '1200');
    final sportsList =
        profile.sports.isNotEmpty ? profile.sports.map((s) => s.name).toList() : ['Football', 'Cricket'];
    String selectedSport = sportsList.first;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.add_business_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Register Arena / Court',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                    label: 'Court / Pitch Name (e.g. Arena Alpha)',
                    controller: courtNameCtrl),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: selectedSport,
                  decoration: InputDecoration(
                    labelText: 'Sport Category',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                  items: sportsList
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedSport = val);
                    }
                  },
                ),
                const SizedBox(height: 10),
                AppTextField(label: 'Pitch Dimensions', controller: sizeCtrl),
                const SizedBox(height: 10),
                AppTextField(label: 'Surface Type', controller: surfaceCtrl),
                const SizedBox(height: 10),
                AppTextField(
                  label: 'Base Rate (₹/hr)',
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                final name = courtNameCtrl.text.trim();
                if (name.isEmpty) {
                  ToastUtils.showError(context, 'Please enter a court name');
                  return;
                }
                final rate = double.tryParse(rateCtrl.text.trim()) ?? 1200.0;
                final newCourt = TurfCourtVenueItem(
                  id: 'CR-${DateTime.now().millisecondsSinceEpoch}',
                  name: name,
                  sport: selectedSport,
                  sports: [selectedSport],
                  surface: surfaceCtrl.text.trim().isNotEmpty
                      ? surfaceCtrl.text.trim()
                      : 'FIFA Pro 50mm Monofilament',
                  hourlyRate: rate,
                  timings: profile.weekdayOpeningTime == '24 Hours'
                      ? '24 Hours Open'
                      : '${profile.weekdayOpeningTime} - ${profile.weekdayClosingTime}',
                );
                ref.read(turfProfileProvider.notifier).addCourtVenue(newCourt);
                Navigator.pop(ctx);
                ToastUtils.showSuccess(context, 'Registered arena: $name');
              },
              child: const Text('Add Court'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditTurfDialog() {
    ToastUtils.showSuccess(
        context, 'Turf specifications & amenities verified up-to-date.');
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
                  // 1. Subscription Plan Breakdown
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
                                profile.isSubscriptionActive
                                    ? 'ACTIVE'
                                    : 'EXPIRED',
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
                                          fontSize: 12,
                                          color: Color(0xFF475569)),
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
                                          fontSize: 12,
                                          color: Color(0xFF475569)),
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
                              padding:
                                  const EdgeInsets.symmetric(vertical: 13),
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
                    ...profile.subscriptionHistory.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          const Icon(
                                              Icons.check_circle_rounded,
                                              size: 16,
                                              color: Color(0xFF16A34A)),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              item.id,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                  color: Color(0xFF111827)),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDCFCE7),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        item.status.toUpperCase(),
                                        style: const TextStyle(
                                            color: Color(0xFF166534),
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Date: ${item.date}',
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF4B5563)),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Valid: ${item.validPeriod}',
                                            style: const TextStyle(
                                                fontSize: 10.5,
                                                color: Colors.grey),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '₹${item.totalAmount.toInt()}',
                                          style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF166534)),
                                        ),
                                        const Text('₹1000 + 18% GST',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey)),
                                      ],
                                    ),
                                  ],
                                ),
                                const Divider(height: 14),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        'Receipt: #${item.receiptNumber}',
                                        style: const TextStyle(
                                            fontSize: 10.5,
                                            color: Color(0xFF6B7280),
                                            fontFamily: 'monospace'),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'PAID ONLINE',
                                      style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF166534)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 22),
            SizedBox(width: 8),
            Text('Logout Confirmation',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out of your Games24 Partner Hub account?',
          style: TextStyle(fontSize: 13.5, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('owner_logged_in', false);
      await prefs.remove('owner_phone');
      await prefs.remove('verified_admin_data');
      await prefs.remove('owner_venue_name');
      ref.read(isAdminModeProvider.notifier).setMode(false);
      if (mounted) {
        context.go('/login');
      }
    }
  }

  void _showKycDetailsBottomSheet(TurfProfileState profile) {
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
                      color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shield_rounded, color: Color(0xFF0F766E), size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'KYC & Legal Tax Records',
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
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
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
                                '🔒 Verified Legal Identity Locked',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.warning,
                                  fontSize: 13,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Aadhaar, PAN Card, and GSTIN details were verified during partner registration and are locked for tax compliance. Contact Super Admin to request updates.',
                                style: TextStyle(fontSize: 11, color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildKycDisplayCard(
                    title: 'GSTIN Business Registration Number',
                    value: profile.gstin.isNotEmpty ? profile.gstin : '33AAAAA0000A1Z5',
                    icon: Icons.receipt_rounded,
                    badge: 'Verified GSTIN',
                  ),
                  const SizedBox(height: 12),
                  _buildKycDisplayCard(
                    title: 'Owner PAN Card Number',
                    value: profile.pan.isNotEmpty ? profile.pan : 'ABCDE1234F',
                    icon: Icons.badge_rounded,
                    badge: 'PAN Verified',
                  ),
                  const SizedBox(height: 12),
                  _buildKycDisplayCard(
                    title: 'Owner Aadhaar Identity Number',
                    value: profile.aadhaar.isNotEmpty ? profile.aadhaar : 'XXXX-XXXX-4589',
                    icon: Icons.credit_card_rounded,
                    badge: 'Aadhaar Verified',
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.account_balance_rounded, color: Color(0xFF154D36), size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Automated Payout Bank Account',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                            Icon(Icons.lock, size: 13, color: Colors.grey),
                          ],
                        ),
                        const Divider(height: 20),
                        _buildReadOnlyKycField('Bank Account Number', profile.bankAccount.isNotEmpty ? profile.bankAccount : '9876543210012'),
                        const SizedBox(height: 10),
                        _buildReadOnlyKycField('IFSC Code', profile.ifsc.isNotEmpty ? profile.ifsc : 'HDFC0001234'),
                        const SizedBox(height: 10),
                        _buildReadOnlyKycField('Payout UPI ID', profile.upiId.isNotEmpty ? profile.upiId : 'owner@okhdfcbank'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBookingArchiveBottomSheet(TurfProfileState profile) {
    String localFilter = 'All';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final filteredBookings = profile.bookingHistory.where((b) {
            if (localFilter == 'All') return true;
            return b.status.toLowerCase() == localFilter.toLowerCase();
          }).toList();

          return Container(
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
                          color: const Color(0xFF1D4ED8).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF1D4ED8), size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Booking Archive (${profile.bookingHistory.length})',
                          style: const TextStyle(
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['All', 'Confirmed', 'Checked-In', 'Completed', 'Cancelled'].map((status) {
                        final isSelected = localFilter == status;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(status),
                            selected: isSelected,
                            selectedColor: const Color(0xFF154D36),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : const Color(0xFF334155),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              fontSize: 12,
                            ),
                            backgroundColor: Colors.white,
                            onSelected: (selected) {
                              if (selected) {
                                setSheetState(() => localFilter = status);
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const Divider(height: 1),
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
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                          itemCount: filteredBookings.length,
                          itemBuilder: (context, index) {
                            final item = filteredBookings[index];
                            Color statusColor = AppColors.success;
                            if (item.status.toLowerCase().contains('confirmed')) statusColor = const Color(0xFF154D36);
                            if (item.status.toLowerCase().contains('checked')) statusColor = const Color(0xFF0284C7);
                            if (item.status.toLowerCase().contains('cancel')) statusColor = AppColors.error;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        item.id,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
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
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.person_rounded, size: 16, color: Color(0xFF154D36)),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          '${item.customerName} (${item.customerPhone})',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
                                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569)),
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
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        '₹${item.amount.toStringAsFixed(0)} (${item.paymentMethod})',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF154D36),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildKycDisplayCard({
    required String title,
    required String value,
    required IconData icon,
    required String badge,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(icon, color: const Color(0xFF0F766E), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.lock, size: 13, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyKycField(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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
}
