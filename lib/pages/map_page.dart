import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:glasstrail/l10n/l10n.dart';
import 'package:glasstrail/models/app_models.dart';
import 'package:glasstrail/state/app_controller.dart';

class MapPage extends StatefulWidget {
  const MapPage({required this.controller, super.key});

  final AppController controller;

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();

  bool _showMine = true;
  bool _showFriends = true;
  DrinkCategory? _selectedCategory;
  DateFilter _dateFilter = DateFilter.all;
  DrinkLog? _selectedLog;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final logs = widget.controller.mapLogs(
      showMine: _showMine,
      showFriends: _showFriends,
      category: _selectedCategory,
      dateFilter: _dateFilter,
    );

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(52.5200, 13.4050),
              initialZoom: 11,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'app.glasstrail',
                tileProvider: NetworkTileProvider(),
              ),
              CircleLayer(
                circles: logs
                    .where(
                        (log) => log.userId == widget.controller.currentUser.id)
                    .map(
                      (log) => CircleMarker(
                        point: LatLng(log.latitude, log.longitude),
                        radius: 8,
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.15),
                      ),
                    )
                    .toList(),
              ),
              MarkerLayer(
                markers: logs
                    .map(
                      (log) => Marker(
                        width: 48,
                        height: 48,
                        point: LatLng(log.latitude, log.longitude),
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _selectedLog = log;
                          }),
                          child: Icon(
                            Icons.location_on,
                            size: 36,
                            color:
                                log.userId == widget.controller.currentUser.id
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.tertiary,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
          Positioned(
            left: 12,
            right: 12,
            top: 40,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.mapTitle,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: Text(l10n.mine),
                          selected: _showMine,
                          onSelected: (value) => setState(() {
                            _showMine = value;
                          }),
                        ),
                        ChoiceChip(
                          label: Text(l10n.friends),
                          selected: _showFriends,
                          onSelected: (value) => setState(() {
                            _showFriends = value;
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownMenu<DrinkCategory?>(
                            initialSelection: _selectedCategory,
                            label: Text(l10n.category),
                            dropdownMenuEntries: [
                              DropdownMenuEntry<DrinkCategory?>(
                                value: null,
                                label: l10n.allCategories,
                              ),
                              ...DrinkCategory.values.map(
                                (category) => DropdownMenuEntry<DrinkCategory?>(
                                  value: category,
                                  label: category.defaultLabel,
                                ),
                              ),
                            ],
                            onSelected: (value) => setState(() {
                              _selectedCategory = value;
                            }),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownMenu<DateFilter>(
                            initialSelection: _dateFilter,
                            label: Text(l10n.dateRange),
                            dropdownMenuEntries: [
                              DropdownMenuEntry(
                                value: DateFilter.today,
                                label: l10n.today,
                              ),
                              DropdownMenuEntry(
                                value: DateFilter.sevenDays,
                                label: l10n.last7Days,
                              ),
                              DropdownMenuEntry(
                                value: DateFilter.thirtyDays,
                                label: l10n.last30Days,
                              ),
                              DropdownMenuEntry(
                                value: DateFilter.all,
                                label: l10n.allTime,
                              ),
                            ],
                            onSelected: (value) => setState(() {
                              _dateFilter = value ?? DateFilter.all;
                            }),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 240,
            child: FloatingActionButton.small(
              onPressed: () {
                _mapController.move(const LatLng(52.5200, 13.4050), 12);
              },
              tooltip: l10n.recenter,
              child: const Icon(Icons.my_location),
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.2,
            minChildSize: 0.15,
            maxChildSize: 0.45,
            builder: (context, scrollController) {
              return Card(
                margin: const EdgeInsets.all(0),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (_selectedLog == null) ...[
                      Text(
                        l10n.noMapSelection,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(l10n.mapSelectionHint),
                    ] else ...[
                      Text(
                        _selectedLog!.drinkName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_selectedLog!.userName} • '
                        '${DateFormat.yMMMd(widget.controller.locale.languageCode).add_Hm().format(_selectedLog!.loggedAt)}',
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: [
                          Chip(
                              label: Text(_selectedLog!.category.defaultLabel)),
                          Chip(
                            avatar: const Icon(Icons.celebration, size: 16),
                            label: Text('${_selectedLog!.cheersCount}'),
                          ),
                          Chip(
                            avatar: const Icon(Icons.mode_comment, size: 16),
                            label: Text('${_selectedLog!.commentCount}'),
                          ),
                        ],
                      ),
                      if (_selectedLog!.comment != null) ...[
                        const SizedBox(height: 8),
                        Text(_selectedLog!.comment!),
                      ],
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
