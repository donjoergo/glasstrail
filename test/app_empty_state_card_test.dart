import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glasstrail/src/widgets/app_empty_state_card.dart';

void main() {
  testWidgets('renders a more compact empty state card when requested', (
    tester,
  ) async {
    Future<Size> pumpCard({required bool compact}) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: AppEmptyStateCard(
                  icon: Icons.notifications_none_rounded,
                  title: 'No notifications right now',
                  body:
                      'When friends log drinks or send you friend requests, you\'ll see them here. Read notifications are deleted after 30 days, unread notifications after 90 days.',
                  compact: compact,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final rootContainer = find
          .descendant(
            of: find.byType(AppEmptyStateCard),
            matching: find.byType(Container),
          )
          .first;
      return tester.getSize(rootContainer);
    }

    final regularSize = await pumpCard(compact: false);
    final compactSize = await pumpCard(compact: true);

    expect(compactSize.height, lessThan(regularSize.height));
  });
}
