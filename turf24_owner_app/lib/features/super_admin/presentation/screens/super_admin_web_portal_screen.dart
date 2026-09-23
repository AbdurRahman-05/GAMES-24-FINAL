import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../providers/super_admin_providers.dart';
import '../widgets/revenue_chart_widget.dart';
import '../widgets/sports_distribution_chart.dart';
import '../widgets/user_profile_inspector_modal.dart';

class SuperAdminWebPortalScreen extends ConsumerStatefulWidget {
  const SuperAdminWebPortalScreen({super.key});

  @override
  ConsumerState<SuperAdminWebPortalScreen> createState() =>
      _SuperAdminWebPortalScreenState();
}

class _SuperAdminWebPortalScreenState
    extends ConsumerState<SuperAdminWebPortalScreen> {
  int _activeNavIndex = 0;
  final TextEditingController _broadcastController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  double _platformCommission = 10.0;
  String _searchQuery = '';

  @override
  void dispose() {
    _broadcastController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _inspectUserProfile(UserAccountModel user) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: UserProfileInspectorModal(
          user: user,
          onToggleBlock: () {
            final newStatus = user.status == AccountStatus.blocked
                ? AccountStatus.active
                : AccountStatus.blocked;
            ref.read(superAdminProvider.notifier).updateUserStatus(user.id, newStatus);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(user.status == AccountStatus.blocked
                    ? '${user.name} Unblocked'
                    : '${user.name} Blocked from PlayHub'),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width >= 850;
    final superAdminState = ref.watch(superAdminProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      body: Row(
        children: [
          // Desktop Web Persistent Left Sidebar
          if (isDesktop) _buildWebSidebar(context, theme, isDark),

          // Main Web Portal Content Area
          Expanded(
            child: Column(
              children: [
                // Top Web Bar
                _buildWebTopBar(context, theme, isDark, isDesktop),

                // Web Page Content View
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: _buildSelectedNavView(
                        context, ref, superAdminState, theme, isDark),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Left Persistent Web Sidebar
  Widget _buildWebSidebar(BuildContext context, ThemeData theme, bool isDark) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          right: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Web Portal Brand Header
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppColors.heroGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PlayHub Admin',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'Web Control Portal',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Nav Items
          _buildSidebarNavItem(0, Icons.dashboard_rounded, 'Platform Telemetry'),
          _buildSidebarNavItem(1, Icons.verified_user_rounded, 'Turf Approvals (KYC)'),
          _buildSidebarNavItem(2, Icons.people_alt_rounded, 'User & Partner Access'),
          _buildSidebarNavItem(3, Icons.campaign_rounded, 'Broadcast Center'),
          _buildSidebarNavItem(4, Icons.payments_rounded, 'Commission Rules'),

          const Spacer(),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppButton(
              text: 'Exit Web Portal',
              icon: Icons.logout_rounded,
              type: AppButtonType.outline,
              height: 38,
              onPressed: () => context.go('/login'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarNavItem(int index, IconData icon, String label) {
    final isSelected = _activeNavIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: () => setState(() => _activeNavIndex = index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? AppColors.primary : Colors.grey[600],
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AppColors.primary : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Top Web Navigation Bar
  Widget _buildWebTopBar(
      BuildContext context, ThemeData theme, bool isDark, bool isDesktop) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Row(
        children: [
          if (!isDesktop)
            IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.dashboard_rounded),
                          title: const Text('Platform Telemetry'),
                          onTap: () {
                            setState(() => _activeNavIndex = 0);
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.verified_user_rounded),
                          title: const Text('Turf Approvals'),
                          onTap: () {
                            setState(() => _activeNavIndex = 1);
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.people_alt_rounded),
                          title: const Text('User Moderation'),
                          onTap: () {
                            setState(() => _activeNavIndex = 2);
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    'PlayHub Control Center',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isDesktop) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'WEB STANDALONE PORTAL',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Row(
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary,
                child: Icon(Icons.security_rounded, size: 18, color: Colors.white),
              ),
              if (isDesktop) ...[
                const SizedBox(width: 8),
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('App Owner Admin',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    Text('owner@playhub.in',
                        style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // Active View Content Switcher
  Widget _buildSelectedNavView(
    BuildContext context,
    WidgetRef ref,
    SuperAdminState state,
    ThemeData theme,
    bool isDark,
  ) {
    switch (_activeNavIndex) {
      case 0:
        return _buildPlatformTelemetryView(context, state, theme);
      case 1:
        return _buildTurfApprovalsView(context, ref, state, theme);
      case 2:
        return _buildUserAccessView(context, ref, state, theme);
      case 3:
        return _buildBroadcastView(context, theme);
      case 4:
        return _buildCommissionView(context, theme);
      default:
        return _buildPlatformTelemetryView(context, state, theme);
    }
  }

  // View 0: Telemetry Overview with Charts
  Widget _buildPlatformTelemetryView(
      BuildContext context, SuperAdminState state, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Platform Telemetry & Analytics',
                    style: theme.textTheme.displayMedium?.copyWith(fontSize: 22)),
                const SizedBox(height: 2),
                Text('Real-time server metrics across all 18 turfs in Madurai',
                    style: theme.textTheme.bodyMedium),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.wifi_tethering_rounded, size: 14, color: AppColors.success),
                  SizedBox(width: 6),
                  Text(
                    '18ms Ping • 99.98% Uptime',
                    style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // KPI Summary Cards
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 700;
            return isWide
                ? Row(
                    children: [
                      Expanded(
                        child: AppCard(
                          padding: const EdgeInsets.all(18),
                          color: AppColors.primary.withValues(alpha: 0.1),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total Platform GMV', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              const SizedBox(height: 6),
                              const Text('₹2,48,500', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.primary)),
                              const SizedBox(height: 4),
                              Text('₹24,850 Net Fee (${_platformCommission.toInt()}%)', style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AppCard(
                          padding: const EdgeInsets.all(18),
                          color: AppColors.secondary.withValues(alpha: 0.1),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Active Madurai Turfs', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              SizedBox(height: 6),
                              Text('18 Arenas', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                              SizedBox(height: 4),
                              Text('1 Pending KYC Approval', style: TextStyle(fontSize: 11, color: AppColors.secondary, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AppCard(
                          padding: const EdgeInsets.all(18),
                          color: AppColors.warning.withValues(alpha: 0.1),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Registered Players', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              SizedBox(height: 6),
                              Text('4,820 Users', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.warning)),
                              SizedBox(height: 4),
                              Text('Madurai City Region', style: TextStyle(fontSize: 11, color: AppColors.warning, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      AppCard(
                        padding: const EdgeInsets.all(16),
                        color: AppColors.primary.withValues(alpha: 0.1),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Platform GMV', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 4),
                            const Text('₹2,48,500', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
                            Text('₹24,850 Net Fee (${_platformCommission.toInt()}%)', style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      AppCard(
                        padding: const EdgeInsets.all(16),
                        color: AppColors.secondary.withValues(alpha: 0.1),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Active Madurai Turfs', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            SizedBox(height: 4),
                            Text('18 Arenas', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      AppCard(
                        padding: const EdgeInsets.all(16),
                        color: AppColors.warning.withValues(alpha: 0.1),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Registered Players', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            SizedBox(height: 4),
                            Text('4,820 Users', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.warning)),
                          ],
                        ),
                      ),
                    ],
                  );
          },
        ),
        const SizedBox(height: 24),

        // Visual Graphs Row (Revenue Growth & Sports Breakdown)
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 750;
            return isWide
                ? const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: RevenueChartWidget()),
                      SizedBox(width: 16),
                      Expanded(flex: 2, child: SportsDistributionChart()),
                    ],
                  )
                : const Column(
                    children: [
                      RevenueChartWidget(),
                      SizedBox(height: 16),
                      SportsDistributionChart(),
                    ],
                  );
          },
        ),
      ],
    );
  }

  // View 1: Turf Owner Approvals & KYC
  Widget _buildTurfApprovalsView(
      BuildContext context, WidgetRef ref, SuperAdminState state, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Turf Owner Onboarding & Verification',
            style: theme.textTheme.displayMedium?.copyWith(fontSize: 22)),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.partners.length,
          itemBuilder: (context, index) {
            final partner = state.partners[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: AppCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(partner.turfName,
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        _buildStatusBadge(partner.status),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('Owner: ${partner.ownerName} • Phone: ${partner.phone}', style: theme.textTheme.bodyMedium),
                    Text('GST Registration: ${partner.gstNumber} • Registered: ${partner.registeredDate}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        if (partner.status != AccountStatus.active)
                          Flexible(
                            child: AppButton(
                              text: 'Approve Venue Owner',
                              height: 38,
                              onPressed: () {
                                ref.read(superAdminProvider.notifier).updatePartnerStatus(
                                      partner.id,
                                      AccountStatus.active,
                                    );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('${partner.turfName} Approved!')),
                                );
                              },
                            ),
                          ),
                        if (partner.status != AccountStatus.active) const SizedBox(width: 12),
                        Flexible(
                          child: AppButton(
                            text: partner.status == AccountStatus.blocked ? 'Unblock Partner' : 'Block Partner',
                            type: partner.status == AccountStatus.blocked ? AppButtonType.primary : AppButtonType.outline,
                            height: 38,
                            onPressed: () {
                              final next = partner.status == AccountStatus.blocked
                                  ? AccountStatus.active
                                  : AccountStatus.blocked;
                              ref.read(superAdminProvider.notifier).updatePartnerStatus(partner.id, next);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(partner.status == AccountStatus.blocked ? '${partner.turfName} Unblocked' : '${partner.turfName} Blocked')),
                              );
                            },
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
      ],
    );
  }

  // View 2: User Access Directory (Tap to Inspect Profile)
  Widget _buildUserAccessView(
      BuildContext context, WidgetRef ref, SuperAdminState state, ThemeData theme) {
    final filteredUsers = state.users.where((u) {
      return u.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          u.phone.contains(_searchQuery);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('User Directory & Moderation Inspector', style: theme.textTheme.displayMedium?.copyWith(fontSize: 22)),
            const Text('(Tap user row to open full inspector modal)', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: 'Search Players or Users',
          hint: 'Search by name or phone...',
          prefixIcon: Icons.search_rounded,
          controller: _searchController,
          onChanged: (val) => setState(() => _searchQuery = val),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredUsers.length,
          itemBuilder: (context, index) {
            final user = filteredUsers[index];
            final isBlocked = user.status == AccountStatus.blocked;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                onTap: () => _inspectUserProfile(user),
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: isBlocked ? AppColors.error.withValues(alpha: 0.15) : AppColors.primary.withValues(alpha: 0.1),
                      child: Icon(isBlocked ? Icons.block_rounded : Icons.person_rounded, color: isBlocked ? AppColors.error : AppColors.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(user.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(width: 6),
                              const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.primary),
                            ],
                          ),
                          Text('${user.phone} • ${user.area}', style: theme.textTheme.bodySmall),
                          Text('${user.totalBookings} Turf Bookings • Joined ${user.joinedDate}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 110,
                      child: AppButton(
                        text: isBlocked ? 'Unblock' : 'Block User',
                        height: 36,
                        type: isBlocked ? AppButtonType.primary : AppButtonType.outline,
                        onPressed: () {
                          final newStatus = isBlocked ? AccountStatus.active : AccountStatus.blocked;
                          ref.read(superAdminProvider.notifier).updateUserStatus(user.id, newStatus);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(isBlocked ? '${user.name} Unblocked' : '${user.name} Blocked')),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // View 3: Broadcast Push Center
  Widget _buildBroadcastView(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Broadcast Platform Announcement', style: theme.textTheme.displayMedium?.copyWith(fontSize: 22)),
        const SizedBox(height: 6),
        const Text('Push an instant broadcast notification to all 4,820 Madurai sports players and venue owners.', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 20),
        AppTextField(
          label: 'Broadcast Title',
          hint: 'e.g. Madurai Super Box Cricket Cup Announced! 🏆',
          prefixIcon: Icons.campaign_rounded,
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Notification Message',
          hint: 'Register your 8-member team before Sunday to claim ₹500 discount...',
          maxLines: 3,
          controller: _broadcastController,
        ),
        const SizedBox(height: 24),
        AppButton(
          text: 'Send Web Broadcast Push Notification',
          icon: Icons.send_rounded,
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Broadcast push sent to 4,820 Madurai users!'), backgroundColor: AppColors.primary),
            );
            _broadcastController.clear();
          },
        ),
      ],
    );
  }

  // View 4: Commission Rules & Payout Center
  Widget _buildCommissionView(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Platform Commission Rate Settings & Payouts', style: theme.textTheme.displayMedium?.copyWith(fontSize: 22)),
        const SizedBox(height: 16),
        AppCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Global Commission Rate:'),
                  Text('${_platformCommission.toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 20)),
                ],
              ),
              Slider(
                value: _platformCommission,
                min: 5.0,
                max: 20.0,
                divisions: 15,
                activeColor: AppColors.primary,
                onChanged: (val) => setState(() => _platformCommission = val),
              ),
              AppButton(
                text: 'Save Web Commission Rules',
                height: 42,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Platform commission updated to ${_platformCommission.toInt()}%')),
                  );
                },
              ),
              const Divider(height: 32),
              Text('Weekly Partner Payout Disbursement', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Disburse ₹2,23,650 directly to 18 verified Madurai turf owner UPI bank accounts', style: TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 16),
              AppButton(
                text: 'Release Automated Weekly Payouts (₹2,23,650)',
                icon: Icons.account_balance_wallet_rounded,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Payouts disbursed to 18 turf owner bank accounts via UPI!'), backgroundColor: AppColors.success),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(AccountStatus status) {
    Color color = AppColors.success;
    String label = 'Active';

    if (status == AccountStatus.pending) {
      color = AppColors.warning;
      label = 'Pending KYC';
    } else if (status == AccountStatus.blocked) {
      color = AppColors.error;
      label = 'Blocked';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
