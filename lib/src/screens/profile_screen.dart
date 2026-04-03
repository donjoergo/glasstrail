import 'package:flutter/material.dart';
import 'package:glasstrail/l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_controller.dart';
import '../app_language.dart';
import '../app_routes.dart';
import '../app_scope.dart';
import '../birthday.dart';
import '../l10n_extensions.dart';
import '../models.dart';
import '../widgets/app_media.dart';

enum _ProfilePendingSetting { theme, language, unit, handedness }

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static final Uri _gitHubRepositoryUri = Uri.parse(
    'https://github.com/donjoergo/GlassTrail',
  );

  _ProfilePendingSetting? _pendingSetting;
  late final Future<String?> _appVersionFuture;

  @override
  void initState() {
    super.initState();
    _appVersionFuture = _loadAppVersion();
  }

  Future<String?> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final version = packageInfo.version.trim();
      return version.isEmpty ? null : version;
    } catch (_) {
      return null;
    }
  }

  Future<void> _openEditProfile() async {
    final result = await Navigator.of(context).pushNamed(AppRoutes.editProfile);
    final message = result is String ? result : null;
    if (!mounted || message == null || message.isEmpty) {
      return;
    }
    _showMessage(message);
  }

  Future<void> _updateSettings(
    _ProfilePendingSetting pendingSetting,
    UserSettings settings,
  ) async {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.controllerOf(context);
    setState(() {
      _pendingSetting = pendingSetting;
    });
    final success = await controller.updateSettings(settings);
    if (!mounted) {
      return;
    }
    setState(() {
      _pendingSetting = null;
    });
    final message = controller.takeFlashMessage(l10n);
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

  Future<void> _openGitHubRepository() async {
    final l10n = AppLocalizations.of(context);

    try {
      final launched = await launchUrl(
        _gitHubRepositoryUri,
        mode: LaunchMode.externalApplication,
      );
      if (!mounted || launched) {
        return;
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
    }

    _showMessage(l10n.somethingWentWrong);
  }

  String _formatAppVersionLabel(AppLocalizations l10n, String? version) {
    if (version == null || version.isEmpty) {
      return l10n.appTitle;
    }
    return '${l10n.appTitle} V$version';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.controllerOf(context);
    final user = controller.currentUser!;
    final theme = Theme.of(context);
    final settings = controller.settings;
    final routeMemory = AppScope.routeMemoryOf(context);
    final navigator = Navigator.of(context);
    final isBusy = controller.isBusy;
    final isSigningOut = controller.isBusyFor(AppBusyAction.signOut);
    final editProfileButton = FilledButton.tonalIcon(
      key: const Key('profile-edit-button'),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(40),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: isBusy ? null : _openEditProfile,
      icon: const Icon(Icons.edit_outlined),
      label: Text(l10n.editProfile),
    );
    final logoutButton = FilledButton.tonalIcon(
      key: const Key('profile-logout-button'),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(40),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      onPressed: isBusy
          ? null
          : () async {
              final success = await controller.signOut();
              if (!mounted) {
                return;
              }
              final message = controller.takeFlashMessage(l10n);
              if (message != null) {
                _showMessage(message);
              }
              if (!success) {
                return;
              }
              await routeMemory.markLoggedOut();
              if (!mounted) {
                return;
              }
              navigator.pushReplacementNamed(AppRoutes.auth);
            },
      icon: isSigningOut
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.logout_rounded),
      label: Text(l10n.logout),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      children: <Widget>[
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        AppAvatar(
                          imagePath: user.profileImagePath,
                          radius: 30,
                          backgroundColor: theme.colorScheme.primary.withValues(
                            alpha: 0.14,
                          ),
                          fallback: Text(
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
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user.email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (user.birthday != null) ...<Widget>[
                          const SizedBox(width: 12),
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
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: double.infinity, child: editProfileButton),
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
                enabled: !isBusy,
                isLoading:
                    _pendingSetting == _ProfilePendingSetting.theme &&
                    controller.isBusyFor(AppBusyAction.updateSettings),
                loadingIndicatorKey: const Key('theme-settings-loading'),
                key: const Key('theme-segmented-control'),
                segments: AppThemePreference.values
                    .map(
                      (preference) => ButtonSegment<AppThemePreference>(
                        value: preference,
                        label: Text(l10n.themeLabel(preference)),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) => _updateSettings(
                  _ProfilePendingSetting.theme,
                  settings.copyWith(themePreference: value),
                ),
              ),
              const SizedBox(height: 16),
              _SettingsSegmentedField<String>(
                label: l10n.language,
                value: settings.localeCode,
                enabled: !isBusy,
                isLoading:
                    _pendingSetting == _ProfilePendingSetting.language &&
                    controller.isBusyFor(AppBusyAction.updateSettings),
                loadingIndicatorKey: const Key('language-settings-loading'),
                key: const Key('language-segmented-control'),
                segments: <ButtonSegment<String>>[
                  ButtonSegment<String>(
                    value: kEnglishLocaleCode,
                    label: Text(l10n.english),
                  ),
                  ButtonSegment<String>(
                    value: kGermanLocaleCode,
                    label: Text(l10n.german),
                  ),
                  ButtonSegment<String>(
                    value: kFranconianLocaleCode,
                    label: Text(l10n.franconian),
                  ),
                ],
                onChanged: (value) => _updateSettings(
                  _ProfilePendingSetting.language,
                  settings.copyWith(localeCode: value),
                ),
              ),
              const SizedBox(height: 16),
              _SettingsSegmentedField<AppUnit>(
                label: l10n.units,
                value: settings.unit,
                enabled: !isBusy,
                isLoading:
                    _pendingSetting == _ProfilePendingSetting.unit &&
                    controller.isBusyFor(AppBusyAction.updateSettings),
                loadingIndicatorKey: const Key('unit-settings-loading'),
                key: const Key('unit-segmented-control'),
                segments: AppUnit.values
                    .map(
                      (unit) => ButtonSegment<AppUnit>(
                        value: unit,
                        label: Text(l10n.unitLabel(unit)),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) => _updateSettings(
                  _ProfilePendingSetting.unit,
                  settings.copyWith(unit: value),
                ),
              ),
              const SizedBox(height: 16),
              _SettingsSegmentedField<AppHandedness>(
                label: l10n.handedness,
                value: settings.handedness,
                enabled: !isBusy,
                isLoading:
                    _pendingSetting == _ProfilePendingSetting.handedness &&
                    controller.isBusyFor(AppBusyAction.updateSettings),
                loadingIndicatorKey: const Key('handedness-settings-loading'),
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
                onChanged: (value) => _updateSettings(
                  _ProfilePendingSetting.handedness,
                  settings.copyWith(handedness: value),
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
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, child: logoutButton),
        const SizedBox(height: 20),
        Container(
          key: const Key('profile-about-section'),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                l10n.about,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              FutureBuilder<String?>(
                future: _appVersionFuture,
                builder: (context, snapshot) {
                  return Text(
                    _formatAppVersionLabel(l10n, snapshot.data),
                    key: const Key('profile-about-version'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: ListTile(
                  key: const Key('profile-about-github-button'),
                  onTap: _openGitHubRepository,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  leading: Icon(
                    Icons.code_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(
                    l10n.github,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    _gitHubRepositoryUri.toString(),
                    style: theme.textTheme.bodySmall,
                  ),
                  trailing: const Icon(Icons.open_in_new_rounded),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'created with ❤️, ☕ and 🍺 by Jörg Dorlach',
                key: const Key('profile-about-attribution'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
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
    this.isLoading = false,
    this.loadingIndicatorKey,
  });

  final String label;
  final T value;
  final List<ButtonSegment<T>> segments;
  final ValueChanged<T> onChanged;
  final bool enabled;
  final bool isLoading;
  final Key? loadingIndicatorKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (isLoading) ...<Widget>[
              const SizedBox(width: 8),
              SizedBox.square(
                dimension: 14,
                child: CircularProgressIndicator(
                  key: loadingIndicatorKey,
                  strokeWidth: 2,
                ),
              ),
            ],
          ],
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
