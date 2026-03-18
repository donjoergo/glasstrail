import 'package:flutter/material.dart';

import '../app_localizations.dart';
import '../app_scope.dart';
import '../birthday.dart';
import '../models.dart';
import 'custom_drink_dialog.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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
      _showMessage(message);
    }
  }

  Future<void> _openEditProfile() async {
    final message = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(builder: (_) => const EditProfileScreen()),
    );
    if (!mounted || message == null || message.isEmpty) {
      return;
    }
    _showMessage(message);
  }

  Future<void> _updateSettings(UserSettings settings) async {
    final controller = AppScope.controllerOf(context);
    final success = await controller.updateSettings(settings);
    if (!mounted) {
      return;
    }
    final message = controller.takeFlashMessage();
    if (message != null) {
      _showMessage(message);
    }
    if (!success) {
      return;
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.controllerOf(context);
    final user = controller.currentUser!;
    final theme = Theme.of(context);
    final settings = controller.settings;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      children: <Widget>[
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: theme.colorScheme.primary.withValues(
                      alpha: 0.14,
                    ),
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
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.email,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (user.birthday != null) ...<Widget>[
                const SizedBox(height: 16),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          Icons.cake_outlined,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          formatBirthdayMonthDay(
                            user.birthday!,
                            settings.localeCode,
                          ),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                key: const Key('profile-edit-button'),
                onPressed: controller.isBusy ? null : _openEditProfile,
                icon: const Icon(Icons.edit_outlined),
                label: Text(l10n.editProfile),
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
                l10n.settings,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
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
              const SizedBox(height: 20),
              _SettingsSegmentedField<AppThemePreference>(
                label: l10n.theme,
                value: settings.themePreference,
                enabled: !controller.isBusy,
                key: const Key('theme-segmented-control'),
                segments: AppThemePreference.values
                    .map(
                      (preference) => ButtonSegment<AppThemePreference>(
                        value: preference,
                        label: Text(l10n.themeLabel(preference)),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) =>
                    _updateSettings(settings.copyWith(themePreference: value)),
              ),
              const SizedBox(height: 16),
              _SettingsSegmentedField<String>(
                label: l10n.language,
                value: settings.localeCode,
                enabled: !controller.isBusy,
                key: const Key('language-segmented-control'),
                segments: <ButtonSegment<String>>[
                  ButtonSegment<String>(value: 'en', label: Text(l10n.english)),
                  ButtonSegment<String>(value: 'de', label: Text(l10n.german)),
                ],
                onChanged: (value) =>
                    _updateSettings(settings.copyWith(localeCode: value)),
              ),
              const SizedBox(height: 16),
              _SettingsSegmentedField<AppUnit>(
                label: l10n.units,
                value: settings.unit,
                enabled: !controller.isBusy,
                key: const Key('unit-segmented-control'),
                segments: AppUnit.values
                    .map(
                      (unit) => ButtonSegment<AppUnit>(
                        value: unit,
                        label: Text(l10n.unitLabel(unit)),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) =>
                    _updateSettings(settings.copyWith(unit: value)),
              ),
              const SizedBox(height: 16),
              _SettingsSegmentedField<AppHandedness>(
                label: l10n.handedness,
                value: settings.handedness,
                enabled: !controller.isBusy,
                key: const Key('handedness-segmented-control'),
                segments: <ButtonSegment<AppHandedness>>[
                  ButtonSegment<AppHandedness>(
                    value: AppHandedness.left,
                    label: Text(l10n.handednessLabel(AppHandedness.left)),
                  ),
                  ButtonSegment<AppHandedness>(
                    value: AppHandedness.right,
                    label: Text(l10n.handednessLabel(AppHandedness.right)),
                  ),
                ],
                onChanged: (value) =>
                    _updateSettings(settings.copyWith(handedness: value)),
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
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
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
                      backgroundColor: theme.colorScheme.primary.withValues(
                        alpha: 0.12,
                      ),
                      child: Icon(
                        drink.category.icon,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    title: Text(drink.name),
                    subtitle: Text(
                      '${l10n.categoryLabel(drink.category)} • ${settings.unit.formatVolume(drink.volumeMl)}',
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
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(l10n.roadmapBody),
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: controller.isBusy
                    ? null
                    : () async {
                        final success = await controller.signOut();
                        if (!mounted) {
                          return;
                        }
                        final message = controller.takeFlashMessage();
                        if (message != null) {
                          _showMessage(message);
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

class _SettingsSegmentedField<T> extends StatelessWidget {
  const _SettingsSegmentedField({
    super.key,
    required this.label,
    required this.value,
    required this.segments,
    required this.onChanged,
    required this.enabled,
  });

  final String label;
  final T value;
  final List<ButtonSegment<T>> segments;
  final ValueChanged<T> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<T>(
            segments: segments,
            selected: <T>{value},
            emptySelectionAllowed: false,
            showSelectedIcon: false,
            expandedInsets: EdgeInsets.zero,
            onSelectionChanged: enabled
                ? (selection) => onChanged(selection.first)
                : null,
          ),
        ),
      ],
    );
  }
}
