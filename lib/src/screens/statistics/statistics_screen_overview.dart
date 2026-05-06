part of '../statistics_screen.dart';

class _StatisticsOverviewPage extends StatelessWidget {
  const _StatisticsOverviewPage();

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.controllerOf(context);

    return RefreshIndicator(
      key: const Key('statistics-refresh-indicator'),
      onRefresh: () => _refreshStatistics(context),
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
    );
  }
}
