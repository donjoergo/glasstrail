import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../app_localizations.dart';
import '../app_scope.dart';
import '../models.dart';
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
    final path = await AppScope.photoServiceOf(context).pickImage();
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.controllerOf(context);
    final isBusy = controller.isBusy;
    final isSavingDrink = controller.isBusyFor(AppBusyAction.saveCustomDrink);

    return AlertDialog(
      title: Text(
        widget.initialDrink == null
            ? l10n.createCustomDrink
            : l10n.editCustomDrink,
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
