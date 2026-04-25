part of '../statistics_screen.dart';

class _StatisticsHistoryPage extends StatefulWidget {
  const _StatisticsHistoryPage();

  @override
  State<_StatisticsHistoryPage> createState() => _StatisticsHistoryPageState();
}

class _StatisticsHistoryPageState extends State<_StatisticsHistoryPage> {
  DrinkCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.controllerOf(context);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final allEntries = controller.entries;
    final entries = _selectedCategory == null
        ? allEntries
        : allEntries
              .where((entry) => entry.category == _selectedCategory)
              .toList();

    return RefreshIndicator(
      key: const Key('statistics-history-refresh-indicator'),
      onRefresh: () => _refreshStatistics(context),
      child: ListView(
        key: const Key('statistics-history-list-view'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: <Widget>[
          if (allEntries.isEmpty)
            AppEmptyStateCard(
              key: const Key('statistics-history-empty-state'),
              icon: Icons.history_rounded,
              title: l10n.statisticsHistoryEmptyTitle,
              body: l10n.statisticsHistoryEmptyBody,
            )
          else ...<Widget>[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: DrinkCategory.values
                    .where(
                      (category) =>
                          (controller.statistics.categoryCounts[category] ??
                                  0) >
                              0 ||
                          _selectedCategory == category,
                    )
                    .map((category) {
                      final count =
                          controller.statistics.categoryCounts[category] ?? 0;
                      return FilterChip(
                        selected: _selectedCategory == category,
                        showCheckmark: false,
                        avatar: Icon(
                          category.icon,
                          key: Key(
                            'statistics-history-category-chip-icon-${category.storageValue}',
                          ),
                          size: 18,
                        ),
                        label: Text('${l10n.categoryLabel(category)} ($count)'),
                        onSelected: (_) {
                          setState(() {
                            _selectedCategory = _selectedCategory == category
                                ? null
                                : category;
                          });
                        },
                      );
                    })
                    .toList(),
              ),
            ),
            const SizedBox(height: 24),
            if (entries.isEmpty)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(l10n.emptyFilter),
              )
            else
              ...entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _StatisticsHistoryEntryCard(entry: entry),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _StatisticsHistoryEntryCard extends StatelessWidget {
  const _StatisticsHistoryEntryCard({required this.entry});

  final DrinkEntry entry;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.controllerOf(context);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locationAddress = _normalizedLocationAddress(entry.locationAddress);
    final metadataLabel = <String>[
      DateFormat.yMMMd(controller.settings.localeCode).format(entry.consumedAt),
      if (entry.shouldShowAlcoholFreeMarker) l10n.alcoholFree,
    ].join(' • ');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: <Widget>[
          Icon(entry.category.icon, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  controller.localizedEntryDrinkName(entry),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  metadataLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (locationAddress != null) ...<Widget>[
                  const SizedBox(height: 4),
                  Row(
                    children: <Widget>[
                      Icon(
                        Icons.location_on_outlined,
                        key: Key(
                          'statistics-history-location-icon-${entry.id}',
                        ),
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          locationAddress,
                          key: Key('statistics-history-location-${entry.id}'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Text(controller.settings.unit.formatVolume(entry.volumeMl)),
        ],
      ),
    );
  }

  String? _normalizedLocationAddress(String? value) {
    return normalizeLocationAddress(value);
  }
}

class _StatisticsGalleryPage extends StatelessWidget {
  const _StatisticsGalleryPage();

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.controllerOf(context);
    final l10n = AppLocalizations.of(context);
    final localeCode = controller.settings.localeCode;
    final unit = controller.settings.unit;
    final entries = controller.entries
        .where(_statisticsGalleryHasImage)
        .toList(growable: false);
    final galleryItems = entries
        .map(
          (entry) => AppGalleryViewerItem(
            imagePath: entry.imagePath!.trim(),
            drinkName: controller.localizedEntryDrinkName(
              entry,
              localeCode: localeCode,
            ),
            metadata: <String>[
              l10n.categoryLabel(entry.category),
              if (entry.shouldShowAlcoholFreeMarker) l10n.alcoholFree,
              DateFormat.yMMMd(localeCode).add_Hm().format(entry.consumedAt),
              if (entry.volumeMl != null) unit.formatVolume(entry.volumeMl),
              if (_normalizedLocationAddress(entry.locationAddress) != null)
                _normalizedLocationAddress(entry.locationAddress)!,
            ],
            comment: _normalizedGalleryComment(entry.comment),
          ),
        )
        .toList(growable: false);

    if (entries.isEmpty) {
      return RefreshIndicator(
        key: const Key('statistics-gallery-refresh-indicator'),
        onRefresh: () => _refreshStatistics(context),
        child: ListView(
          key: const Key('statistics-gallery-list-view'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          children: <Widget>[
            _StatisticsEmptyStateCard(
              key: const Key('statistics-gallery-empty-state'),
              icon: Icons.photo_library_rounded,
              title: l10n.statisticsGalleryEmptyTitle,
              body: l10n.statisticsGalleryEmptyBody,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      key: const Key('statistics-gallery-refresh-indicator'),
      onRefresh: () => _refreshStatistics(context),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GridView.builder(
            key: const Key('statistics-gallery-grid'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _statisticsGalleryCrossAxisCount(
                constraints.maxWidth,
              ),
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              final galleryItem = galleryItems[index];

              return _StatisticsGalleryTile(
                key: Key('statistics-gallery-tile-${entry.id}'),
                imagePath: galleryItem.imagePath,
                onTap: () {
                  showAppGalleryViewerDialog(
                    context,
                    items: galleryItems,
                    initialIndex: index,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String? _normalizedGalleryComment(String? comment) {
    final normalized = comment?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  String? _normalizedLocationAddress(String? value) {
    return normalizeLocationAddress(value);
  }
}

class _StatisticsGalleryTile extends StatefulWidget {
  const _StatisticsGalleryTile({
    super.key,
    required this.imagePath,
    required this.onTap,
  });

  final String imagePath;
  final VoidCallback onTap;

  @override
  State<_StatisticsGalleryTile> createState() => _StatisticsGalleryTileState();
}

class _StatisticsGalleryTileState extends State<_StatisticsGalleryTile> {
  late Future<ImageProvider<Object>?> _imageFuture;

  @override
  void initState() {
    super.initState();
    _updateImageFuture();
  }

  @override
  void didUpdateWidget(covariant _StatisticsGalleryTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath != widget.imagePath) {
      _updateImageFuture();
    }
  }

  void _updateImageFuture() {
    _imageFuture = AppMediaResolver.resolveImageProvider(widget.imagePath);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        child: AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: ColoredBox(
              color: theme.colorScheme.surfaceContainerHighest,
              child: FutureBuilder<ImageProvider<Object>?>(
                future: _imageFuture,
                builder: (context, snapshot) {
                  final imageProvider = snapshot.data;
                  if (imageProvider == null) {
                    return Icon(
                      Icons.image_outlined,
                      color: theme.colorScheme.onSurfaceVariant,
                    );
                  }
                  return Image(
                    image: imageProvider,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Icon(
                      Icons.broken_image_outlined,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
