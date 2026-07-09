import 'package:flutter/material.dart';
import 'package:glasstrail/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import '../achievements/catalog_models.dart';
import '../app_scope.dart';

class PlacesScreen extends StatefulWidget {
  const PlacesScreen({super.key, this.focusPlaceType});

  /// Set when opened from the achievements Setup-Required deep link, so the
  /// relevant Home/Work section is scrolled into view and highlighted.
  final SavedPlaceType? focusPlaceType;

  @override
  State<PlacesScreen> createState() => _PlacesScreenState();
}

class _PlacesScreenState extends State<PlacesScreen> {
  bool _isCapturing = false;
  final GlobalKey _homeSectionKey = GlobalKey();
  final GlobalKey _workSectionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.focusPlaceType != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final key = widget.focusPlaceType == SavedPlaceType.home
            ? _homeSectionKey
            : _workSectionKey;
        final context = key.currentContext;
        if (context != null) {
          Scrollable.ensureVisible(
            context,
            duration: const Duration(milliseconds: 250),
            alignment: 0.1,
          );
        }
      });
    }
  }

  Future<void> _setPlace(SavedPlaceType placeType) async {
    final controller = AppScope.controllerOf(context);
    final activeExists = controller.savedPlaces.any(
      (place) => place.placeType == placeType && place.isActive,
    );

    if (activeExists) {
      final l10n = AppLocalizations.of(context);
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(
            placeType == SavedPlaceType.home ? l10n.savedPlacesHome : l10n.savedPlacesWork,
          ),
          content: Text(l10n.savedPlacesReplaceConfirmBody),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.savedPlacesReplaceConfirmAction),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) {
        return;
      }
    }

    setState(() => _isCapturing = true);
    final locationService = AppScope.locationServiceOf(context);
    final result = await locationService.fetchCurrentLocation(
      localeCode: controller.settings.localeCode,
    );
    if (!mounted) {
      return;
    }
    setState(() => _isCapturing = false);

    final location = result.location;
    if (location == null) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.locationUnavailable)));
      return;
    }

    await controller.setSavedPlace(
      placeType: placeType,
      latitude: location.latitude,
      longitude: location.longitude,
    );
  }

  Future<void> _deletePlace(String placeId) async {
    final controller = AppScope.controllerOf(context);
    await controller.deleteSavedPlace(placeId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.controllerOf(context);
    final places = controller.savedPlaces;

    final activeHome = places
        .where((p) => p.placeType == SavedPlaceType.home && p.isActive)
        .cast<SavedPlace?>()
        .firstWhere((_) => true, orElse: () => null);
    final activeWork = places
        .where((p) => p.placeType == SavedPlaceType.work && p.isActive)
        .cast<SavedPlace?>()
        .firstWhere((_) => true, orElse: () => null);
    final archived = places.where((p) => !p.isActive).toList(growable: false)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.savedPlacesTitle)),
      body: AbsorbPointer(
        absorbing: _isCapturing,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            _PlaceSection(
              key: _homeSectionKey,
              title: l10n.savedPlacesHome,
              place: activeHome,
              isCapturing: _isCapturing,
              isFocused: widget.focusPlaceType == SavedPlaceType.home,
              onSet: () => _setPlace(SavedPlaceType.home),
            ),
            const SizedBox(height: 16),
            _PlaceSection(
              key: _workSectionKey,
              title: l10n.savedPlacesWork,
              place: activeWork,
              isCapturing: _isCapturing,
              isFocused: widget.focusPlaceType == SavedPlaceType.work,
              onSet: () => _setPlace(SavedPlaceType.work),
            ),
            if (archived.isNotEmpty) ...<Widget>[
              const SizedBox(height: 24),
              Text(
                l10n.savedPlacesArchived,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              for (final place in archived)
                Card(
                  child: ListTile(
                    leading: Icon(
                      place.placeType == SavedPlaceType.home
                          ? Icons.home_outlined
                          : Icons.work_outline_rounded,
                    ),
                    title: Text(
                      place.placeType == SavedPlaceType.home
                          ? l10n.savedPlacesHome
                          : l10n.savedPlacesWork,
                    ),
                    subtitle: Text(_coordinatesLabel(place)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: () => _deletePlace(place.id),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  String _coordinatesLabel(SavedPlace place) {
    final formatter = NumberFormat.decimalPattern();
    return '${formatter.format(place.latitude)}, ${formatter.format(place.longitude)}';
  }
}

class _PlaceSection extends StatelessWidget {
  const _PlaceSection({
    super.key,
    required this.title,
    required this.place,
    required this.isCapturing,
    required this.onSet,
    this.isFocused = false,
  });

  final String title;
  final SavedPlace? place;
  final bool isCapturing;
  final bool isFocused;
  final VoidCallback onSet;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final formatter = NumberFormat.decimalPattern();

    return Card(
      shape: isFocused
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.colorScheme.primary, width: 2),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (place == null)
              Text(l10n.achievementsSetupRequired)
            else
              Text('${formatter.format(place!.latitude)}, ${formatter.format(place!.longitude)}'),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: isCapturing ? null : onSet,
              icon: isCapturing
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location_rounded),
              label: Text(place == null ? l10n.achievementsSetUpNow : l10n.savedPlacesTitle),
            ),
          ],
        ),
      ),
    );
  }
}
