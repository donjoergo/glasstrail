import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:glasstrail/l10n/l10n.dart';
import 'package:glasstrail/state/app_controller.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({required this.controller, super.key});

  final AppController controller;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Future<void> _pickAndValidateImport() async {
    final l10n = context.l10n;
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );

    if (picked == null) {
      return;
    }

    final file = picked.files.single;
    String content = '';

    if (file.path != null) {
      content = await File(file.path!).readAsString();
    } else if (file.bytes != null) {
      content = utf8.decode(file.bytes!);
    }

    if (content.trim().isEmpty) {
      if (!mounted) {
        return;
      }
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.validationErrors),
          content: const Text('File was empty.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
          ],
        ),
      );
      return;
    }

    final result = widget.controller.validateLegacyImport(content);
    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(result.errors.isEmpty
              ? l10n.importPreview
              : l10n.validationErrors),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${l10n.entries}: ${result.totalEntries}'),
                  Text('${l10n.validEntries}: ${result.validEntries}'),
                  if (result.errors.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ...result.errors.take(10).map(
                          (error) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text('• $error'),
                          ),
                        ),
                  ],
                  if (result.rows.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    DataTable(
                      columns: [
                        DataColumn(label: Text(l10n.legacyType)),
                        DataColumn(label: Text(l10n.mappedTo)),
                        DataColumn(label: Text(l10n.count)),
                      ],
                      rows: result.rows
                          .take(8)
                          .map(
                            (row) => DataRow(
                              cells: [
                                DataCell(Text(row.legacyType)),
                                DataCell(Text(row.mappedType)),
                                DataCell(Text('${row.count}')),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            if (result.validEntries > 0)
              FilledButton(
                onPressed: () {
                  widget.controller.applyLastImport();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.importSuccess)),
                  );
                },
                child: Text(l10n.importNow),
              ),
          ],
        );
      },
    );
  }

  Future<void> _pickQuietHours({required bool start}) async {
    final initial = start
        ? widget.controller.quietHoursStart
        : widget.controller.quietHoursEnd;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );

    if (picked == null) {
      return;
    }

    if (start) {
      widget.controller.setQuietHours(picked, widget.controller.quietHoursEnd);
    } else {
      widget.controller
          .setQuietHours(widget.controller.quietHoursStart, picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final import = widget.controller.lastImportResult;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      widget.controller.usingRemoteApi
                          ? Icons.cloud_done_outlined
                          : Icons.cloud_off_outlined,
                    ),
                    title: Text(
                      widget.controller.usingRemoteApi
                          ? 'Backend API enabled'
                          : 'Backend API disabled',
                    ),
                    subtitle: Text(
                      widget.controller.usingRemoteApi
                          ? widget.controller.apiBaseUrl
                          : 'Using local mock data. Start with '
                              '--dart-define=USE_REMOTE_API=true and '
                              '--dart-define=API_BASE_URL=http://localhost:3000.',
                    ),
                  ),
                  if (widget.controller.usingRemoteApi) ...[
                    FilledButton.tonalIcon(
                      onPressed: widget.controller.isRemoteSyncing
                          ? null
                          : () async {
                              await widget.controller.refreshFeed();
                              if (!context.mounted) {
                                return;
                              }
                              final error = widget.controller.lastSyncError;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    error ?? 'Remote feed sync completed.',
                                  ),
                                ),
                              );
                            },
                      icon: widget.controller.isRemoteSyncing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.sync),
                      label: const Text('Sync feed now'),
                    ),
                    if (widget.controller.lastSyncError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        widget.controller.lastSyncError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.themeMode,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  SegmentedButton<ThemeMode>(
                    segments: [
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text(l10n.themeSystem),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text(l10n.themeLight),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text(l10n.themeDark),
                      ),
                    ],
                    selected: {widget.controller.themeMode},
                    onSelectionChanged: (selection) {
                      widget.controller.setThemeMode(selection.first);
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(l10n.language,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  SegmentedButton<Locale>(
                    segments: [
                      ButtonSegment(
                        value: const Locale('en'),
                        label: Text(l10n.langEnglish),
                      ),
                      ButtonSegment(
                        value: const Locale('de'),
                        label: Text(l10n.langGerman),
                      ),
                    ],
                    selected: {widget.controller.locale},
                    onSelectionChanged: (selection) {
                      widget.controller.setLocale(selection.first);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: Text(l10n.notificationPrefs),
                ),
                SwitchListTile(
                  title: Text(l10n.friendDrinkNotifications),
                  value: widget.controller.friendDrinkNotifications,
                  onChanged: widget.controller.setFriendDrinkNotifications,
                ),
                ListTile(
                  leading: const Icon(Icons.dark_mode_outlined),
                  title: const Text('Quiet hours start'),
                  subtitle:
                      Text(widget.controller.quietHoursStart.format(context)),
                  onTap: () => _pickQuietHours(start: true),
                ),
                ListTile(
                  leading: const Icon(Icons.light_mode_outlined),
                  title: const Text('Quiet hours end'),
                  subtitle:
                      Text(widget.controller.quietHoursEnd.format(context)),
                  onTap: () => _pickQuietHours(start: false),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.importData),
                    subtitle: Text(l10n.importSummary),
                  ),
                  FilledButton(
                    onPressed: _pickAndValidateImport,
                    child: Text(l10n.pickJsonFile),
                  ),
                  if (import != null) ...[
                    const SizedBox(height: 12),
                    Text('${l10n.entries}: ${import.totalEntries}'),
                    Text('${l10n.validEntries}: ${import.validEntries}'),
                    if (import.rows.isNotEmpty)
                      DataTable(
                        columns: [
                          DataColumn(label: Text(l10n.legacyType)),
                          DataColumn(label: Text(l10n.mappedTo)),
                          DataColumn(label: Text(l10n.count)),
                        ],
                        rows: import.rows
                            .take(5)
                            .map(
                              (row) => DataRow(
                                cells: [
                                  DataCell(Text(row.legacyType)),
                                  DataCell(Text(row.mappedType)),
                                  DataCell(Text('${row.count}')),
                                ],
                              ),
                            )
                            .toList(),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
