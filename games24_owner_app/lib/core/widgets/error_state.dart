import 'package:flutter/material.dart';
import 'app_button.dart';

class ErrorState extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback onRetry;

  const ErrorState({
    super.key,
    this.title = 'Something Went Wrong',
    this.description = 'We could not load the sports data. Please try again.',
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 64, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text(title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(description, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          AppButton(
            text: 'Try Again',
            icon: Icons.refresh_rounded,
            onPressed: onRetry,
            isFullWidth: false,
          ),
        ],
      ),
    );
  }
}
