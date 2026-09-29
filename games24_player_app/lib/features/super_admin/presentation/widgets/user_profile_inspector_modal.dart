import 'package:flutter/material.dart';
import 'package:games24_player_app/core/utils/toast_utils.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../providers/super_admin_providers.dart';

class UserProfileInspectorModal extends StatelessWidget {
  final UserAccountModel user;
  final VoidCallback onToggleBlock;

  const UserProfileInspectorModal({
    super.key,
    required this.user,
    required this.onToggleBlock,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isBlocked = user.status == AccountStatus.blocked;

    return Container(
      constraints: const BoxConstraints(maxWidth: 550),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Modal Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: isBlocked
                        ? AppColors.error.withValues(alpha: 0.15)
                        : AppColors.primary.withValues(alpha: 0.1),
                    child: Icon(
                      isBlocked ? Icons.block_rounded : Icons.person_rounded,
                      color: isBlocked ? AppColors.error : AppColors.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Text(user.phone, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // User Key Stats Card
          AppCard(
            color: isDark ? AppColors.cardDark : Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Text('Total Spend', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      const SizedBox(height: 2),
                      Text('₹${user.totalBookings * 340}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                    ],
                  ),
                ),
                Container(width: 1, height: 32, color: Colors.grey[300]),
                Expanded(
                  child: Column(
                    children: [
                      const Text('Bookings', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      const SizedBox(height: 2),
                      Text('${user.totalBookings}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
                Container(width: 1, height: 32, color: Colors.grey[300]),
                Expanded(
                  child: Column(
                    children: [
                      const Text('Account Status', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      const SizedBox(height: 2),
                      Text(
                        isBlocked ? 'BLOCKED' : 'ACTIVE',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: isBlocked ? AppColors.error : AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Detailed Attributes Grid
          Text('Player Details & Activity', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          _buildDetailRow('Location Area:', '${user.area}, Madurai'),
          _buildDetailRow('Joined Platform:', user.joinedDate),
          _buildDetailRow('Favorite Sport:', 'Football (7v7)'),
          _buildDetailRow('Most Booked Turf:', 'Madurai Turf Arena (KK Nagar)'),
          _buildDetailRow('Payment Mode:', 'UPI / Google Pay Preferred'),
          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: isBlocked ? 'Unblock Account' : 'Block & Revoke Access',
                  type: isBlocked ? AppButtonType.primary : AppButtonType.outline,
                  icon: isBlocked ? Icons.lock_open_rounded : Icons.block_rounded,
                  onPressed: () {
                    onToggleBlock();
                    Navigator.pop(context);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  text: 'Send Direct Push',
                  icon: Icons.chat_rounded,
                  onPressed: () {
                    Navigator.pop(context);
                    ToastUtils.showSuccess(context, "Direct push notification sent to ${user.name}");
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
