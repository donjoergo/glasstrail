import 'package:flutter/material.dart';

import '../app_localizations.dart';
import '../app_scope.dart';
import '../models.dart';
import 'custom_drink_dialog.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nicknameController;
  late final TextEditingController _displayNameController;
  DateTime? _birthday;
  String? _profileImagePath;
  String? _hydratedUserId;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController();
    _displayNameController = TextEditingController();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  void _hydrate(AppUser user) {
    if (_hydratedUserId == user.id) {
      return;
    }
    _hydratedUserId = user.id;
    _nicknameController.text = user.nickname;
    _displayNameController.text = user.displayName;
    _birthday = user.birthday;
    _profileImagePath = user.profileImagePath;
  }

  Future<void> _pickBirthday() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(1995, 1, 1),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (!mounted || selected == null) {
      return;
    }
    setState(() {
      _birthday = selected;
    });
  }

  Future<void> _pickPhoto() async {
    final path = await AppScope.photoServiceOf(context).pickImage();
    if (!mounted || path == null) {
      return;
    }
    setState(() {
      _profileImagePath = path;
    });
  }

  Future<void> _saveProfile() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.invalidRequired)),
      );
      return;
    }
    final controller = AppScope.controllerOf(context);
    final success = await controller.updateProfile(
      nickname: _nicknameController.text,
      displayName: _displayNameController.text,
      birthday: _birthday,
      profileImagePath: _profileImagePath,
    );
    if (!mounted) {
      return;
    }
    final message = controller.takeFlashMessage();
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
    if (success) {
      setState(() {});
    }
  }

  Future<void> _showCustomDrinkDialog([DrinkDefinition? drink]) async {
    await showDialog<void>(
      context: context,
      builder: (_) => CustomDrinkDialog(initialDrink: drink),
    );
    if (!mounted) {
      return;
    }
    final message = AppScope.controllerOf(context).takeFlashMessage();
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.controllerOf(context);
    final user = controller.currentUser!;
    final theme = Theme.of(context);
    _hydrate(user);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: <Widget>[
              CircleAvatar(
                radius: 30,
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.14),
                child: Text(
                  user.initials,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      user.displayName,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '@${user.nickname} • ${user.email}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.editProfile,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nicknameController,
                  decoration: InputDecoration(labelText: l10n.nickname),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? l10n.invalidRequired : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _displayNameController,
                  decoration: InputDecoration(labelText: l10n.displayName),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? l10n.invalidRequired : null,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    FilledButton.tonalIcon(
                      onPressed: _pickBirthday,
                      icon: const Icon(Icons.cake_outlined),
                      label: Text(
                        _birthday == null
                            ? '${l10n.birthday} (${l10n.optional})'
                            : '${_birthday!.year}-${_birthday!.month.toString().padLeft(2, '0')}-${_birthday!.day.toString().padLeft(2, '0')}',
                      ),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: _pickPhoto,
                      icon: const Icon(Icons.photo_camera_back_outlined),
                      label: Text(_profileImagePath == null ? l10n.pickPhoto : l10n.changePhoto),
                    ),
                  ],
                ),
                if (_profileImagePath != null) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    _profileImagePath!.split(RegExp(r'[\\/]')).last,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: controller.isBusy ? null : _saveProfile,
                  child: Text(l10n.save),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                l10n.settings,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(
                      controller.usesRemoteBackend
                          ? Icons.cloud_done_rounded
                          : Icons.sd_storage_rounded,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            '${l10n.backend}: ${controller.backendLabel}',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            controller.usesRemoteBackend
                                ? l10n.backendRemoteBody
                                : l10n.backendLocalBody,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<AppThemePreference>(
                key: ValueKey<String>('theme-${controller.settings.themePreference.name}'),
                initialValue: controller.settings.themePreference,
                decoration: InputDecoration(labelText: l10n.theme),
                items: AppThemePreference.values
                    .map(
                      (preference) => DropdownMenuItem<AppThemePreference>(
                        value: preference,
                        child: Text(l10n.themeLabel(preference)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  controller.updateSettings(
                    controller.settings.copyWith(themePreference: value),
                  );
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey<String>('locale-${controller.settings.localeCode}'),
                initialValue: controller.settings.localeCode,
                decoration: InputDecoration(labelText: l10n.language),
                items: <DropdownMenuItem<String>>[
                  DropdownMenuItem<String>(value: 'en', child: Text(l10n.english)),
                  DropdownMenuItem<String>(value: 'de', child: Text(l10n.german)),
                ],
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  controller.updateSettings(
                    controller.settings.copyWith(localeCode: value),
                  );
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<AppUnit>(
                key: ValueKey<String>('unit-${controller.settings.unit.name}'),
                initialValue: controller.settings.unit,
                decoration: InputDecoration(labelText: l10n.units),
                items: AppUnit.values
                    .map(
                      (unit) => DropdownMenuItem<AppUnit>(
                        value: unit,
                        child: Text(l10n.unitLabel(unit)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  controller.updateSettings(
                    controller.settings.copyWith(unit: value),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      l10n.customDrinks,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  FilledButton.tonal(
                    onPressed: () => _showCustomDrinkDialog(),
                    child: Text(l10n.addCustomDrinkAction),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (controller.customDrinks.isEmpty)
                Text(
                  l10n.emptyFilter,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              else
                ...controller.customDrinks.map(
                  (drink) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                      child: Icon(drink.category.icon, color: theme.colorScheme.primary),
                    ),
                    title: Text(drink.name),
                    subtitle: Text(
                      '${l10n.categoryLabel(drink.category)} • ${controller.settings.unit.formatVolume(drink.volumeMl)}',
                    ),
                    trailing: IconButton(
                      onPressed: () => _showCustomDrinkDialog(drink),
                      icon: const Icon(Icons.edit_rounded),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                l10n.roadmap,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Text(l10n.roadmapBody),
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                      onPressed: controller.isBusy
                          ? null
                          : () async {
                              final messenger = ScaffoldMessenger.of(context);
                              final success = await controller.signOut();
                              if (!mounted) {
                                return;
                              }
                              final message = controller.takeFlashMessage();
                              if (message != null) {
                                messenger.showSnackBar(
                                  SnackBar(content: Text(message)),
                                );
                              }
                              if (!success) {
                                return;
                              }
                            },
                icon: const Icon(Icons.logout_rounded),
                label: Text(l10n.logout),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
