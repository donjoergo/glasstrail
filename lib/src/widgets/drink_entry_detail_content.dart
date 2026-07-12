import 'package:flutter/material.dart';
import 'package:glasstrail/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import '../app_scope.dart';
import '../l10n_extensions.dart';
import '../models.dart';
import 'app_media.dart';

/// Shared drink entry detail body used by the statistics map sheet, the map
/// overlay panel, and the master-detail panes.
///
/// Renders only the content column — the host decides scroll behavior and
/// padding. Widget keys are built from [keyPrefix] so the original
/// `statistics-map-sheet-*` test keys keep working by default.
class DrinkEntryDetailContent extends StatelessWidget {
  const DrinkEntryDetailContent({
    super.key,
    required this.entry,
    required this.accentColor,
    this.keyPrefix = 'statistics-map-sheet',
  });

  final DrinkEntry entry;
  final Color accentColor;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.controllerOf(context);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final localeCode = controller.settings.localeCode;
    final unit = controller.settings.unit;
    final drinkName = controller.localizedEntryDrinkName(
      entry,
      localeCode: localeCode,
    );
    final categoryLabel = <String>[
      l10n.categoryLabel(entry.category),
      if (entry.shouldShowAlcoholFreeMarker) l10n.alcoholFree,
    ].join(' • ');
    final timeLabel = DateFormat.yMMMd(
      localeCode,
    ).add_Hm().format(entry.consumedAt);
    final volumeLabel = entry.volumeMl == null
        ? null
        : unit.formatVolume(entry.volumeMl);
    final locationAddress = normalizeLocationAddress(entry.locationAddress);
    final comment = nonEmptyTrimmed(entry.comment);
    final imagePath = nonEmptyTrimmed(entry.imagePath);

    return Column(
      key: Key('$keyPrefix-${entry.id}'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            CircleAvatar(
              radius: 24,
              backgroundColor: accentColor.withValues(alpha: 0.16),
              foregroundColor: accentColor,
              child: Icon(entry.category.icon),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    drinkName,
                    key: Key('$keyPrefix-name-${entry.id}'),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    categoryLabel,
                    key: Key('$keyPrefix-category-${entry.id}'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timeLabel,
                    key: Key('$keyPrefix-time-${entry.id}'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (volumeLabel != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  volumeLabel,
                  key: Key('$keyPrefix-volume-${entry.id}'),
                ),
              ),
          ],
        ),
        if (locationAddress != null) ...<Widget>[
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(Icons.location_on_outlined, size: 18, color: accentColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  locationAddress,
                  key: Key('$keyPrefix-location-${entry.id}'),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ],
        if (comment != null) ...<Widget>[
          const SizedBox(height: 18),
          Text(
            l10n.comment,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(comment, key: Key('$keyPrefix-comment-${entry.id}')),
        ],
        if (imagePath != null) ...<Widget>[
          const SizedBox(height: 18),
          AppPhotoPreview(
            key: Key('$keyPrefix-image-${entry.id}'),
            imagePath: imagePath,
            cropPortraitToSquare: true,
            enableFullscreenOnTap: true,
          ),
        ],
      ],
    );
  }
}
