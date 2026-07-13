import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glasstrail/l10n/app_localizations.dart';
import 'package:glasstrail/src/app_scope.dart';
import 'package:glasstrail/src/locale_memory.dart';
import 'package:glasstrail/src/models.dart';
import 'package:glasstrail/src/route_memory.dart';
import 'package:glasstrail/src/stats_calculator.dart';
import 'package:glasstrail/src/widgets/statistics_overview_content.dart';

import 'support/test_harness.dart';

void main() {
  // Non-zero counts for a couple of categories so the pie chart's section
  // titles differ and can be matched back to a category for order checks.
  const stats = AppStatistics(
    weeklyTotal: 0,
    monthlyTotal: 0,
    yearlyTotal: 0,
    currentStreak: 0,
    bestStreak: 0,
    bestStreakStart: null,
    bestStreakEnd: null,
    hasEntryToday: false,
    streakThroughYesterday: 0,
    streakMessageState: StreakMessageState.start,
    weekProgress: <WeekProgressDay>[],
    categoryCounts: <DrinkCategory, int>{
      DrinkCategory.beer: 3,
      DrinkCategory.wine: 2,
      DrinkCategory.cocktails: 1,
    },
    totalEntries: 6,
    beerTotalCount: 3,
    regularBeerCount: 3,
    alcoholFreeBeerCount: 0,
  );

  testWidgets(
    'legend chips list categories in the stored custom order, not enum '
    'order',
    (tester) async {
      final controller = await buildTestController();
      // Reversed enum order so the legend order can be distinguished from
      // DrinkCategory.values order.
      final reversed = DrinkCategory.values.reversed.toList(growable: false);
      await controller.reorderGlobalCategories(reversed);

      await tester.pumpWidget(
        AppScope(
          controller: controller,
          photoService: const TestPhotoService(),
          importFileService: const TestImportFileService(),
          locationService: const TestLocationService(),
          routeMemory: RouteMemory.disabled(),
          localeMemory: LocaleMemory.disabled(),
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: SingleChildScrollView(
                child: StatisticsOverviewContent(
                  stats: stats,
                  localeCode: 'en',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final chips = tester
          .widgetList<StatisticsLegendChip>(find.byType(StatisticsLegendChip))
          .toList(growable: false);
      final chipCategoryOrder = chips
          .map((chip) => (chip.iconKey as ValueKey<String>).value)
          .toList(growable: false);
      final expectedOrder = reversed
          .map((category) => 'stats-category-chip-icon-${category.name}')
          .toList(growable: false);

      expect(chipCategoryOrder, expectedOrder);

      // The pie chart's sections must iterate in the same custom order, not
      // filtered but with matching stable order (comment above
      // _buildSections says all categories are always passed as sections).
      final pieChart = tester.widget<PieChart>(find.byType(PieChart));
      expect(pieChart.data.sections, hasLength(reversed.length));
      final nonEmptyTitles = pieChart.data.sections
          .map((section) => section.title)
          .where((title) => title.isNotEmpty)
          .toList(growable: false);
      // Only beer/wine/cocktails have non-zero counts (see stats above), so
      // their titles are non-empty; reversed enum order puts cocktails
      // before wine before beer.
      expect(nonEmptyTitles.length, 3);
      expect(nonEmptyTitles[0], startsWith('Cocktails'));
      expect(nonEmptyTitles[1], startsWith('Wine'));
      expect(nonEmptyTitles[2], startsWith('Beer'));
    },
  );
}
