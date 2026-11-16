import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'toast_utils.dart';

class PhoneDialer {
  /// Opens the device's native phone dialer with [phoneNumber] ready to call.
  static Future<bool> call(
    BuildContext context,
    String phoneNumber, {
    String? customerName,
  }) async {
    final cleanNumber = phoneNumber.trim().replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanNumber.isEmpty) {
      if (context.mounted) {
        ToastUtils.showError(
          context,
          'No valid phone number found for ${customerName ?? "customer"}.',
        );
      }
      return false;
    }

    final Uri dialUri = Uri(scheme: 'tel', path: cleanNumber);

    try {
      final launched = await launchUrl(
        dialUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        final fallbackLaunched = await launchUrl(dialUri);
        if (!fallbackLaunched && context.mounted) {
          ToastUtils.showError(
            context,
            'Unable to open phone dialer for $cleanNumber.',
          );
          return false;
        }
      }
      return true;
    } catch (e) {
      try {
        await launchUrl(dialUri);
        return true;
      } catch (err) {
        if (context.mounted) {
          ToastUtils.showError(
            context,
            'Could not launch dialer for $cleanNumber: $err',
          );
        }
        return false;
      }
    }
  }
}
