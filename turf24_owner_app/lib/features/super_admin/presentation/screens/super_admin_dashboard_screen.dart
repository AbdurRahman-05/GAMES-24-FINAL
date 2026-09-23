import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../providers/super_admin_providers.dart';

class SuperAdminDashboardScreen extends ConsumerStatefulWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  ConsumerState<SuperAdminDashboardScreen> createState() =>
      _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState
    extends ConsumerState<SuperAdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _broadcastController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  double _platformCommission = 10.0;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _broadcastController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final superAdminState = ref.watch(superAdminProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('PlayHub Owner Control Panel'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            onPressed: () => context.go('/login'),
            tooltip: 'Exit Super Admin',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(icon: Icon(Icons.verified_user_rounded), text: 'Turf Approvals'),
            Tab(icon: Icon(Icons.people_alt_rounded), text: 'User & Partner Access'),
            Tab(icon: Icon(Icons.campaign_rounded), text: 'Broadcast Center'),
            Tab(icon: Icon(Icons.payments_rounded), text: 'Commissions & Payouts'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Platform KPI Overview
            Row(
              children: [
                Expanded(
                  child: AppCard(
                    padding: const EdgeInsets.all(12),
                    color: AppColors.primary.withValues(alpha: 0.1),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Platform GMV', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        const SizedBox(height: 2),
                        const Text('₹2,48,500', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        Text('₹24,850 Fee (${_platformCommission.toInt()}%)', style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppCard(
                    padding: const EdgeInsets.all(12),
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Active Venues', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        SizedBox(height: 2),
                        Text('18 Turfs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                        Text('Madurai Total', style: TextStyle(fontSize: 10, color: AppColors.secondary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppCard(
                    padding: const EdgeInsets.all(12),
                    color: AppColors.warning.withValues(alpha: 0.1),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Players', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        SizedBox(height: 2),
                        Text('4,820', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.warning)),
                        Text('Active Enthusiasts', style: TextStyle(fontSize: 10, color: AppColors.warning, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Tab Views Container
            SizedBox(
              height: 520,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // TAB 1: Turf Owner Onboarding & Approvals
                  _buildTurfApprovalsTab(context, ref, superAdminState, theme),

                  // TAB 2: User & Partner Block/Unblock Access Directory
                  _buildUserAccessTab(context, ref, superAdminState, theme),

                  // TAB 3: Broadcast Notifications Center
                  _buildBroadcastTab(context, theme),

                  // TAB 4: Platform Commission & Payout Controls
                  _buildCommissionTab(context, theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Tab 1: Turf Owner Onboarding & Approvals
  Widget _buildTurfApprovalsTab(
    BuildContext context,
    WidgetRef ref,
    SuperAdminState state,
    ThemeData theme,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Turf Owner Verification Queue',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${state.partners.where((p) => p.status == AccountStatus.pending).length} Pending Verification',
                  style: const TextStyle(
                      color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.partners.length,
            itemBuilder: (context, index) {
              final partner = state.partners[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            partner.turfName,
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          _buildStatusChip(partner.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Owner: ${partner.ownerName} • Area: ${partner.area}, Madurai',
                          style: theme.textTheme.bodySmall),
                      Text('GST: ${partner.gstNumber} • Phone: ${partner.phone}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (partner.status != AccountStatus.active)
                            Expanded(
                              child: AppButton(
                                text: 'Approve Venue Owner',
                                height: 36,
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
                          if (partner.status != AccountStatus.active) const SizedBox(width: 8),
                          Expanded(
                            child: AppButton(
                              text: partner.status == AccountStatus.blocked
                                  ? 'Unblock Partner'
                                  : 'Block Partner',
                              type: partner.status == AccountStatus.blocked
                                  ? AppButtonType.primary
                                  : AppButtonType.outline,
                              height: 36,
                              onPressed: () {
                                final next = partner.status == AccountStatus.blocked
                                    ? AccountStatus.active
                                    : AccountStatus.blocked;
                                ref.read(superAdminProvider.notifier).updatePartnerStatus(
                                      partner.id,
                                      next,
                                    );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                    partner.status == AccountStatus.blocked
                                        ? '${partner.turfName} Unblocked'
                                        : '${partner.turfName} Blocked from Platform',
                                  )),
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
      ),
    );
  }

  // Tab 2: User Access (1-Tap Block / Unblock Users)
  Widget _buildUserAccessTab(
    BuildContext context,
    WidgetRef ref,
    SuperAdminState state,
    ThemeData theme,
  ) {
    final filteredUsers = state.users.where((u) {
      return u.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          u.phone.contains(_searchQuery);
    }).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Platform User Directory & Moderation',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          AppTextField(
            label: 'Search Players or Users',
            hint: 'Search by name or phone...',
            prefixIcon: Icons.search_rounded,
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
          const SizedBox(height: 14),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredUsers.length,
            itemBuilder: (context, index) {
              final user = filteredUsers[index];
              final isBlocked = user.status == AccountStatus.blocked;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: isBlocked
                            ? AppColors.error.withValues(alpha: 0.15)
                            : AppColors.primary.withValues(alpha: 0.1),
                        child: Icon(
                          isBlocked ? Icons.block_rounded : Icons.person_rounded,
                          color: isBlocked ? AppColors.error : AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                            Text('${user.phone} • ${user.area}', style: theme.textTheme.bodySmall),
                            Text('${user.totalBookings} Turf Bookings • Joined ${user.joinedDate}',
                                style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 95,
                        child: AppButton(
                          text: isBlocked ? 'Unblock' : 'Block User',
                          height: 32,
                          type: isBlocked ? AppButtonType.primary : AppButtonType.outline,
                          onPressed: () {
                            final newStatus = isBlocked ? AccountStatus.active : AccountStatus.blocked;
                            ref.read(superAdminProvider.notifier).updateUserStatus(user.id, newStatus);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isBlocked
                                    ? '${user.name} Unblocked'
                                    : '${user.name} Blocked from PlayHub'),
                              ),
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
      ),
    );
  }

  // Tab 3: Broadcast Announcements
  Widget _buildBroadcastTab(BuildContext context, ThemeData theme) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Broadcast Platform Announcement',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text(
            'Push an instant notification banner to all 4,820 Madurai sports players and venue owners.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Announcement Title',
            hint: 'e.g. Madurai Super Box Cricket Tournament Cup Announced! 🏆',
            prefixIcon: Icons.campaign_rounded,
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'Notification Message Body',
            hint: 'Register your 8-member team before Sunday to claim ₹500 early bird discount...',
            maxLines: 3,
            controller: _broadcastController,
          ),
          const SizedBox(height: 20),
          AppButton(
            text: 'Send Broadcast Push Notification',
            icon: Icons.send_rounded,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Broadcast push sent to 4,820 Madurai users!'),
                  backgroundColor: AppColors.primary,
                ),
              );
              _broadcastController.clear();
            },
          ),
        ],
      ),
    );
  }

  // Tab 4: Platform Commission Controls
  Widget _buildCommissionTab(BuildContext context, ThemeData theme) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Platform Commission Rate',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Set global percentage fee collected by PlayHub Madurai on venue bookings',
              style: TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Global Commission Rate:'),
                    Text('${_platformCommission.toInt()}%',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 18)),
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
                  text: 'Update Commission Rule',
                  height: 40,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Platform commission updated to ${_platformCommission.toInt()}%')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(AccountStatus status) {
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
