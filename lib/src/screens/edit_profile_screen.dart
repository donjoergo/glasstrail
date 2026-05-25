import 'package:flutter/material.dart';
import 'package:glasstrail/l10n/app_localizations.dart';

import '../app_controller.dart';
import '../app_routes.dart';
import '../app_scope.dart';
import '../app_theme.dart';
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
  bool _authRedirectScheduled = false;

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

  Future<void> _showChangePasswordDialog() async {
    final message = await showDialog<String>(
      context: context,
      builder: (context) => const _ChangePasswordDialog(),
    );
    if (!mounted || message == null) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showDeleteAccountDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) => const _DeleteAccountDialog(),
    );
  }

  Widget _busyIcon(AppBusyAction action, IconData icon) {
    if (!AppScope.controllerOf(context).isBusyFor(action)) {
      return Icon(icon);
    }
    return const SizedBox.square(
      dimension: 18,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.controllerOf(context);
    final user = controller.currentUser;
    if (user == null) {
      if (!_authRedirectScheduled) {
        _authRedirectScheduled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          Navigator.of(
            context,
            rootNavigator: true,
          ).pushNamedAndRemoveUntil(AppRoutes.auth, (_) => false);
        });
      }
      return const Scaffold(body: SizedBox.shrink());
    }
    _authRedirectScheduled = false;

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
                                  user.displayName,
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
                      const SizedBox(height: 28),
                      Divider(
                        color: theme.colorScheme.outlineVariant,
                        height: 1,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        l10n.accountSectionTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.accountSectionBody,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _fullWidthAction(
                        FilledButton.tonalIcon(
                          key: const Key('edit-profile-change-password-button'),
                          onPressed: isBusy ? null : _showChangePasswordDialog,
                          icon: _busyIcon(
                            AppBusyAction.changePassword,
                            Icons.lock_outline_rounded,
                          ),
                          label: Text(l10n.changePassword),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _fullWidthAction(
                        OutlinedButton.icon(
                          key: const Key('edit-profile-delete-account-button'),
                          style: AppTheme.destructiveOutlinedButtonStyle(
                            theme.colorScheme,
                          ),
                          onPressed: isBusy ? null : _showDeleteAccountDialog,
                          icon: _busyIcon(
                            AppBusyAction.deleteAccount,
                            Icons.delete_forever_outlined,
                          ),
                          label: Text(l10n.deleteAccount),
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

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _currentPasswordController;
  late final TextEditingController _newPasswordController;
  late final TextEditingController _repeatNewPasswordController;

  @override
  void initState() {
    super.initState();
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _repeatNewPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _repeatNewPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final controller = AppScope.controllerOf(context);
    final success = await controller.changePassword(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
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

    Navigator.of(context).pop<String>(message ?? l10n.changePasswordSuccess);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.controllerOf(context);
    final isChangingPassword = controller.isBusyFor(
      AppBusyAction.changePassword,
    );
    final isBusy = controller.isBusy;

    return AlertDialog(
      key: const Key('change-password-dialog'),
      scrollable: true,
      title: Text(l10n.changePassword),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(l10n.changePasswordBody),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('change-password-current-field'),
              controller: _currentPasswordController,
              enabled: !isBusy,
              obscureText: true,
              autofillHints: const <String>[AutofillHints.password],
              decoration: InputDecoration(labelText: l10n.currentPassword),
              validator: (value) => value == null || value.trim().isEmpty
                  ? l10n.invalidRequired
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('change-password-new-field'),
              controller: _newPasswordController,
              enabled: !isBusy,
              obscureText: true,
              autofillHints: const <String>[AutofillHints.newPassword],
              decoration: InputDecoration(labelText: l10n.newPassword),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.invalidRequired;
                }
                if (value == _currentPasswordController.text) {
                  return l10n.changePasswordSameAsCurrent;
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('change-password-repeat-field'),
              controller: _repeatNewPasswordController,
              enabled: !isBusy,
              obscureText: true,
              autofillHints: const <String>[AutofillHints.newPassword],
              decoration: InputDecoration(labelText: l10n.repeatNewPassword),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.invalidRequired;
                }
                if (value != _newPasswordController.text) {
                  return l10n.changePasswordConfirmationMismatch;
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: isBusy ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('change-password-submit-button'),
          onPressed: isBusy ? null : _submit,
          child: isChangingPassword
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.changePasswordAction),
        ),
      ],
    );
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  late final TextEditingController _confirmationController;

  @override
  void initState() {
    super.initState();
    _confirmationController = TextEditingController();
  }

  @override
  void dispose() {
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final phrase = l10n.deleteAccountVerificationPhrase;
    if (_confirmationController.text.trim() != phrase) {
      return;
    }

    final controller = AppScope.controllerOf(context);
    final success = await controller.deleteAccount();
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
    final routeMemory = AppScope.routeMemoryOf(context);
    final navigator = Navigator.of(context, rootNavigator: true);
    final messenger = ScaffoldMessenger.of(context);
    await routeMemory.markLoggedOut();
    if (!mounted) {
      return;
    }
    navigator.pushNamedAndRemoveUntil(AppRoutes.auth, (_) => false);
    messenger.showSnackBar(SnackBar(content: Text(l10n.deleteAccountSuccess)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.controllerOf(context);
    final theme = Theme.of(context);
    final isDeletingAccount = controller.isBusyFor(AppBusyAction.deleteAccount);
    final isBusy = controller.isBusy;
    final verificationPhrase = l10n.deleteAccountVerificationPhrase;
    final canDelete = _confirmationController.text.trim() == verificationPhrase;

    return AlertDialog(
      key: const Key('delete-account-dialog'),
      scrollable: true,
      title: Text(l10n.deleteAccountTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(l10n.deleteAccountBody(verificationPhrase)),
          const SizedBox(height: 16),
          TextField(
            key: const Key('delete-account-confirmation-field'),
            controller: _confirmationController,
            enabled: !isBusy,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: l10n.deleteAccountVerificationLabel(
                verificationPhrase,
              ),
              helperText: verificationPhrase,
            ),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: isBusy ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('delete-account-submit-button'),
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          onPressed: isBusy || !canDelete ? null : _submit,
          child: isDeletingAccount
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.deleteAccountAction),
        ),
      ],
    );
  }
}
