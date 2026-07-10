part of '../statistics_screen.dart';

class _StatisticsDashboardPage extends StatelessWidget {
  const _StatisticsDashboardPage();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(flex: 5, child: _StatisticsDashboardOverviewColumn()),
        Expanded(flex: 7, child: _StatisticsMapPage()),
      ],
    );
  }
}

class _StatisticsDashboardOverviewColumn extends StatelessWidget {
  const _StatisticsDashboardOverviewColumn();

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.controllerOf(context);
    final l10n = AppLocalizations.of(context);
    final galleryEntries = controller.entries
        .where(_statisticsGalleryHasImage)
        .toList(growable: false);
    final galleryItems = _statisticsGalleryViewerItems(
      controller: controller,
      l10n: l10n,
      entries: galleryEntries,
    );

    return RefreshIndicator(
      key: const Key('statistics-dashboard-refresh-indicator'),
      onRefresh: () => _refreshStatistics(context),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return CustomScrollView(
            key: const Key('statistics-dashboard-scroll'),
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: <Widget>[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
                sliver: SliverToBoxAdapter(
                  child: StatisticsOverviewContent(
                    stats: controller.statistics,
                    localeCode: controller.settings.localeCode,
                  ),
                ),
              ),
              if (galleryEntries.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 12, 120),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _statisticsGalleryCrossAxisCount(
                        constraints.maxWidth,
                      ),
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _statisticsGalleryTileFor(
                        context: context,
                        entries: galleryEntries,
                        galleryItems: galleryItems,
                        index: index,
                      ),
                      childCount: galleryEntries.length,
                    ),
                  ),
                )
              else
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          );
        },
      ),
    );
  }
}

class _StatisticsOverviewPage extends StatelessWidget {
  const _StatisticsOverviewPage();

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.controllerOf(context);

    return RefreshIndicator(
      key: const Key('statistics-refresh-indicator'),
      onRefresh: () => _refreshStatistics(context),
      child: AppConstrainedContent(
        maxWidth: AppBreakpoints.listContentMaxWidth,
        child: ListView(
          key: const Key('statistics-list-view'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          children: <Widget>[
            StatisticsOverviewContent(
              stats: controller.statistics,
              localeCode: controller.settings.localeCode,
            ),
          ],
        ),
      ),
    );
  }
}
