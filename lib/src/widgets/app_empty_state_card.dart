import 'package:flutter/material.dart';

class AppEmptyStateCard extends StatelessWidget {
  const AppEmptyStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardPadding = compact ? 24.0 : 28.0;
    final iconPadding = compact ? 12.0 : 16.0;
    final iconSize = compact ? 32.0 : 36.0;
    final iconRadius = compact ? 16.0 : 20.0;
    final titleSpacing = compact ? 14.0 : 18.0;
    final bodySpacing = compact ? 8.0 : 10.0;

    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            padding: EdgeInsets.all(iconPadding),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(iconRadius),
            ),
            child: Icon(icon, size: iconSize, color: theme.colorScheme.primary),
          ),
          SizedBox(height: titleSpacing),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: bodySpacing),
          Text(
            body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
