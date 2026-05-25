import 'package:flutter/material.dart';
import 'package:glasstrail/l10n/app_localizations.dart';

import 'app_controller.dart';
import 'app_scope.dart';
import 'beer_with_me_import.dart';

const Color _importSuccessColor = Color(0xFF1F8F5A);
const Color _importWarningColor = Color(0xFFB7791F);

enum BeerWithMePostSignUpPromptAction { importExport, later }

Future<BeerWithMePostSignUpPromptAction?> showBeerWithMePostSignUpPrompt(
  BuildContext context,
) {
  final l10n = AppLocalizations.of(context);
  final theme = Theme.of(context);
  return showDialog<BeerWithMePostSignUpPromptAction>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return PopScope(
        canPop: false,
        child: AlertDialog(
          key: const Key('post-signup-beer-with-me-dialog'),
          title: Text(l10n.beerWithMePostSignUpTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(l10n.beerWithMePostSignUpBody),
              const SizedBox(height: 12),
              Text(
                l10n.beerWithMePostSignUpHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              key: const Key('post-signup-beer-with-me-later-button'),
              onPressed: () {
                Navigator.of(
                  context,
                ).pop(BeerWithMePostSignUpPromptAction.later);
              },
              child: Text(l10n.maybeLater),
            ),
            FilledButton(
              key: const Key('post-signup-beer-with-me-import-button'),
              onPressed: () {
                Navigator.of(
                  context,
                ).pop(BeerWithMePostSignUpPromptAction.importExport);
              },
              child: Text(l10n.beerWithMeImportAction),
            ),
          ],
        ),
      );
    },
  );
}

Future<void> startBeerWithMeImportFlow(
  BuildContext context, {
  bool showProgressDialog = false,
}) async {
  final exportFile = await _pickBeerWithMeExportFile(context);
  if (!context.mounted || exportFile == null) {
    return;
  }

  final shouldImport = await _confirmBeerWithMeImport(
    context,
    exportFile.rows.length,
  );
  if (!context.mounted || shouldImport != true) {
    return;
  }

  final controller = AppScope.controllerOf(context);
  try {
    final importFuture = controller.importBeerWithMeExport(exportFile);
    late final BeerWithMeImportResult result;
    if (showProgressDialog) {
      final dialogResult = await _showBeerWithMeImportProgressDialog(
        context,
        importFuture,
      );
      result = dialogResult ?? await importFuture;
    } else {
      result = await importFuture;
    }
    if (!context.mounted) {
      return;
    }
    await _showBeerWithMeImportResult(context, result);
  } catch (_) {
    if (!context.mounted) {
      return;
    }
    _showMessage(context, AppLocalizations.of(context).somethingWentWrong);
  }
}

Future<BeerWithMeImportFile?> _pickBeerWithMeExportFile(
  BuildContext context,
) async {
  final l10n = AppLocalizations.of(context);
  final importFileService = AppScope.importFileServiceOf(context);
  try {
    final selectedFile = await importFileService.pickJsonFile();
    if (!context.mounted || selectedFile == null) {
      return null;
    }

    final exportFile = parseBeerWithMeExportFile(selectedFile.contents);
    if (exportFile.rows.isEmpty) {
      _showMessage(context, l10n.beerWithMeImportEmpty);
      return null;
    }
    return exportFile;
  } on FormatException {
    if (context.mounted) {
      _showMessage(context, l10n.beerWithMeImportInvalidFile);
    }
    return null;
  } catch (_) {
    if (context.mounted) {
      _showMessage(context, l10n.beerWithMeImportReadFailed);
    }
    return null;
  }
}

Future<bool?> _confirmBeerWithMeImport(BuildContext context, int rowCount) {
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

Future<BeerWithMeImportResult?> _showBeerWithMeImportProgressDialog(
  BuildContext context,
  Future<BeerWithMeImportResult> importFuture,
) {
  final controller = AppScope.controllerOf(context);
  return showDialog<BeerWithMeImportResult>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return _BeerWithMeImportProgressDialog(
        controller: controller,
        importFuture: importFuture,
      );
    },
  );
}

Future<void> _showBeerWithMeImportResult(
  BuildContext context,
  BeerWithMeImportResult result,
) {
  final l10n = AppLocalizations.of(context);
  return showDialog<void>(
    context: context,
    builder: (context) {
      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;
      final errors = result.errors;
      final summaryRows = <Widget>[
        if (result.importedCount > 0)
          _buildBeerWithMeImportSummaryRow(
            context,
            key: const Key('beer-with-me-import-summary-imported'),
            icon: Icons.check_circle_rounded,
            color: _importSuccessColor,
            message: l10n.beerWithMeImportResultImported(result.importedCount),
          ),
        if (result.skippedDuplicateCount > 0)
          _buildBeerWithMeImportSummaryRow(
            context,
            key: const Key('beer-with-me-import-summary-skipped'),
            icon: Icons.warning_amber_rounded,
            color: _importWarningColor,
            message: l10n.beerWithMeImportResultSkipped(
              result.skippedDuplicateCount,
            ),
          ),
        if (result.errorCount > 0)
          _buildBeerWithMeImportSummaryRow(
            context,
            key: const Key('beer-with-me-import-summary-errors'),
            icon: Icons.error_outline_rounded,
            color: colorScheme.error,
            message: l10n.beerWithMeImportResultErrors(result.errorCount),
          ),
        _buildBeerWithMeImportSummaryRow(
          context,
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
                    context,
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
                    _buildBeerWithMeImportErrorCard(context, error),
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

Widget _buildBeerWithMeImportBanner(
  BuildContext context, {
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

Widget _buildBeerWithMeImportSummaryRow(
  BuildContext context, {
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

Widget _buildBeerWithMeImportErrorCard(
  BuildContext context,
  BeerWithMeImportError error,
) {
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

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

class _BeerWithMeImportProgressDialog extends StatefulWidget {
  const _BeerWithMeImportProgressDialog({
    required this.controller,
    required this.importFuture,
  });

  final AppController controller;
  final Future<BeerWithMeImportResult> importFuture;

  @override
  State<_BeerWithMeImportProgressDialog> createState() =>
      _BeerWithMeImportProgressDialogState();
}

class _BeerWithMeImportProgressDialogState
    extends State<_BeerWithMeImportProgressDialog> {
  @override
  void initState() {
    super.initState();
    widget.importFuture.then(
      _closeWithResult,
      onError: (Object error, StackTrace stackTrace) {
        if (!mounted) {
          return;
        }
        Navigator.of(context).pop();
      },
    );
  }

  void _closeWithResult(BeerWithMeImportResult result) {
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final l10n = AppLocalizations.of(context);
          final theme = Theme.of(context);
          final importProgress = widget.controller.beerWithMeImportProgress;
          final isCancellationRequested =
              widget.controller.isBeerWithMeImportCancellationRequested;
          return AlertDialog(
            key: const Key('beer-with-me-import-progress-dialog'),
            title: Text(l10n.beerWithMeImport),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l10n.beerWithMeImportProgress(
                      importProgress?.processedCount ?? 0,
                      importProgress?.totalCount ?? 0,
                    ),
                    key: const Key('beer-with-me-import-progress-label'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    key: const Key('beer-with-me-import-progress-indicator'),
                    value: importProgress?.progressValue,
                    minHeight: 8,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.beerWithMeImportProgressDetails(
                      importProgress?.importedCount ?? 0,
                      importProgress?.skippedDuplicateCount ?? 0,
                      importProgress?.errorCount ?? 0,
                    ),
                    key: const Key('beer-with-me-import-progress-details'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              FilledButton.tonalIcon(
                key: const Key('beer-with-me-import-progress-cancel-button'),
                style: FilledButton.styleFrom(
                  foregroundColor: theme.colorScheme.onErrorContainer,
                  backgroundColor: theme.colorScheme.errorContainer,
                ),
                onPressed: isCancellationRequested
                    ? null
                    : () {
                        widget.controller.requestBeerWithMeImportCancellation();
                      },
                icon: const Icon(Icons.stop_circle_outlined),
                label: Text(
                  isCancellationRequested
                      ? l10n.beerWithMeImportCancelling
                      : l10n.beerWithMeImportCancelAction,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
