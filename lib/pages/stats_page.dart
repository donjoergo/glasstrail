import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:glasstrail/l10n/l10n.dart';
import 'package:glasstrail/models/app_models.dart';
import 'package:glasstrail/state/app_controller.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.statsTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.statsOverview),
              Tab(text: l10n.statsMap),
              Tab(text: l10n.statsList),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _StatsOverviewTab(controller: controller),
            _StatsMapTab(controller: controller),
            _StatsListTab(controller: controller),
          ],
        ),
      ),
    );
  }
}

class _StatsOverviewTab extends StatelessWidget {
  const _StatsOverviewTab({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final daily = controller.totalForDays(1);
    final weekly = controller.totalForDays(7);
    final monthly = controller.totalForDays(30);
    final counts = controller.categoryCounts();
    final streak = controller.streakMetrics();
    final series = controller.last7DaySeries();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.2,
            ),
            children: [
              _SummaryTile(title: l10n.dailyTotal, value: '$daily'),
              _SummaryTile(title: l10n.weeklyTotal, value: '$weekly'),
              _SummaryTile(title: l10n.monthlyTotal, value: '$monthly'),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.trend7Days,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        minY: 0,
                        lineBarsData: [
                          LineChartBarData(
                            spots: List<FlSpot>.generate(
                              series.length,
                              (index) => FlSpot(
                                  index.toDouble(), series[index].toDouble()),
                            ),
                            isCurved: true,
                            barWidth: 3,
                            dotData: const FlDotData(show: true),
                          ),
                        ],
                        titlesData: FlTitlesData(
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                final day = DateTime.now().subtract(
                                    Duration(days: 6 - value.toInt()));
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(DateFormat.E().format(day)),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.categoryDistribution,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 180,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 28,
                        sections: counts.entries.map((entry) {
                          final color = _categoryColor(entry.key, context);
                          final value = entry.value.toDouble();
                          return PieChartSectionData(
                            value: value == 0 ? 0.1 : value,
                            title: entry.value == 0 ? '' : '${entry.value}',
                            color: color,
                            radius: 60,
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: counts.entries
                        .map(
                          (entry) => Chip(
                            label: Text(
                              '${entry.key.defaultLabel}: ${entry.value}',
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: Text(l10n.currentStreak),
                  trailing: Text('${streak.current}'),
                ),
                ListTile(
                  title: Text(l10n.bestStreak),
                  trailing: Text('${streak.best}'),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.streakProgress),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: streak.best == 0
                            ? 0
                            : (streak.current / streak.best),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.categoryDistribution,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        barGroups: counts.entries
                            .toList()
                            .asMap()
                            .entries
                            .map(
                              (entry) => BarChartGroupData(
                                x: entry.key,
                                barRods: [
                                  BarChartRodData(
                                    toY: entry.value.value.toDouble(),
                                    width: 18,
                                    borderRadius: BorderRadius.circular(6),
                                    color: _categoryColor(
                                        entry.value.key, context),
                                  ),
                                ],
                              ),
                            )
                            .toList(),
                        titlesData: FlTitlesData(
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final idx = value.toInt();
                                if (idx < 0 ||
                                    idx >= DrinkCategory.values.length) {
                                  return const SizedBox.shrink();
                                }
                                final category = DrinkCategory.values[idx];
                                return Text(
                                    category.defaultLabel.substring(0, 3));
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _categoryColor(DrinkCategory category, BuildContext context) {
    switch (category) {
      case DrinkCategory.beer:
        return const Color(0xFFF5C26B);
      case DrinkCategory.wine:
        return const Color(0xFFBF4D73);
      case DrinkCategory.spirits:
        return const Color(0xFF7A5CFA);
      case DrinkCategory.cocktails:
        return const Color(0xFF1F7A8C);
      case DrinkCategory.nonAlcoholic:
        return Theme.of(context).colorScheme.secondary;
    }
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text(title, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

enum _StatsMapRange { sevenDays, thirtyDays, all, custom }

class _StatsMapTab extends StatefulWidget {
  const _StatsMapTab({required this.controller});

  final AppController controller;

  @override
  State<_StatsMapTab> createState() => _StatsMapTabState();
}

class _StatsMapTabState extends State<_StatsMapTab> {
  final MapController _mapController = MapController();

  _StatsMapRange _range = _StatsMapRange.sevenDays;
  DateTimeRange? _customRange;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final myLogs = widget.controller.logs
        .where((log) => log.userId == widget.controller.currentUser.id)
        .where(_isInsideRange)
        .toList();

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<_StatsMapRange>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                        value: _StatsMapRange.sevenDays,
                        label: Text(l10n.last7Days),
                      ),
                      ButtonSegment(
                        value: _StatsMapRange.thirtyDays,
                        label: Text(l10n.last30Days),
                      ),
                      ButtonSegment(
                        value: _StatsMapRange.all,
                        label: Text(l10n.allTime),
                      ),
                      ButtonSegment(
                        value: _StatsMapRange.custom,
                        label: Text(l10n.custom),
                      ),
                    ],
                    selected: {_range},
                    onSelectionChanged: (selection) {
                      setState(() {
                        _range = selection.first;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: l10n.chooseDateRange,
                  onPressed: _pickCustomDateRange,
                  icon: const Icon(Icons.date_range_outlined),
                ),
              ],
            ),
          ),
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: const MapOptions(
                initialCenter: LatLng(52.52, 13.405),
                initialZoom: 11,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'app.glasstrail',
                  tileProvider: CancellableNetworkTileProvider(),
                ),
                MarkerLayer(
                  markers: myLogs
                      .map(
                        (log) => Marker(
                          point: LatLng(log.latitude, log.longitude),
                          width: 42,
                          height: 42,
                          child: Icon(
                            Icons.location_on,
                            color: Theme.of(context).colorScheme.primary,
                            size: 34,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isInsideRange(DrinkLog log) {
    final date =
        DateTime(log.loggedAt.year, log.loggedAt.month, log.loggedAt.day);
    final now = DateTime.now();

    switch (_range) {
      case _StatsMapRange.sevenDays:
        return !date.isBefore(
          DateTime(now.year, now.month, now.day)
              .subtract(const Duration(days: 6)),
        );
      case _StatsMapRange.thirtyDays:
        return !date.isBefore(
          DateTime(now.year, now.month, now.day)
              .subtract(const Duration(days: 29)),
        );
      case _StatsMapRange.all:
        return true;
      case _StatsMapRange.custom:
        if (_customRange == null) {
          return true;
        }
        final start = DateTime(
          _customRange!.start.year,
          _customRange!.start.month,
          _customRange!.start.day,
        );
        final end = DateTime(
          _customRange!.end.year,
          _customRange!.end.month,
          _customRange!.end.day,
        );
        return !date.isBefore(start) && !date.isAfter(end);
    }
  }

  Future<void> _pickCustomDateRange() async {
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 2)),
      initialDateRange: _customRange,
    );

    if (selected != null) {
      setState(() {
        _customRange = selected;
        _range = _StatsMapRange.custom;
      });
    }
  }
}

class _StatsListTab extends StatelessWidget {
  const _StatsListTab({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final myLogs = controller.logs
        .where((log) => log.userId == controller.currentUser.id)
        .toList();
    final groupedByMonth = <String, List<DrinkLog>>{};
    for (final log in myLogs) {
      final key =
          DateFormat.yMMMM(controller.locale.languageCode).format(log.loggedAt);
      groupedByMonth.putIfAbsent(key, () => <DrinkLog>[]).add(log);
    }

    final counts = controller.categoryCounts();
    final streak = controller.streakMetrics();

    if (myLogs.isEmpty) {
      return Center(child: Text(l10n.noHistory));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 120),
      itemCount: groupedByMonth.keys.length + 3,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: DataTable(
                columns: [
                  DataColumn(label: Text(l10n.category)),
                  DataColumn(label: Text(l10n.count)),
                ],
                rows: counts.entries
                    .map(
                      (entry) => DataRow(
                        cells: [
                          DataCell(Text(entry.key.defaultLabel)),
                          DataCell(Text('${entry.value}')),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          );
        }

        if (index == 1) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Column(
              children: [
                ListTile(
                  title: Text(l10n.currentStreak),
                  trailing: Text('${streak.current}'),
                ),
                ListTile(
                  title: Text(l10n.bestStreak),
                  trailing: Text('${streak.best}'),
                ),
              ],
            ),
          );
        }

        if (index == 2) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(l10n.totals),
              trailing: Text('${myLogs.length}'),
            ),
          );
        }

        final month = groupedByMonth.keys.elementAt(index - 3);
        final monthLogs = groupedByMonth[month]!;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            title: Text(month),
            subtitle: Text('${monthLogs.length}'),
            children: monthLogs
                .map(
                  (log) => ListTile(
                    title: Text(log.drinkName),
                    subtitle:
                        Text(DateFormat.yMMMd().add_Hm().format(log.loggedAt)),
                    trailing: Chip(label: Text(log.category.defaultLabel)),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }
}
