import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:glasstrail/l10n/l10n.dart';
import 'package:glasstrail/state/app_controller.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({required this.controller, super.key});

  final AppController controller;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  final _accountFormKey = GlobalKey<FormState>();
  final _profileFormKey = GlobalKey<FormState>();

  int _page = 0;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _displayNameController = TextEditingController();
  String? _avatarPath;

  @override
  void dispose() {
    _pageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nicknameController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_page == 0 && !_accountFormKey.currentState!.validate()) {
      return;
    }

    if (_page == 1 && !_profileFormKey.currentState!.validate()) {
      return;
    }

    if (_page < 2) {
      setState(() {
        _page += 1;
      });
      await _pageController.animateToPage(
        _page,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
      return;
    }

    widget.controller.completeOnboarding(
      nickname: _nicknameController.text.trim(),
      displayName: _displayNameController.text.trim(),
      avatarUrl: _avatarPath,
    );

    if (!mounted) {
      return;
    }
    context.go('/feed');
  }

  Future<void> _back() async {
    if (_page == 0) {
      return;
    }
    setState(() {
      _page -= 1;
    });
    await _pageController.animateToPage(
      _page,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _pickAvatar() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null) {
      return;
    }

    final file = result.files.single;
    setState(() {
      _avatarPath = file.path;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.onboardingTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: LinearProgressIndicator(value: (_page + 1) / 3),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _AccountStep(
                  formKey: _accountFormKey,
                  emailController: _emailController,
                  passwordController: _passwordController,
                ),
                _ProfileStep(
                  formKey: _profileFormKey,
                  nicknameController: _nicknameController,
                  displayNameController: _displayNameController,
                  avatarPath: _avatarPath,
                  onPickAvatar: _pickAvatar,
                ),
                _ReadyStep(controller: widget.controller),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Row(
              children: [
                if (_page > 0)
                  TextButton(
                    onPressed: _back,
                    child: Text(l10n.back),
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: _next,
                  child: Text(_page == 2 ? l10n.finish : l10n.next),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountStep extends StatelessWidget {
  const _AccountStep({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.onboardingAccount,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: emailController,
              decoration: InputDecoration(labelText: l10n.email),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || !value.contains('@')) {
                  return l10n.email;
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: passwordController,
              decoration: InputDecoration(labelText: l10n.password),
              obscureText: true,
              validator: (value) {
                if (value == null || value.length < 6) {
                  return l10n.password;
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileStep extends StatelessWidget {
  const _ProfileStep({
    required this.formKey,
    required this.nicknameController,
    required this.displayNameController,
    required this.avatarPath,
    required this.onPickAvatar,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nicknameController;
  final TextEditingController displayNameController;
  final String? avatarPath;
  final VoidCallback onPickAvatar;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.onboardingProfile,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundImage:
                      avatarPath == null ? null : FileImage(File(avatarPath!)),
                  child: avatarPath == null ? const Icon(Icons.person) : null,
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: onPickAvatar,
                  child: Text('${l10n.pickPhoto} (${l10n.optional})'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: nicknameController,
              decoration: InputDecoration(labelText: l10n.nickname),
              validator: (value) {
                if (value == null || value.trim().length < 2) {
                  return l10n.nickname;
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: displayNameController,
              decoration: InputDecoration(labelText: l10n.displayName),
              validator: (value) {
                if (value == null || value.trim().length < 2) {
                  return l10n.displayName;
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadyStep extends StatelessWidget {
  const _ReadyStep({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.onboardingDone,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text('• ${l10n.navFeed}'),
          Text('• ${l10n.navMap}'),
          Text('• ${l10n.navAdd}'),
          Text('• ${l10n.navStats}'),
          Text('• ${l10n.navProfile}'),
          const SizedBox(height: 12),
          const Text('Invite onboarding is ready under /onboarding route.'),
        ],
      ),
    );
  }
}
