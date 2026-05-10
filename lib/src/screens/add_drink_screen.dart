import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:glasstrail/l10n/app_localizations.dart';

import '../app_theme.dart';
import '../app_controller.dart';
import '../app_scope.dart';
import '../l10n_extensions.dart';
import '../location_service.dart';
import '../models.dart';
import '../photo_pick_flow.dart';
import '../photo_service.dart';
import '../widgets/app_media.dart';
import '../widgets/drink_picker_catalog.dart';
import 'custom_drink_dialog.dart';

class AddDrinkScreen extends StatefulWidget {
  const AddDrinkScreen({super.key});

  @override
  State<AddDrinkScreen> createState() => _AddDrinkScreenState();
}

class _AddDrinkScreenState extends State<AddDrinkScreen>
    with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  final _volumeController = TextEditingController();

  DrinkDefinition? _selectedDrink;
  String? _imagePath;
  bool _volumeEditedManually = false;
  bool _isLocationEnabled = true;
  bool _isResolvingLocation = false;
  bool _locationAttempted = false;
  EntryLocationData? _location;
  LocationAccuracyStatus _locationAccuracyStatus =
      LocationAccuracyStatus.unknown;
  bool _startedInitialLocationLookup = false;
  int _locationRequestVersion = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_startedInitialLocationLookup) {
      return;
    }
    _startedInitialLocationLookup = true;
    _refreshLocation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _commentController.dispose();
    _volumeController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !_isLocationEnabled) {
      return;
    }
    _refreshLocation(force: true);
  }

  Future<void> _pickPhoto() async {
    final path = await pickImageForUpload(
      context,
      preset: ImageUploadPreset.feed,
    );
    if (!mounted || path == null) {
      return;
    }
    setState(() {
      _imagePath = path;
    });
  }

  Future<void> _openCustomDrinkDialog() async {
    final l10n = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      builder: (_) => const CustomDrinkDialog(),
    );
    if (!mounted) {
      return;
    }
    final message = AppScope.controllerOf(context).takeFlashMessage(l10n);
    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _selectDrink(DrinkDefinition drink) {
    final unit = AppScope.controllerOf(context).settings.unit;
    setState(() {
      _selectedDrink = drink;
      _volumeEditedManually = false;
      _volumeController.text = unit.formatVolumeInput(drink.volumeMl);
    });
  }

  Future<void> _refreshLocation({bool force = false}) async {
    if (!_isLocationEnabled || (_isResolvingLocation && !force)) {
      return;
    }

    final locationService = AppScope.locationServiceOf(context);
    final localeCode = AppScope.controllerOf(context).settings.localeCode;
    final requestVersion = ++_locationRequestVersion;
    setState(() {
      _isResolvingLocation = true;
      _locationAttempted = true;
    });

    LocationFetchResult result = const LocationFetchResult();
    try {
      result = await locationService.fetchCurrentLocation(
        localeCode: localeCode,
      );
    } catch (_) {}

    if (!mounted ||
        requestVersion != _locationRequestVersion ||
        !_isLocationEnabled) {
      return;
    }

    setState(() {
      _location = result.location;
      _locationAccuracyStatus = result.accuracyStatus;
      _isResolvingLocation = false;
    });
  }

  void _setLocationEnabled(bool value) {
    if (value == _isLocationEnabled) {
      return;
    }

    setState(() {
      _isLocationEnabled = value;
      if (!value) {
        _locationRequestVersion++;
        _isResolvingLocation = false;
        _locationAccuracyStatus = LocationAccuracyStatus.unknown;
      }
    });

    if (value && _location == null) {
      _refreshLocation();
    }
  }

  Future<void> _openLocationSettings() async {
    final opened = await AppScope.locationServiceOf(context).openAppSettings();
    if (!mounted || opened) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).locationUnavailable)),
    );
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate() || _selectedDrink == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.invalidRequired)));
      return;
    }

    final controller = AppScope.controllerOf(context);
    final volume = double.tryParse(_volumeController.text.trim());
    final location = _isLocationEnabled ? _location : null;
    final success = await controller.addDrinkEntry(
      drink: _selectedDrink!,
      volumeMl: _volumeEditedManually
          ? (volume == null
                ? _selectedDrink!.volumeMl
                : controller.settings.unit.convertToMl(volume))
          : _selectedDrink!.volumeMl,
      comment: _commentController.text,
      imagePath: _imagePath,
      locationLatitude: location?.latitude,
      locationLongitude: location?.longitude,
      locationAddress: location?.address,
    );
    if (!mounted) {
      return;
    }
    final message = controller.takeFlashMessage(l10n);
    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
    if (success) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.controllerOf(context);
    final theme = Theme.of(context);
    final localeCode = controller.settings.localeCode;
    final unit = controller.settings.unit;
    final isBusy = controller.isBusy;
    final isSavingDrink = controller.isBusyFor(AppBusyAction.addDrinkEntry);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.addDrink)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: <Widget>[
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                DrinkPickerCatalog(
                  availableDrinks: controller.availableDrinks,
                  recentDrinks: controller.recentDrinks,
                  localeCode: localeCode,
                  unit: unit,
                  selectedDrink: _selectedDrink,
                  enabled: !isBusy,
                  collapseAfterSelect: true,
                  onCreateCustomDrink: _openCustomDrinkDialog,
                  onSelect: _selectDrink,
                ),
                if (_selectedDrink != null) ...<Widget>[
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          _selectedDrink!.displayName(localeCode),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.drinkDefinitionMetadata(_selectedDrink!, unit),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('drink-volume-field'),
                    controller: _volumeController,
                    enabled: !isBusy,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: '${l10n.volume} (${l10n.unitLabel(unit)})',
                    ),
                    onChanged: (_) {
                      _volumeEditedManually = true;
                    },
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                l10n.location,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Switch.adaptive(
                              key: const Key('drink-location-toggle'),
                              value: _isLocationEnabled,
                              onChanged: isBusy ? null : _setLocationEnabled,
                            ),
                          ],
                        ),
                        Text(
                          l10n.saveLocationForEntry,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Icon(
                              Icons.location_on_outlined,
                              size: 18,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                key: const Key('drink-location-value'),
                                _locationText(l10n),
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                        if (_showsApproximateLocationWarning) ...<Widget>[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.tertiary.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  l10n.locationApproximateWarning,
                                  key: const Key(
                                    'drink-location-approximate-warning',
                                  ),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  key: const Key(
                                    'drink-location-open-settings-button',
                                  ),
                                  onPressed: _openLocationSettings,
                                  icon: const Icon(Icons.settings_outlined),
                                  label: Text(l10n.openAppSettings),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('drink-comment-field'),
                    controller: _commentController,
                    enabled: !isBusy,
                    minLines: 2,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: '${l10n.comment} (${l10n.optional})',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      FilledButton.tonalIcon(
                        onPressed: isBusy ? null : _pickPhoto,
                        icon: const Icon(Icons.photo_library_outlined),
                        label: Text(
                          _imagePath == null
                              ? l10n.pickPhoto
                              : l10n.changePhoto,
                        ),
                      ),
                      if (_imagePath != null)
                        OutlinedButton.icon(
                          style: AppTheme.destructiveOutlinedButtonStyle(
                            theme.colorScheme,
                          ),
                          onPressed: isBusy
                              ? null
                              : () {
                                  setState(() {
                                    _imagePath = null;
                                  });
                                },
                          icon: const Icon(Icons.close_rounded),
                          label: Text(l10n.removePhoto),
                        ),
                    ],
                  ),
                  if (_imagePath != null) ...<Widget>[
                    const SizedBox(height: 12),
                    AppPhotoPreview(
                      key: const Key('add-drink-image-preview'),
                      imagePath: _imagePath,
                      cropPortraitToSquare: true,
                    ),
                  ],
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const Key('confirm-drink-button'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: isBusy ? null : _save,
                    child: isSavingDrink
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.confirmDrink),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _locationText(AppLocalizations l10n) {
    if (!_isLocationEnabled) {
      return l10n.locationDisabledForEntry;
    }
    if (_isResolvingLocation) {
      return l10n.locationLoading;
    }
    final address = _location?.address?.trim();
    if (address != null && address.isNotEmpty) {
      return address;
    }
    if (_location != null) {
      return l10n.locationAddressUnavailable;
    }
    if (_locationAttempted) {
      return l10n.locationUnavailable;
    }
    return l10n.locationLoading;
  }

  bool get _showsApproximateLocationWarning {
    return _isLocationEnabled &&
        !_isResolvingLocation &&
        _locationAttempted &&
        _locationAccuracyStatus == LocationAccuracyStatus.reduced;
  }
}
