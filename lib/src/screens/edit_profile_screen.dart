import 'package:flutter/material.dart';
import 'package:glasstrail/l10n/app_localizations.dart';

import '../app_theme.dart';
import '../app_controller.dart';
import '../app_scope.dart';
import '../birthday.dart';
import '../models.dart';
import '../photo_pick_flow.dart';
import '../photo_service.dart';
import '../widgets/app_media.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _displayNameController;
  DateTime? _birthday;
  String? _profileImagePath;
  String? _hydratedUserId;

  Widget _fullWidthAction(Widget child) {
    return SizedBox(width: double.infinity, child: child);
  }

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  void _hydrate(AppUser user) {
    if (_hydratedUserId == user.id) {
      return;
    }
    _hydratedUserId = user.id;
    _displayNameController.text = user.displayName;
    _birthday = user.birthday;
    _profileImagePath = user.profileImagePath;
  }

  Future<void> _pickBirthday() async {
    final selected = await pickMonthDayBirthday(
      context,
      initialValue: _birthday,
    );
    if (!mounted || selected == null) {
      return;
    }
    setState(() {
      _birthday = selected;
    });
  }

  Future<void> _pickPhoto() async {
    final path = await pickImageForUpload(
      context,
      preset: ImageUploadPreset.profile,
    );
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.invalidRequired)));
      return;
    }

    final controller = AppScope.controllerOf(context);
    final success = await controller.updateProfile(
      displayName: _displayNameController.text,
      birthday: _birthday,
      profileImagePath: _profileImagePath,
      clearBirthday: _birthday == null,
      clearProfileImage: _profileImagePath == null,
    );
    if (!mounted) {
      return;
    }

    final message = controller.takeFlashMessage(l10n);
    if (!success) {
      if (message != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
      return;
    }

    Navigator.of(context).pop<String>(message ?? l10n.editProfile);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.controllerOf(context);
    final user = controller.currentUser!;
    final theme = Theme.of(context);
    final isBusy = controller.isBusy;
    final isSavingProfile = controller.isBusyFor(AppBusyAction.updateProfile);
    _hydrate(user);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.editProfile)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Container(
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
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          AppAvatar(
                            key: const Key('edit-profile-image-preview'),
                            imagePath: _profileImagePath,
                            radius: 72,
                            backgroundColor: theme.colorScheme.primary
                                .withValues(alpha: 0.14),
                            fallback: Text(
                              user.initials,
                              style: theme.textTheme.headlineLarge?.copyWith(
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
                                  user.email,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  l10n.editProfile,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: <Widget>[
                                    _fullWidthAction(
                                      FilledButton.tonalIcon(
                                        key: const Key(
                                          'edit-profile-change-photo-button',
                                        ),
                                        onPressed: isBusy ? null : _pickPhoto,
                                        icon: const Icon(
                                          Icons.photo_camera_back_outlined,
                                        ),
                                        label: Text(
                                          _profileImagePath == null
                                              ? l10n.pickPhoto
                                              : l10n.changePhoto,
                                        ),
                                      ),
                                    ),
                                    if (_profileImagePath != null) ...<Widget>[
                                      const SizedBox(height: 10),
                                      _fullWidthAction(
                                        OutlinedButton.icon(
                                          key: const Key(
                                            'edit-profile-remove-photo-button',
                                          ),
                                          style:
                                              AppTheme.destructiveOutlinedButtonStyle(
                                                theme.colorScheme,
                                              ),
                                          onPressed: isBusy
                                              ? null
                                              : () {
                                                  setState(() {
                                                    _profileImagePath = null;
                                                  });
                                                },
                                          icon: const Icon(Icons.close_rounded),
                                          label: Text(l10n.removePhoto),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        key: const Key('edit-profile-display-name-field'),
                        controller: _displayNameController,
                        enabled: !isBusy,
                        decoration: InputDecoration(
                          labelText: l10n.displayName,
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? l10n.invalidRequired
                            : null,
                      ),
                      const SizedBox(height: 12),
                      if (_birthday == null)
                        _fullWidthAction(
                          FilledButton.tonalIcon(
                            key: const Key('edit-profile-birthday-button'),
                            onPressed: isBusy ? null : _pickBirthday,
                            icon: const Icon(Icons.cake_outlined),
                            label: Text('${l10n.birthday} (${l10n.optional})'),
                          ),
                        )
                      else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            FilledButton.tonalIcon(
                              key: const Key('edit-profile-birthday-button'),
                              style: FilledButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                minimumSize: const Size(0, 40),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: isBusy ? null : _pickBirthday,
                              icon: const Icon(Icons.cake_outlined),
                              label: Text(
                                formatBirthdayMonthDay(
                                  _birthday!,
                                  controller.settings.localeCode,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                key: const Key(
                                  'edit-profile-remove-birthday-button',
                                ),
                                style:
                                    AppTheme.destructiveOutlinedButtonStyle(
                                      theme.colorScheme,
                                    ).copyWith(
                                      visualDensity: VisualDensity.compact,
                                      minimumSize: const WidgetStatePropertyAll(
                                        Size(0, 40),
                                      ),
                                      padding: const WidgetStatePropertyAll(
                                        EdgeInsets.symmetric(horizontal: 12),
                                      ),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                onPressed: isBusy
                                    ? null
                                    : () {
                                        setState(() {
                                          _birthday = null;
                                        });
                                      },
                                icon: const Icon(Icons.close_rounded),
                                label: Text(l10n.removeBirthday),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          key: const Key('edit-profile-save-button'),
                          onPressed: isBusy ? null : _saveProfile,
                          child: isSavingProfile
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(l10n.save),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
