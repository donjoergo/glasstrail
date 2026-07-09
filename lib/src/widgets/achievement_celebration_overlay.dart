import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glasstrail/l10n/app_localizations.dart';

import '../achievements/achievement_localizations.dart';
import '../achievements/catalog.dart';
import '../app_controller.dart';
import '../app_scope.dart';

/// Wraps [child] with the unlock celebration queue.
///
/// Real-time drink-log unlocks (`AchievementUnlockSource.realtimeLog`) show
/// up to 3 animated cards plus an overflow summary. Every other source
/// (import, backfill, history edit, settings change) shows a single
/// compact summary instead, per spec.md "Celebration, Haptics, and Sound".
class AchievementCelebrationOverlay extends StatefulWidget {
  const AchievementCelebrationOverlay({super.key, required this.child});

  final Widget child;

  @override
  State<AchievementCelebrationOverlay> createState() =>
      _AchievementCelebrationOverlayState();
}

class _AchievementCelebrationOverlayState
    extends State<AchievementCelebrationOverlay> {
  static const int _maxAnimatedCards = 3;
  static const Duration _visibleDuration = Duration(seconds: 4);

  List<AchievementUnlock> _queue = const <AchievementUnlock>[];
  bool _isCompactSummary = false;
  bool _isVisible = false;
  AppController? _controller;
  Timer? _dismissTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = AppScope.controllerOf(context);
    if (!identical(_controller, controller)) {
      _controller?.removeListener(_onControllerChanged);
      _controller = controller;
      _controller!.addListener(_onControllerChanged);
      _onControllerChanged();
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller?.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (_isVisible) return;
    final pending = _controller!.pendingCelebrationUnlocks;
    if (pending.isEmpty) return;

    final realtime = pending
        .where((u) => u.source == AchievementUnlockSource.realtimeLog)
        .toList(growable: false);
    final batch = realtime.isNotEmpty ? realtime : pending;

    setState(() {
      _queue = batch;
      _isCompactSummary = realtime.isEmpty;
      _isVisible = true;
    });

    _presentHapticsAndSound();
    _dismissTimer?.cancel();
    _dismissTimer = Timer(_visibleDuration, _dismiss);
  }

  Future<void> _presentHapticsAndSound() async {
    // One haptic + one sound per whole unlock sequence, not per card.
    unawaited(HapticFeedback.mediumImpact());
    if (defaultTargetPlatform == TargetPlatform.android || kIsWeb) {
      try {
        await SystemSound.play(SystemSoundType.click);
      } catch (_) {
        // Fail silently, matching the locked web/media-blocked behavior.
      }
    }
  }

  void _dismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    if (!mounted || !_isVisible) return;
    final refs = _queue.map((u) => u.ref).toList(growable: false);
    setState(() {
      _isVisible = false;
      _queue = const <AchievementUnlock>[];
    });
    final controller = _controller;
    if (controller != null) {
      unawaited(controller.markAchievementUnlocksSurfaced(refs));
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final reducedMotion =
        mediaQuery.disableAnimations || mediaQuery.accessibleNavigation;

    return Stack(
      children: <Widget>[
        widget.child,
        if (_isVisible)
          Positioned(
            left: 16,
            right: 16,
            bottom: 96,
            child: _isCompactSummary
                ? _CompactSummaryCard(count: _queue.length, onDismiss: _dismiss)
                : _AnimatedUnlockQueue(
                    unlocks: _queue,
                    maxCards: _maxAnimatedCards,
                    reducedMotion: reducedMotion,
                    onDismiss: _dismiss,
                  ),
          ),
      ],
    );
  }
}

class _CompactSummaryCard extends StatelessWidget {
  const _CompactSummaryCard({required this.count, required this.onDismiss});

  final int count;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      child: InkWell(
        onTap: onDismiss,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              Icon(
                Icons.emoji_events_rounded,
                color: theme.colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l10n.achievementsSummaryBackfillTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(l10n.achievementsSummaryBackfillBody(count)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedUnlockQueue extends StatelessWidget {
  const _AnimatedUnlockQueue({
    required this.unlocks,
    required this.maxCards,
    required this.reducedMotion,
    required this.onDismiss,
  });

  final List<AchievementUnlock> unlocks;
  final int maxCards;
  final bool reducedMotion;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shown = unlocks.take(maxCards).toList(growable: false);
    final overflowCount = unlocks.length - shown.length;

    return GestureDetector(
      onTap: onDismiss,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final unlock in shown)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _UnlockCard(unlock: unlock, reducedMotion: reducedMotion),
            ),
          if (overflowCount > 0)
            Material(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Text(l10n.achievementsOverflowUnlocked(overflowCount)),
              ),
            ),
        ],
      ),
    );
  }
}

class _UnlockCard extends StatelessWidget {
  const _UnlockCard({required this.unlock, required this.reducedMotion});

  final AchievementUnlock unlock;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final family = achievementFamilyById(unlock.familyId);
    final level = family?.levels
        .where((l) => l.level == unlock.level)
        .cast<AchievementLevelDef?>()
        .firstWhere((_) => true, orElse: () => null);

    final card = Material(
      color: theme.colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: <Widget>[
            Icon(
              Icons.emoji_events_rounded,
              color: theme.colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                level == null
                    ? ''
                    : resolveAchievementString(l10n, level.titleKey),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (reducedMotion) {
      return card;
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0, 1),
          child: Transform.scale(
            scale: 0.85 + (0.15 * value.clamp(0, 1)),
            child: child,
          ),
        );
      },
      child: card,
    );
  }
}
