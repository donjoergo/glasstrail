import 'package:flutter/material.dart';

import '../app_localizations.dart';
import '../app_scope.dart';

enum _AuthMode { signIn, signUp }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _signInKey = GlobalKey<FormState>();
  final _signUpKey = GlobalKey<FormState>();

  final _signInEmailController = TextEditingController();
  final _signInPasswordController = TextEditingController();
  final _signUpEmailController = TextEditingController();
  final _signUpPasswordController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _displayNameController = TextEditingController();

  _AuthMode _mode = _AuthMode.signIn;
  DateTime? _birthday;
  String? _profileImagePath;

  @override
  void dispose() {
    _signInEmailController.dispose();
    _signInPasswordController.dispose();
    _signUpEmailController.dispose();
    _signUpPasswordController.dispose();
    _nicknameController.dispose();
    _displayNameController.dispose();
    super.dispose();
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

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final formState = _mode == _AuthMode.signIn
        ? _signInKey.currentState
        : _signUpKey.currentState;
    if (formState == null || !formState.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.invalidRequired)),
      );
      return;
    }

    final controller = AppScope.controllerOf(context);
    final success = _mode == _AuthMode.signIn
        ? await controller.signIn(
            email: _signInEmailController.text,
            password: _signInPasswordController.text,
          )
        : await controller.signUp(
            email: _signUpEmailController.text,
            password: _signUpPasswordController.text,
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
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.controllerOf(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              theme.colorScheme.primary.withValues(alpha: 0.14),
              theme.colorScheme.tertiary.withValues(alpha: 0.08),
              theme.scaffoldBackgroundColor,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Card(
                  color: theme.colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          l10n.welcomeTitle,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          l10n.welcomeBody,
                          style: theme.textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 20),
                        SegmentedButton<_AuthMode>(
                          segments: <ButtonSegment<_AuthMode>>[
                            ButtonSegment<_AuthMode>(
                              value: _AuthMode.signIn,
                              label: Text(
                                l10n.signIn,
                                key: const Key('auth-mode-sign-in'),
                              ),
                            ),
                            ButtonSegment<_AuthMode>(
                              value: _AuthMode.signUp,
                              label: Text(
                                l10n.signUp,
                                key: const Key('auth-mode-sign-up'),
                              ),
                            ),
                          ],
                          selected: <_AuthMode>{_mode},
                          onSelectionChanged: (selection) {
                            setState(() {
                              _mode = selection.first;
                            });
                          },
                        ),
                        const SizedBox(height: 20),
                        Text(
                          l10n.authHint,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (_mode == _AuthMode.signIn) _buildSignInForm(l10n) else _buildSignUpForm(l10n),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            key: const Key('auth-submit-button'),
                            onPressed: controller.isBusy ? null : _submit,
                            child: controller.isBusy
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Text(_mode == _AuthMode.signIn ? l10n.signIn : l10n.signUp),
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
      ),
    );
  }

  Widget _buildSignInForm(AppLocalizations l10n) {
    return Form(
      key: _signInKey,
      child: Column(
        children: <Widget>[
          TextFormField(
            key: const Key('signin-email-field'),
            controller: _signInEmailController,
            decoration: InputDecoration(labelText: l10n.email),
            keyboardType: TextInputType.emailAddress,
            validator: (value) =>
                value == null || value.trim().isEmpty ? l10n.invalidRequired : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('signin-password-field'),
            controller: _signInPasswordController,
            decoration: InputDecoration(labelText: l10n.password),
            obscureText: true,
            validator: (value) =>
                value == null || value.trim().isEmpty ? l10n.invalidRequired : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpForm(AppLocalizations l10n) {
    return Form(
      key: _signUpKey,
      child: Column(
        children: <Widget>[
          TextFormField(
            key: const Key('signup-email-field'),
            controller: _signUpEmailController,
            decoration: InputDecoration(labelText: l10n.email),
            keyboardType: TextInputType.emailAddress,
            validator: (value) =>
                value == null || value.trim().isEmpty ? l10n.invalidRequired : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('signup-password-field'),
            controller: _signUpPasswordController,
            decoration: InputDecoration(labelText: l10n.password),
            obscureText: true,
            validator: (value) =>
                value == null || value.trim().isEmpty ? l10n.invalidRequired : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('signup-nickname-field'),
            controller: _nicknameController,
            decoration: InputDecoration(labelText: l10n.nickname),
            validator: (value) =>
                value == null || value.trim().isEmpty ? l10n.invalidRequired : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('signup-display-name-field'),
            controller: _displayNameController,
            decoration: InputDecoration(labelText: l10n.displayName),
            validator: (value) =>
                value == null || value.trim().isEmpty ? l10n.invalidRequired : null,
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: _pickBirthday,
                  icon: const Icon(Icons.cake_outlined),
                  label: Text(
                    _birthday == null
                        ? '${l10n.birthday} (${l10n.optional})'
                        : '${_birthday!.year}-${_birthday!.month.toString().padLeft(2, '0')}-${_birthday!.day.toString().padLeft(2, '0')}',
                  ),
                ),
              ),
              if (_birthday != null) ...<Widget>[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _birthday = null;
                    });
                  },
                  icon: const Icon(Icons.close_rounded),
                  tooltip: l10n.removePhoto,
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              FilledButton.tonalIcon(
                onPressed: _pickPhoto,
                icon: const Icon(Icons.account_circle_outlined),
                label: Text(_profileImagePath == null ? l10n.pickPhoto : l10n.changePhoto),
              ),
              if (_profileImagePath != null) ...<Widget>[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _profileImagePath!.split(RegExp(r'[\\/]')).last,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _profileImagePath = null;
                    });
                  },
                  icon: const Icon(Icons.close_rounded),
                  tooltip: l10n.removePhoto,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
