part of '../statistics_screen.dart';

class _StatisticsMapPanelSelection {
  const _StatisticsMapPanelSelection({required this.markers, this.detail});

  /// One marker means a single tapped marker; more mean a tapped cluster.
  final List<_StatisticsMapMarkerData> markers;

  /// Non-null shows the detail view instead of the cluster list.
  final _StatisticsMapMarkerData? detail;
}

/// Builds the private map entry panel for widget tests, which cannot
/// construct part-file private types directly.
@visibleForTesting
Widget buildStatisticsMapEntryPanelForTesting({
  required List<DrinkEntry> entries,
  DrinkEntry? detailEntry,
  required VoidCallback onClose,
  required ValueChanged<DrinkEntry> onDetailSelected,
  required VoidCallback onBackToList,
}) {
  _StatisticsMapMarkerData markerFor(DrinkEntry entry) {
    return _StatisticsMapMarkerData(
      entry: entry,
      position: maplibre.LatLng(
        entry.locationLatitude ?? 0,
        entry.locationLongitude ?? 0,
      ),
    );
  }

  return _StatisticsMapEntryPanel(
    selection: _StatisticsMapPanelSelection(
      markers: entries.map(markerFor).toList(growable: false),
      detail: detailEntry == null ? null : markerFor(detailEntry),
    ),
    onClose: onClose,
    onDetailSelected: (marker) => onDetailSelected(marker.entry),
    onBackToList: onBackToList,
  );
}

class _StatisticsMapEntryPanel extends StatelessWidget {
  const _StatisticsMapEntryPanel({
    required this.selection,
    required this.onClose,
    required this.onDetailSelected,
    required this.onBackToList,
  });

  final _StatisticsMapPanelSelection selection;
  final VoidCallback onClose;
  final ValueChanged<_StatisticsMapMarkerData> onDetailSelected;
  final VoidCallback onBackToList;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final materialL10n = MaterialLocalizations.of(context);
    final theme = Theme.of(context);
    final detail = selection.detail;
    final showBack = detail != null && selection.markers.length > 1;

    return Material(
      key: const Key('statistics-map-panel'),
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 8, 0),
            child: Row(
              children: <Widget>[
                if (showBack)
                  IconButton(
                    key: const Key('statistics-map-panel-back'),
                    tooltip: materialL10n.backButtonTooltip,
                    onPressed: onBackToList,
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                Expanded(
                  child: detail == null
                      ? Padding(
                          padding: const EdgeInsetsDirectional.only(start: 12),
                          child: Text(
                            l10n.statisticsMapClusterTitle(
                              selection.markers.length,
                            ),
                            key: const Key('statistics-map-panel-title'),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                IconButton(
                  key: const Key('statistics-map-panel-close'),
                  tooltip: materialL10n.closeButtonTooltip,
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Flexible(
            child: detail != null
                ? SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                    child: DrinkEntryDetailContent(
                      entry: detail.entry,
                      accentColor: statisticsCategoryColors(
                        theme,
                      )[detail.entry.category]!,
                      keyPrefix: 'statistics-map-panel',
                    ),
                  )
                : _StatisticsMapPanelList(
                    markers: selection.markers,
                    onDetailSelected: onDetailSelected,
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatisticsMapPanelList extends StatelessWidget {
  const _StatisticsMapPanelList({
    required this.markers,
    required this.onDetailSelected,
  });

  final List<_StatisticsMapMarkerData> markers;
  final ValueChanged<_StatisticsMapMarkerData> onDetailSelected;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.controllerOf(context);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final localeCode = controller.settings.localeCode;
    final unit = controller.settings.unit;
    final colors = statisticsCategoryColors(theme);
    final sortedMarkers = markers.toList()
      ..sort((a, b) => b.entry.consumedAt.compareTo(a.entry.consumedAt));

    return ListView.builder(
      key: const Key('statistics-map-panel-list'),
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
      itemCount: sortedMarkers.length,
      itemBuilder: (context, index) {
        final marker = sortedMarkers[index];
        final entry = marker.entry;
        final accentColor = colors[entry.category]!;
        final metadataLabel = <String>[
          DateFormat.yMMMd(localeCode).add_Hm().format(entry.consumedAt),
          if (entry.shouldShowAlcoholFreeMarker) l10n.alcoholFree,
        ].join(' • ');

        return ListTile(
          key: Key('statistics-map-panel-item-${entry.id}'),
          onTap: () => onDetailSelected(marker),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          leading: CircleAvatar(
            backgroundColor: accentColor.withValues(alpha: 0.16),
            foregroundColor: accentColor,
            child: Icon(entry.category.icon),
          ),
          title: Text(
            controller.localizedEntryDrinkName(entry, localeCode: localeCode),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            metadataLabel,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (_statisticsGalleryHasImage(entry)) ...<Widget>[
                Icon(
                  Icons.photo_camera_outlined,
                  key: Key('statistics-map-panel-image-indicator-${entry.id}'),
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
              ],
              if (entry.volumeMl != null)
                Text(unit.formatVolume(entry.volumeMl)),
            ],
          ),
        );
      },
    );
  }
}
