import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app_localizations.dart';
import 'app_scope.dart';
import 'photo_service.dart';

Future<String?> pickImageForUpload(
  BuildContext context, {
  required ImageUploadPreset preset,
}) async {
  final source = await _pickPhotoSource(context);
  if (!context.mounted || source == null) {
    return null;
  }
  return AppScope.photoServiceOf(
    context,
  ).pickImage(preset: preset, source: source);
}

Future<PhotoPickSource?> _pickPhotoSource(BuildContext context) {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    return Future<PhotoPickSource?>.value(PhotoPickSource.gallery);
  }

  final l10n = AppLocalizations.of(context);
  final theme = Theme.of(context);
  return showModalBottomSheet<PhotoPickSource>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
              child: Text(
                l10n.pickPhotoSource,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ListTile(
              key: const Key('photo-source-camera-option'),
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.takePhoto),
              onTap: () {
                Navigator.of(sheetContext).pop(PhotoPickSource.camera);
              },
            ),
            ListTile(
              key: const Key('photo-source-gallery-option'),
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.chooseFromGallery),
              onTap: () {
                Navigator.of(sheetContext).pop(PhotoPickSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
