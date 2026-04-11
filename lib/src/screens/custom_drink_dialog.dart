import 'package:flutter/material.dart';
import 'package:glasstrail/l10n/app_localizations.dart';

import '../app_theme.dart';
import '../app_controller.dart';
import '../app_scope.dart';
import '../l10n_extensions.dart';
import '../models.dart';
import '../photo_pick_flow.dart';
import '../photo_service.dart';
import '../widgets/app_media.dart';

class CustomDrinkDialog extends StatefulWidget {
  const CustomDrinkDialog({super.key, this.initialDrink});

  final DrinkDefinition? initialDrink;

  @override
  State<CustomDrinkDialog> createState() => _CustomDrinkDialogState();
}

class _CustomDrinkDialogState extends State<CustomDrinkDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _volumeController;
  DrinkCategory _category = DrinkCategory.nonAlcoholic;
  String? _imagePath;
  bool _didHydrateInitialVolume = false;
  bool _volumeEditedManually = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialDrink;
    _nameController = TextEditingController(text: initial?.name ?? '');
    _volumeController = TextEditingController();
    _category = initial?.category ?? DrinkCategory.nonAlcoholic;
    _imagePath = initial?.imagePath;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didHydrateInitialVolume) {
      return;
    }
    _didHydrateInitialVolume = true;
    _volumeController.text = AppScope.controllerOf(
      context,
    ).settings.unit.formatVolumeInput(widget.initialDrink?.volumeMl);
    _volumeEditedManually = false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _volumeController.dispose();
    super.dispose();
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

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.invalidRequired)));
      return;
    }

    final controller = AppScope.controllerOf(context);
    final volume = double.tryParse(_volumeController.text.trim());
    final success = await controller.saveCustomDrink(
      drinkId: widget.initialDrink?.id,
      name: _nameController.text,
      category: _category,
      volumeMl: _volumeEditedManually
          ? (volume == null
                ? null
                : controller.settings.unit.convertToMl(volume))
          : widget.initialDrink?.volumeMl,
      imagePath: _imagePath,
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

  Future<void> _confirmDelete() async {
    final drink = widget.initialDrink;
    if (drink == null) {
      return;
    }
    final deleted = await showDialog<bool>(
      context: context,
      builder: (_) =>
          _DeleteCustomDrinkDialog(drink: drink, parentContext: context),
    );
    if (!mounted || deleted != true) {
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.controllerOf(context);
    final theme = Theme.of(context);
    final isBusy = controller.isBusy;
    final isSavingDrink = controller.isBusyFor(AppBusyAction.saveCustomDrink);
    final isEditingDrink = widget.initialDrink != null;

    return AlertDialog(
      title: Text(
        isEditingDrink ? l10n.editCustomDrink : l10n.createCustomDrink,
      ),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                enabled: !isBusy,
                controller: _nameController,
                decoration: InputDecoration(labelText: l10n.drinkName),
                validator: (value) => value == null || value.trim().isEmpty
                    ? l10n.invalidRequired
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<DrinkCategory>(
                initialValue: _category,
                isExpanded: true,
                decoration: InputDecoration(labelText: l10n.category),
                items: DrinkCategory.values
                    .map(
                      (category) => DropdownMenuItem<DrinkCategory>(
                        value: category,
                        child: Text(l10n.categoryLabel(category)),
                      ),
                    )
                    .toList(),
                onChanged: isBusy
                    ? null
                    : (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          _category = value;
                        });
                      },
              ),
              const SizedBox(height: 12),
              TextFormField(
                enabled: !isBusy,
                controller: _volumeController,
                decoration: InputDecoration(
                  labelText:
                      '${l10n.volume} (${l10n.unitLabel(controller.settings.unit)})',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) {
                  _volumeEditedManually = true;
                },
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  FilledButton.tonalIcon(
                    onPressed: isBusy ? null : _pickPhoto,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(
                      _imagePath == null ? l10n.pickPhoto : l10n.changePhoto,
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
                  key: const Key('custom-drink-image-preview'),
                  imagePath: _imagePath,
                  cropPortraitToSquare: true,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: <Widget>[
        if (isEditingDrink)
          TextButton(
            key: const Key('custom-drink-delete-button'),
            style: AppTheme.destructiveTextButtonStyle(theme.colorScheme),
            onPressed: isBusy ? null : _confirmDelete,
            child: Text(l10n.deleteCustomDrink),
          ),
        TextButton(
          key: const Key('custom-drink-cancel-button'),
          onPressed: isBusy ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('custom-drink-save-button'),
          onPressed: isBusy ? null : _save,
          child: isSavingDrink
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.save),
        ),
      ],
    );
  }
}

class _DeleteCustomDrinkDialog extends StatefulWidget {
  const _DeleteCustomDrinkDialog({
    required this.drink,
    required this.parentContext,
  });

  final DrinkDefinition drink;
  final BuildContext parentContext;

  @override
  State<_DeleteCustomDrinkDialog> createState() =>
      _DeleteCustomDrinkDialogState();
}

class _DeleteCustomDrinkDialogState extends State<_DeleteCustomDrinkDialog> {
  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.controllerOf(context);
    final success = await controller.deleteCustomDrink(widget.drink);
    final message = controller.takeFlashMessage(l10n);
    if (message != null && widget.parentContext.mounted) {
      ScaffoldMessenger.of(
        widget.parentContext,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
    if (!mounted || !success) {
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.controllerOf(context);
    final theme = Theme.of(context);
    final isBusy = controller.isBusy;
    final isDeleting = controller.isBusyFor(AppBusyAction.deleteCustomDrink);

    return AlertDialog(
      title: Text(l10n.deleteCustomDrink),
      content: Text(l10n.deleteCustomDrinkPrompt),
      actions: <Widget>[
        TextButton(
          key: const Key('delete-custom-drink-cancel-button'),
          onPressed: isBusy ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('delete-custom-drink-confirm-button'),
          style: AppTheme.destructiveFilledButtonStyle(theme.colorScheme),
          onPressed: isBusy ? null : _delete,
          child: isDeleting
              ? SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.onError,
                    ),
                  ),
                )
              : Text(l10n.deleteCustomDrink),
        ),
      ],
    );
  }
}
