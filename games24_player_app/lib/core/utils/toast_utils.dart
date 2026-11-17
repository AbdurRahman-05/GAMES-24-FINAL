import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum ToastType { success, error, warning, info }

class ToastUtils {
  static void showSuccess(BuildContext context, String message) {
    _showLuxuryToast(
      context: context,
      message: message,
      type: ToastType.success,
    );
  }

  static void showError(BuildContext context, String message) {
    _showLuxuryToast(
      context: context,
      message: message,
      type: ToastType.error,
    );
  }

  static void showWarning(BuildContext context, String message) {
    _showLuxuryToast(
      context: context,
      message: message,
      type: ToastType.warning,
    );
  }

  static void showInfo(BuildContext context, String message) {
    _showLuxuryToast(
      context: context,
      message: message,
      type: ToastType.info,
    );
  }

  static void _showLuxuryToast({
    required BuildContext context,
    required String message,
    required ToastType type,
  }) {
    HapticFeedback.lightImpact();

    late final Color accentColor;
    late final Color badgeBgColor;
    late final Color borderColor;
    late final List<Color> gradientColors;
    late final IconData icon;
    late final String label;

    switch (type) {
      case ToastType.success:
        accentColor = const Color(0xFF86EFAC);
        badgeBgColor = const Color(0xFF1B2E18);
        borderColor = const Color(0xFF38522A);
        gradientColors = const [Color(0xFF161E14), Color(0xFF0F150D)];
        icon = Icons.verified_rounded;
        label = 'SUCCESS';
        break;
      case ToastType.error:
        accentColor = const Color(0xFFF87171);
        badgeBgColor = const Color(0xFF2E1717);
        borderColor = const Color(0xFF552222);
        gradientColors = const [Color(0xFF201313), Color(0xFF140B0B)];
        icon = Icons.error_outline_rounded;
        label = 'ALERT';
        break;
      case ToastType.warning:
        accentColor = const Color(0xFFFBBF24);
        badgeBgColor = const Color(0xFF2E2413);
        borderColor = const Color(0xFF55411E);
        gradientColors = const [Color(0xFF1E190E), Color(0xFF141008)];
        icon = Icons.warning_amber_rounded;
        label = 'NOTICE';
        break;
      case ToastType.info:
        accentColor = const Color(0xFF38BDF8);
        badgeBgColor = const Color(0xFF132330);
        borderColor = const Color(0xFF1F3D55);
        gradientColors = const [Color(0xFF0E1A22), Color(0xFF091116)];
        icon = Icons.info_outline_rounded;
        label = 'INFO';
        break;
    }

    final snackBar = SnackBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 92),
      padding: EdgeInsets.zero,
      duration: const Duration(milliseconds: 3200),
      dismissDirection: DismissDirection.horizontal,
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.55),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: accentColor.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Glowing Badge Icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: badgeBgColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: borderColor,
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                color: accentColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Ambient Live Indicator Dot
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.8),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger != null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(snackBar);
    }
  }
}
