import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:glasstrail/l10n/app_localizations.dart';

import '../app_controller.dart';
import '../app_locale_catalog.dart';
import '../birthday.dart';
import '../app_scope.dart';
import '../photo_pick_flow.dart';
import '../photo_service.dart';
import '../widgets/app_media.dart';

enum _AuthMode { signIn, signUp }

const _brandIconAsset = 'assets/icon/app_icon.png';

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
    _displayNameController.dispose();
    super.dispose();
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

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final formState = _mode == _AuthMode.signIn
        ? _signInKey.currentState
        : _signUpKey.currentState;
    if (formState == null || !formState.validate()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.invalidRequired)));
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
            displayName: _displayNameController.text,
            birthday: _birthday,
            profileImagePath: _profileImagePath,
          );

    if (!mounted) {
      return;
    }
    final message = controller.takeFlashMessage(l10n);
    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
    if (success) {
      final localeMemory = AppScope.localeMemoryOf(context);
      final routeMemory = AppScope.routeMemoryOf(context);
      final arguments = ModalRoute.of(context)?.settings.arguments;
      final redirectRoute = arguments is String ? arguments : null;
      await localeMemory.rememberLocale(controller.settings.localeCode);
      if (!mounted) {
        return;
      }
      FocusScope.of(context).unfocus();
      TextInput.finishAutofillContext();
      final targetRoute = await routeMemory.consumePostAuthRoute(redirectRoute);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacementNamed(targetRoute);
    }
  }

  Future<void> _updateLocale(String localeCode) async {
    final controller = AppScope.controllerOf(context);
    final nextLocale = AppLocaleCatalog.normalizeCode(localeCode);
    if (controller.settings.localeCode == nextLocale) {
      return;
    }
    await controller.updateSettings(
      controller.settings.copyWith(localeCode: nextLocale),
    );
    if (!mounted) {
      return;
    }
    await AppScope.localeMemoryOf(context).rememberLocale(nextLocale);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.controllerOf(context);
    final theme = Theme.of(context);
    final localeCode = AppLocaleCatalog.normalizeCode(
      controller.settings.localeCode,
    );
    final isBusy = controller.isBusy;
    final isSubmitting = controller.isBusyFor(
      _mode == _AuthMode.signIn ? AppBusyAction.signIn : AppBusyAction.signUp,
    );

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _buildBrandHero(theme, l10n),
                    const SizedBox(height: 24),
                    Card(
                      margin: EdgeInsets.zero,
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
                            _buildLanguageSelector(
                              theme: theme,
                              l10n: l10n,
                              localeCode: localeCode,
                              isBusy: isBusy,
                            ),
                            const SizedBox(height: 28),
                            SizedBox(
                              width: double.infinity,
                              child: SegmentedButton<_AuthMode>(
                                key: const Key('auth-mode-segmented'),
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
                                showSelectedIcon: false,
                                expandedInsets: EdgeInsets.zero,
                                onSelectionChanged: isBusy
                                    ? null
                                    : (selection) {
                                        setState(() {
                                          _mode = selection.first;
                                        });
                                      },
                              ),
                            ),
                            const SizedBox(height: 24),
                            if (_mode == _AuthMode.signIn)
                              _buildSignInForm(l10n, isBusy)
                            else
                              _buildSignUpForm(l10n, localeCode, isBusy),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                key: const Key('auth-submit-button'),
                                onPressed: isBusy ? null : _submit,
                                child: isSubmitting
                                    ? const SizedBox.square(
                                        dimension: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        _mode == _AuthMode.signIn
                                            ? l10n.signIn
                                            : l10n.signUp,
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSelector({
    required ThemeData theme,
    required AppLocalizations l10n,
    required String localeCode,
    required bool isBusy,
  }) {
    return Container(
      key: const Key('auth-language-selector'),
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.language_rounded, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Text(
                l10n.language,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            key: const Key('auth-language-dropdown'),
            initialValue: localeCode,
            isExpanded: true,
            menuMaxHeight: 280,
            borderRadius: BorderRadius.circular(20),
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            decoration: InputDecoration(
              filled: true,
              fillColor: theme.colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 14,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.35),
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.18),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 1.4,
                ),
              ),
            ),
            items: AppLocaleCatalog.options
                .map(
                  (option) => DropdownMenuItem<String>(
                    value: option.code,
                    child: Text(
                      option.nativeLabel,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(growable: false),
            onChanged: isBusy
                ? null
                : (value) {
                    if (value == null) {
                      return;
                    }
                    _updateLocale(value);
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildBrandHero(ThemeData theme, AppLocalizations l10n) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 360;
        final iconSize = isCompact ? 112.0 : 132.0;
        final baseTitleStyle = isCompact
            ? theme.textTheme.displayMedium
            : theme.textTheme.displayLarge;
        final titleHeight = !isCompact && kIsWeb ? 96.0 : 78.0;
        final title = Text(
          l10n.appTitle,
          key: const Key('auth-brand-title'),
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.visible,
          style: baseTitleStyle?.copyWith(
            fontSize: !isCompact && kIsWeb
                ? (baseTitleStyle.fontSize ?? 57) + 22
                : null,
            fontWeight: FontWeight.w900,
            letterSpacing: -2.2,
            height: 0.94,
          ),
        );

        return Padding(
          key: const Key('auth-brand-hero'),
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 8 : 12,
            vertical: isCompact ? 8 : 12,
          ),
          child: Flex(
            direction: isCompact ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Material(
                key: const Key('auth-brand-icon'),
                elevation: 20,
                shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(30),
                clipBehavior: Clip.antiAlias,
                child: SizedBox.square(
                  dimension: iconSize,
                  child: Image.asset(_brandIconAsset, fit: BoxFit.cover),
                ),
              ),
              SizedBox(width: isCompact ? 0 : 24, height: isCompact ? 20 : 0),
              if (isCompact)
                SizedBox(
                  width: constraints.maxWidth,
                  height: 56,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: title,
                  ),
                )
              else
                Expanded(
                  child: SizedBox(
                    height: titleHeight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: title,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSignInForm(AppLocalizations l10n, bool isBusy) {
    return AutofillGroup(
      child: Form(
        key: _signInKey,
        child: Column(
          children: <Widget>[
            TextFormField(
              key: const Key('signin-email-field'),
              controller: _signInEmailController,
              enabled: !isBusy,
              decoration: InputDecoration(labelText: l10n.email),
              keyboardType: TextInputType.emailAddress,
              autofillHints: const <String>[AutofillHints.email],
              autocorrect: false,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
              validator: (value) => value == null || value.trim().isEmpty
                  ? l10n.invalidRequired
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('signin-password-field'),
              controller: _signInPasswordController,
              enabled: !isBusy,
              decoration: InputDecoration(labelText: l10n.password),
              obscureText: true,
              autofillHints: const <String>[AutofillHints.password],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) {
                if (isBusy) {
                  return;
                }
                _submit();
              },
              validator: (value) => value == null || value.trim().isEmpty
                  ? l10n.invalidRequired
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignUpForm(
    AppLocalizations l10n,
    String localeCode,
    bool isBusy,
  ) {
    return AutofillGroup(
      child: Form(
        key: _signUpKey,
        child: Column(
          children: <Widget>[
            TextFormField(
              key: const Key('signup-email-field'),
              controller: _signUpEmailController,
              enabled: !isBusy,
              decoration: InputDecoration(labelText: l10n.email),
              keyboardType: TextInputType.emailAddress,
              autofillHints: const <String>[AutofillHints.email],
              autocorrect: false,
              validator: (value) => value == null || value.trim().isEmpty
                  ? l10n.invalidRequired
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('signup-password-field'),
              controller: _signUpPasswordController,
              enabled: !isBusy,
              decoration: InputDecoration(labelText: l10n.password),
              obscureText: true,
              autofillHints: const <String>[AutofillHints.newPassword],
              validator: (value) => value == null || value.trim().isEmpty
                  ? l10n.invalidRequired
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('signup-display-name-field'),
              controller: _displayNameController,
              enabled: !isBusy,
              decoration: InputDecoration(labelText: l10n.displayName),
              autofillHints: const <String>[AutofillHints.name],
              validator: (value) => value == null || value.trim().isEmpty
                  ? l10n.invalidRequired
                  : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: isBusy ? null : _pickBirthday,
                    icon: const Icon(Icons.cake_outlined),
                    label: Text(
                      _birthday == null
                          ? '${l10n.birthday} (${l10n.optional})'
                          : formatBirthdayMonthDay(_birthday!, localeCode),
                    ),
                  ),
                ),
                if (_birthday != null) ...<Widget>[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: isBusy
                        ? null
                        : () {
                            setState(() {
                              _birthday = null;
                            });
                          },
                    icon: const Icon(Icons.close_rounded),
                    tooltip: l10n.removeBirthday,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            if (_profileImagePath != null) ...<Widget>[
              const SizedBox(height: 4),
              Center(
                child: AppAvatar(
                  key: const Key('auth-profile-image-preview'),
                  imagePath: _profileImagePath,
                  radius: 42,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.14),
                  fallback: Icon(
                    Icons.account_circle_outlined,
                    size: 42,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                FilledButton.tonalIcon(
                  onPressed: isBusy ? null : _pickPhoto,
                  icon: const Icon(Icons.account_circle_outlined),
                  label: Text(
                    _profileImagePath == null
                        ? l10n.pickPhoto
                        : l10n.changePhoto,
                  ),
                ),
                if (_profileImagePath != null)
                  OutlinedButton.icon(
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}
