import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glasstrail/l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_controller.dart';
import '../app_routes.dart';
import '../app_scope.dart';
import '../beer_with_me_import.dart';
import '../birthday.dart';
import '../friend_profile_links.dart';
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
  static const Color _importSuccessColor = Color(0xFF1F8F5A);
  static const Color _importWarningColor = Color(0xFFB7791F);
  static final Uri _gitHubRepositoryUri = Uri.parse(
    'https://github.com/donjoergo/GlassTrail',
  );
  static final Uri _changelogUri = Uri.parse(
    'https://github.com/donjoergo/glasstrail/blob/main/CHANGELOG.md',
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

  Future<void> _pickBeerWithMeImport() async {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.controllerOf(context);
    final importFileService = AppScope.importFileServiceOf(context);

    try {
      final selectedFile = await importFileService.pickJsonFile();
      if (!mounted || selectedFile == null) {
        return;
      }

      final exportFile = parseBeerWithMeExportFile(selectedFile.contents);
      if (exportFile.rows.isEmpty) {
        _showMessage(l10n.beerWithMeImportEmpty);
        return;
      }

      final shouldImport = await _confirmBeerWithMeImport(
        exportFile.rows.length,
      );
      if (!mounted || shouldImport != true) {
        return;
      }

      final result = await controller.importBeerWithMeExport(exportFile);
      if (!mounted) {
        return;
      }
      await _showBeerWithMeImportResult(result);
    } on FormatException {
      if (!mounted) {
        return;
      }
      _showMessage(l10n.beerWithMeImportInvalidFile);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showMessage(l10n.beerWithMeImportReadFailed);
    }
  }

  Future<bool?> _confirmBeerWithMeImport(int rowCount) {
    final l10n = AppLocalizations.of(context);
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          key: const Key('beer-with-me-import-confirm-dialog'),
          title: Text(l10n.beerWithMeImportConfirmTitle),
          content: Text(l10n.beerWithMeImportConfirmBody(rowCount)),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.beerWithMeImportAction),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showBeerWithMeImportResult(BeerWithMeImportResult result) {
    final l10n = AppLocalizations.of(context);
    final errors = result.errors;
    return showDialog<void>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final summaryRows = <Widget>[
          if (result.importedCount > 0)
            _buildBeerWithMeImportSummaryRow(
              key: const Key('beer-with-me-import-summary-imported'),
              icon: Icons.check_circle_rounded,
              color: _importSuccessColor,
              message: l10n.beerWithMeImportResultImported(
                result.importedCount,
              ),
            ),
          if (result.skippedDuplicateCount > 0)
            _buildBeerWithMeImportSummaryRow(
              key: const Key('beer-with-me-import-summary-skipped'),
              icon: Icons.warning_amber_rounded,
              color: _importWarningColor,
              message: l10n.beerWithMeImportResultSkipped(
                result.skippedDuplicateCount,
              ),
            ),
          if (result.errorCount > 0)
            _buildBeerWithMeImportSummaryRow(
              key: const Key('beer-with-me-import-summary-errors'),
              icon: Icons.error_outline_rounded,
              color: colorScheme.error,
              message: l10n.beerWithMeImportResultErrors(result.errorCount),
            ),
          _buildBeerWithMeImportSummaryRow(
            key: const Key('beer-with-me-import-summary-total'),
            icon: Icons.inventory_2_outlined,
            color: colorScheme.primary,
            message: l10n.beerWithMeImportResultTotal(result.totalRows),
            emphasize: false,
          ),
        ];
        return AlertDialog(
          key: const Key('beer-with-me-import-result-dialog'),
          title: Text(l10n.beerWithMeImportResultTitle),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440, maxHeight: 480),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (result.wasCancelled) ...<Widget>[
                    _buildBeerWithMeImportBanner(
                      icon: Icons.warning_amber_rounded,
                      color: _importWarningColor,
                      message: l10n.beerWithMeImportResultCancelled(
                        result.processedCount,
                        result.totalRows,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  for (
                    var index = 0;
                    index < summaryRows.length;
                    index++
                  ) ...<Widget>[
                    if (index > 0) const SizedBox(height: 8),
                    summaryRows[index],
                  ],
                  if (errors.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 16),
                    Row(
                      children: <Widget>[
                        Icon(
                          Icons.error_outline_rounded,
                          size: 18,
                          color: colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.beerWithMeImportErrorListTitle,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    for (final error in errors) ...<Widget>[
                      _buildBeerWithMeImportErrorCard(error),
                      const SizedBox(height: 10),
                    ],
                  ],
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.close),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBeerWithMeImportBanner({
    required IconData icon,
    required Color color,
    required String message,
  }) {
    final theme = Theme.of(context);
    return Container(
      key: const Key('beer-with-me-import-status-banner'),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBeerWithMeImportSummaryRow({
    required Key key,
    required IconData icon,
    required Color color,
    required String message,
    bool emphasize = true,
  }) {
    final theme = Theme.of(context);
    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: emphasize ? 0.09 : 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: emphasize ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBeerWithMeImportErrorCard(BeerWithMeImportError error) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.error;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.error_outline_rounded, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _formatBeerWithMeImportError(error),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatBeerWithMeImportError(BeerWithMeImportError error) {
    final parts = <String>['#${error.rowNumber}'];
    final sourceId = error.sourceId?.trim();
    final glassType = error.glassType?.trim();
    if (sourceId != null && sourceId.isNotEmpty) {
      parts.add('ID $sourceId');
    }
    if (glassType != null && glassType.isNotEmpty) {
      parts.add(glassType);
    }
    return '${parts.join(' • ')}: ${error.message}';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showFriendProfileLink() async {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.controllerOf(context);
    final profile = await controller.loadOwnFriendProfile();
    if (!mounted) {
      return;
    }
    final message = controller.takeFlashMessage(l10n);
    if (message != null) {
      _showMessage(message);
    }
    final shareCode = profile?.profileShareCode;
    if (profile == null || shareCode == null || shareCode.isEmpty) {
      return;
    }

    final link = friendProfileLinkForCode(shareCode);
    await showDialog<void>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          key: const Key('friend-profile-link-dialog'),
          title: Text(l10n.friendProfileLinkTitle),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420, maxHeight: 420),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    key: const Key('friend-profile-qr-code'),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: SizedBox.square(
                      dimension: 180,
                      child: QrImageView(
                        data: link,
                        version: QrVersions.auto,
                        size: 180,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.friendProfileLinkBody,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: SelectableText(
                      link,
                      key: const Key('friend-profile-link-text'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.close),
            ),
            TextButton.icon(
              key: const Key('friend-profile-copy-link-button'),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: link));
                if (!context.mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.friendProfileLinkCopied)),
                );
              },
              icon: const Icon(Icons.copy_rounded),
              label: Text(l10n.copyLink),
            ),
            FilledButton.icon(
              key: const Key('friend-profile-share-link-button'),
              onPressed: () async {
                try {
                  await SharePlus.instance.share(
                    ShareParams(
                      uri: Uri.parse(link),
                      title: l10n.friendProfileShareTitle,
                    ),
                  );
                } catch (_) {
                  if (!context.mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.somethingWentWrong)),
                  );
                }
              },
              icon: const Icon(Icons.ios_share_rounded),
              label: Text(l10n.share),
            ),
          ],
        );
      },
    );
  }

  Future<void> _acceptFriendRequest(FriendConnection connection) async {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.controllerOf(context);
    await controller.acceptFriendRequest(connection);
    if (!mounted) {
      return;
    }
    final message = controller.takeFlashMessage(l10n);
    if (message != null) {
      _showMessage(message);
    }
  }

  Future<void> _rejectFriendRequest(FriendConnection connection) async {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.controllerOf(context);
    await controller.rejectFriendRequest(connection);
    if (!mounted) {
      return;
    }
    final message = controller.takeFlashMessage(l10n);
    if (message != null) {
      _showMessage(message);
    }
  }

  Future<void> _removeFriend(FriendConnection connection) async {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.controllerOf(context);
    await controller.removeFriend(connection);
    if (!mounted) {
      return;
    }
    final message = controller.takeFlashMessage(l10n);
    if (message != null) {
      _showMessage(message);
    }
  }

  LaunchMode get _changelogLaunchMode {
    return switch (defaultTargetPlatform) {
      TargetPlatform.android ||
      TargetPlatform.iOS => LaunchMode.inAppBrowserView,
      _ => LaunchMode.externalApplication,
    };
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

  Future<void> _openChangelog() async {
    final l10n = AppLocalizations.of(context);

    try {
      final launched = await launchUrl(
        _changelogUri,
        mode: _changelogLaunchMode,
        browserConfiguration: const BrowserConfiguration(showTitle: true),
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
    final isImporting = controller.isBusyFor(AppBusyAction.importBeerWithMe);
    final importProgress = controller.beerWithMeImportProgress;
    final isImportCancellationRequested =
        controller.isBeerWithMeImportCancellationRequested;
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
    final beerWithMeImportButton = FilledButton.tonalIcon(
      key: const Key('profile-import-button'),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(40),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      onPressed: isBusy ? null : _pickBeerWithMeImport,
      icon: isImporting
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.file_upload_outlined),
      label: Text(l10n.beerWithMeImportAction),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                            key: const Key('profile-avatar'),
                            imagePath: user.profileImagePath,
                            radius: 30,
                            backgroundColor: theme.colorScheme.primary
                                .withValues(alpha: 0.14),
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
                              ],
                            ),
                          ),
                          if (user.birthday != null) ...<Widget>[
                            const SizedBox(width: 12),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
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
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
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
          _buildFriendsSection(theme, l10n, controller, isBusy),
          const SizedBox(height: 20),
          Container(
            key: const Key('profile-import-section'),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.beerWithMeImport,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(l10n.beerWithMeImportBody),
                const SizedBox(height: 16),
                SizedBox(width: double.infinity, child: beerWithMeImportButton),
                if (isImporting && importProgress != null) ...<Widget>[
                  const SizedBox(height: 16),
                  Text(
                    l10n.beerWithMeImportProgress(
                      importProgress.processedCount,
                      importProgress.totalCount,
                    ),
                    key: const Key('profile-import-progress-label'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    key: const Key('profile-import-progress-indicator'),
                    value: importProgress.progressValue,
                    minHeight: 8,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.beerWithMeImportProgressDetails(
                      importProgress.importedCount,
                      importProgress.skippedDuplicateCount,
                      importProgress.errorCount,
                    ),
                    key: const Key('profile-import-progress-details'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    key: const Key('profile-import-cancel-button'),
                    style: FilledButton.styleFrom(
                      foregroundColor: theme.colorScheme.onErrorContainer,
                      backgroundColor: theme.colorScheme.errorContainer,
                    ),
                    onPressed: isImportCancellationRequested
                        ? null
                        : () {
                            controller.requestBeerWithMeImportCancellation();
                          },
                    icon: const Icon(Icons.stop_circle_outlined),
                    label: Text(
                      isImportCancellationRequested
                          ? l10n.beerWithMeImportCancelling
                          : l10n.beerWithMeImportCancelAction,
                    ),
                  ),
                ],
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
                      value: 'en',
                      label: Text(l10n.english),
                    ),
                    ButtonSegment<String>(
                      value: 'de',
                      label: Text(l10n.german),
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
          SizedBox(width: double.infinity, child: logoutButton),
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
                    return Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: ListTile(
                        key: const Key('profile-about-version-button'),
                        onTap: _openChangelog,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        leading: Icon(
                          Icons.article_outlined,
                          color: theme.colorScheme.primary,
                        ),
                        title: Text(
                          _formatAppVersionLabel(l10n, snapshot.data),
                          key: const Key('profile-about-version'),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          _changelogUri.toString(),
                          style: theme.textTheme.bodySmall,
                        ),
                        trailing: const Icon(Icons.open_in_new_rounded),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: ListTile(
                    key: const Key('profile-about-github-button'),
                    onTap: _openGitHubRepository,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    minVerticalPadding: 0,
                    visualDensity: const VisualDensity(vertical: -2),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.open_in_new_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                Text.rich(
                  TextSpan(
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    children: <InlineSpan>[
                      const TextSpan(text: 'created with '),
                      TextSpan(
                        text: '❤️',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontFamily: 'ProfileEmoji',
                        ),
                      ),
                      const TextSpan(text: ', '),
                      TextSpan(
                        text: '☕',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontFamily: 'ProfileEmoji',
                        ),
                      ),
                      const TextSpan(text: ' and '),
                      TextSpan(
                        text: '🍺',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontFamily: 'ProfileEmoji',
                        ),
                      ),
                      const TextSpan(text: ' by Jörg Dorlach'),
                    ],
                  ),
                  key: const Key('profile-about-attribution'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsSection(
    ThemeData theme,
    AppLocalizations l10n,
    AppController controller,
    bool isBusy,
  ) {
    final friends = controller.friends;
    final incomingRequests = controller.incomingFriendRequests;
    final outgoingRequests = controller.outgoingFriendRequests;
    final hasConnections =
        friends.isNotEmpty ||
        incomingRequests.isNotEmpty ||
        outgoingRequests.isNotEmpty;

    return Container(
      key: const Key('profile-friends-section'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.friends,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              key: const Key('profile-friend-link-button'),
              onPressed: isBusy ? null : _showFriendProfileLink,
              icon: controller.isBusyFor(AppBusyAction.loadFriendProfile)
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.qr_code_2_rounded),
              label: Text(l10n.friendProfileLinkAction),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.friendsSectionBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          if (!hasConnections)
            _FriendsEmptyState(message: l10n.friendsEmpty)
          else ...<Widget>[
            for (final request in incomingRequests)
              _FriendConnectionTile(
                key: ValueKey<String>('friend-request-incoming-${request.id}'),
                connection: request,
                statusLabel: l10n.friendIncomingRequest,
                leadingColor: theme.colorScheme.tertiaryContainer,
                trailing: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    FilledButton.tonalIcon(
                      key: Key('friend-request-accept-${request.id}'),
                      onPressed: isBusy
                          ? null
                          : () => _acceptFriendRequest(request),
                      icon: const Icon(Icons.check_rounded),
                      label: Text(l10n.accept),
                    ),
                    OutlinedButton.icon(
                      key: Key('friend-request-reject-${request.id}'),
                      onPressed: isBusy
                          ? null
                          : () => _rejectFriendRequest(request),
                      icon: const Icon(Icons.close_rounded),
                      label: Text(l10n.reject),
                    ),
                  ],
                ),
              ),
            for (final friend in friends)
              _FriendConnectionTile(
                key: ValueKey<String>('friend-${friend.id}'),
                connection: friend,
                statusLabel: l10n.friendAccepted,
                leadingColor: theme.colorScheme.primaryContainer,
                trailing: OutlinedButton.icon(
                  key: Key('friend-remove-${friend.id}'),
                  onPressed: isBusy ? null : () => _removeFriend(friend),
                  icon: const Icon(Icons.person_remove_outlined),
                  label: Text(l10n.unfriend),
                ),
              ),
            for (final request in outgoingRequests)
              _FriendConnectionTile(
                key: ValueKey<String>('friend-request-outgoing-${request.id}'),
                connection: request,
                statusLabel: l10n.friendRequestPending,
                leadingColor: theme.colorScheme.secondaryContainer,
                trailing: _PendingFriendRequestChip(label: l10n.pending),
              ),
          ],
        ],
      ),
    );
  }
}

class _FriendsEmptyState extends StatelessWidget {
  const _FriendsEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const Key('profile-friends-empty'),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _FriendConnectionTile extends StatelessWidget {
  const _FriendConnectionTile({
    super.key,
    required this.connection,
    required this.statusLabel,
    required this.leadingColor,
    required this.trailing,
  });

  final FriendConnection connection;
  final String statusLabel;
  final Color leadingColor;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = connection.profile;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: <Widget>[
          AppAvatar(
            imagePath: profile.profileImagePath,
            radius: 23,
            backgroundColor: leadingColor,
            fallback: Text(
              profile.initials,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  profile.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }
}

class _PendingFriendRequestChip extends StatelessWidget {
  const _PendingFriendRequestChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const Key('friend-request-pending-chip'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.secondary,
          fontWeight: FontWeight.w800,
        ),
      ),
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
