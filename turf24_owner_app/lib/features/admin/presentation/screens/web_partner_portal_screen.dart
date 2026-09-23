import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../providers/admin_providers.dart';
import '../widgets/admin_kpi_card.dart';

class WebPartnerPortalScreen extends ConsumerStatefulWidget {
  const WebPartnerPortalScreen({super.key});

  @override
  ConsumerState<WebPartnerPortalScreen> createState() =>
      _WebPartnerPortalScreenState();
}

class _WebPartnerPortalScreenState
    extends ConsumerState<WebPartnerPortalScreen> {
  int _selectedWebTab = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDesktopWeb = MediaQuery.of(context).size.width >= 800;
    final adminSlotState = ref.watch(adminSlotProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.language_rounded, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PlayHub Madurai - Turf Owner Web Portal',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Desktop Web Console • Madurai Turf Arena',
                  style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.black54),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => context.push('/super-admin/login'),
            icon: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.secondary, size: 18),
            label: const Text('Super Admin Web', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => context.go('/main'),
            icon: const Icon(Icons.phone_android_rounded, size: 16),
            label: const Text('Return to Mobile App'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          // Left Desktop Sidebar
          if (isDesktopWeb)
            Container(
              width: 240,
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.white,
                border: Border(
                  right: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _WebSidebarTile(
                    icon: Icons.dashboard_rounded,
                    label: 'Web Dashboard',
                    isSelected: _selectedWebTab == 0,
                    onTap: () => setState(() => _selectedWebTab = 0),
                  ),
                  _WebSidebarTile(
                    icon: Icons.edit_calendar_rounded,
                    label: 'Turf Slot Grid',
                    isSelected: _selectedWebTab == 1,
                    onTap: () => setState(() => _selectedWebTab = 1),
                  ),
                  _WebSidebarTile(
                    icon: Icons.qr_code_scanner_rounded,
                    label: 'Gate Check-in Terminal',
                    isSelected: _selectedWebTab == 2,
                    onTap: () => setState(() => _selectedWebTab = 2),
                  ),
                  const Spacer(),
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.laptop_mac_rounded, color: AppColors.primary),
                        SizedBox(height: 6),
                        Text('Web Desk Verified', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
                        Text('playhub.in/partner-web', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Main Web Canvas
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: IndexedStack(
                index: _selectedWebTab,
                children: [
                  // Tab 0: Web Analytics Dashboard
                  _buildWebAnalyticsTab(context, theme),

                  // Tab 1: Web Widescreen Slot Calendar Manager
                  _buildWebSlotsTab(context, theme, adminSlotState),

                  // Tab 2: Web Gate Check-in Terminal
                  _buildWebQrTerminalTab(context, theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebAnalyticsTab(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Turf Revenue & Slot Occupancy (Web Analytics)',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('Live Web Sync Active 🟢',
                  style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 20),
        GridView.count(
          crossAxisCount: MediaQuery.of(context).size.width > 1100 ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.4,
          children: const [
            AdminKpiCard(
              title: 'Today\'s Revenue',
              value: '₹14,800',
              subtitle: 'vs ₹12,100 yesterday',
              icon: Icons.currency_rupee_rounded,
              color: AppColors.primary,
              badgeText: '+22.3%',
            ),
            AdminKpiCard(
              title: 'Slot Occupancy',
              value: '88%',
              subtitle: '22 / 25 slots booked',
              icon: Icons.pie_chart_rounded,
              color: AppColors.secondary,
              badgeText: 'High Demand',
            ),
            AdminKpiCard(
              title: 'Bookings Today',
              value: '18',
              subtitle: '14 paid via UPI',
              icon: Icons.confirmation_number_rounded,
              color: Color(0xFF06B6D4),
              badgeText: 'Active',
            ),
            AdminKpiCard(
              title: 'Gate Check-ins',
              value: '4 Pending',
              subtitle: 'Arriving before 09 PM',
              icon: Icons.directions_run_rounded,
              color: AppColors.warning,
              badgeText: 'Ready',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWebSlotsTab(BuildContext context, ThemeData theme, AdminSlotState slotState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Web Widescreen Turf Slot Manager', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Manage Court Availability for Madurai Turf Arena', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  '06:00 AM - 07:00 AM',
                  '07:00 AM - 08:00 AM',
                  '08:00 AM - 09:00 AM',
                  '04:00 PM - 05:00 PM',
                  '05:00 PM - 06:00 PM',
                  '06:00 PM - 07:00 PM',
                  '07:00 PM - 08:00 PM',
                  '08:00 PM - 09:00 PM',
                ].map((s) {
                  final today = DateTime.now();
                  final dateKey = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
                  final isBlocked = slotState.getBlockedSlotsForDate(dateKey).contains(s);
                  return FilterChip(
                    label: Text(s),
                    selected: isBlocked,
                    selectedColor: AppColors.warning.withValues(alpha: 0.2),
                    onSelected: (_) {
                      ref.read(adminSlotProvider.notifier).toggleBlockSlot(s, dateKey);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWebQrTerminalTab(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Web Entry Gate Verification Terminal', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            children: [
              const Icon(Icons.qr_code_scanner_rounded, size: 64, color: AppColors.primary),
              const SizedBox(height: 12),
              const Text('Scan Customer Pass or Enter Booking Code', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              AppButton(
                text: 'Simulate Web Gate Verification Pass',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gate Ticket BK-99214 Verified ✅')),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WebSidebarTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _WebSidebarTile({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          dense: true,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: Icon(icon, color: isSelected ? AppColors.primary : Colors.grey, size: 20),
          title: Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppColors.primary : null,
              fontSize: 13,
            ),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
