import 'package:flutter_test/flutter_test.dart';
import 'package:glasstrail/src/achievements/evaluator.dart';
import 'package:glasstrail/src/achievements/occasion_rules.dart';
import 'package:glasstrail/src/models.dart';

AchievementEntry _entry(DateTime date, {DrinkCategory category = DrinkCategory.wine}) {
  return AchievementEntry(category: category, isAlcoholFree: false, achievementLocalDate: date);
}

void main() {
  group('occasion rules', () {
    test('Good Friday through Easter Monday works for multiple years', () {
      // 2026: Easter Sunday is April 5.
      expect(easterSunday(2026), DateTime(2026, 4, 5));
      expect(goodFriday(2026), DateTime(2026, 4, 3));
      expect(easterMonday(2026), DateTime(2026, 4, 6));

      // 2027: Easter Sunday is March 28.
      expect(easterSunday(2027), DateTime(2027, 3, 28));
      expect(goodFriday(2027), DateTime(2027, 3, 26));
      expect(easterMonday(2027), DateTime(2027, 3, 29));

      for (final int year in <int>[2026, 2027]) {
        expect(
          occasionMatches(
            familyId: AchievementFamilyIds.occasionEaster,
            localDate: goodFriday(year),
            isBeer: false,
          ),
          isTrue,
        );
        expect(
          occasionMatches(
            familyId: AchievementFamilyIds.occasionEaster,
            localDate: easterMonday(year),
            isBeer: false,
          ),
          isTrue,
        );
        expect(
          occasionMatches(
            familyId: AchievementFamilyIds.occasionEaster,
            localDate: easterMonday(year).add(const Duration(days: 1)),
            isBeer: false,
          ),
          isFalse,
        );
      }
    });

    test('Carnival runs from Fat Thursday through Mardi Gras', () {
      // 2026: Easter is April 5 -> Ash Wednesday Feb 18 -> Mardi Gras Feb 17
      // -> Fat Thursday Feb 12.
      expect(mardiGras(2026), DateTime(2026, 2, 17));
      expect(fatThursday(2026), DateTime(2026, 2, 12));

      expect(
        occasionMatches(familyId: AchievementFamilyIds.occasionCarnival, localDate: DateTime(2026, 2, 12), isBeer: false),
        isTrue,
      );
      expect(
        occasionMatches(familyId: AchievementFamilyIds.occasionCarnival, localDate: DateTime(2026, 2, 17), isBeer: false),
        isTrue,
      );
      expect(
        occasionMatches(familyId: AchievementFamilyIds.occasionCarnival, localDate: DateTime(2026, 2, 11), isBeer: false),
        isFalse,
      );
      expect(
        occasionMatches(familyId: AchievementFamilyIds.occasionCarnival, localDate: DateTime(2026, 2, 18), isBeer: false),
        isFalse,
      );
    });

    test('Oktoberfest uses the hardcoded 2026-2030 date table from spec.md', () {
      expect(
        occasionMatches(
          familyId: AchievementFamilyIds.occasionOktoberfest,
          localDate: DateTime(2026, 9, 19),
          isBeer: true,
        ),
        isTrue,
      );
      expect(
        occasionMatches(
          familyId: AchievementFamilyIds.occasionOktoberfest,
          localDate: DateTime(2026, 10, 4),
          isBeer: true,
        ),
        isTrue,
      );
      expect(
        occasionMatches(
          familyId: AchievementFamilyIds.occasionOktoberfest,
          localDate: DateTime(2026, 9, 18),
          isBeer: true,
        ),
        isFalse,
      );
      // Outside the locked table: no window defined.
      expect(oktoberfestWindow(2031), isNull);
      expect(
        occasionMatches(
          familyId: AchievementFamilyIds.occasionOktoberfest,
          localDate: DateTime(2031, 9, 20),
          isBeer: true,
        ),
        isFalse,
      );
    });

    test('Feb 29 falls back to Feb 28 in non-leap years', () {
      final DateTime birthday = DateTime(2000, 2, 29); // leap reference year
      expect(
        occasionMatches(
          familyId: AchievementFamilyIds.occasionBirthday,
          localDate: DateTime(2027, 2, 28), // 2027 is not a leap year
          isBeer: false,
          birthdayMonthDay: birthday,
        ),
        isTrue,
      );
      expect(
        occasionMatches(
          familyId: AchievementFamilyIds.occasionBirthday,
          localDate: DateTime(2028, 2, 29), // 2028 is a leap year
          isBeer: false,
          birthdayMonthDay: birthday,
        ),
        isTrue,
      );
      expect(
        occasionMatches(
          familyId: AchievementFamilyIds.occasionBirthday,
          localDate: DateTime(2028, 2, 28),
          isBeer: false,
          birthdayMonthDay: birthday,
        ),
        isFalse,
      );
    });

    test("St. Patrick's Day and Oktoberfest require beer", () {
      expect(
        occasionMatches(
          familyId: AchievementFamilyIds.occasionStPatricksDay,
          localDate: DateTime(2026, 3, 17),
          isBeer: false,
        ),
        isFalse,
      );
      expect(
        occasionMatches(
          familyId: AchievementFamilyIds.occasionStPatricksDay,
          localDate: DateTime(2026, 3, 17),
          isBeer: true,
        ),
        isTrue,
      );
      expect(
        occasionMatches(
          familyId: AchievementFamilyIds.occasionOktoberfest,
          localDate: DateTime(2026, 9, 20),
          isBeer: false,
        ),
        isFalse,
      );
    });

    test('other occasion badges accept any drink', () {
      for (final String familyId in <String>[
        AchievementFamilyIds.occasionNewYear,
        AchievementFamilyIds.occasionChristmas,
        AchievementFamilyIds.occasionEaster,
        AchievementFamilyIds.occasionHalloween,
        AchievementFamilyIds.occasionCarnival,
      ]) {
        final DateTime probe = switch (familyId) {
          AchievementFamilyIds.occasionNewYear => DateTime(2026, 12, 31),
          AchievementFamilyIds.occasionChristmas => DateTime(2026, 12, 25),
          AchievementFamilyIds.occasionEaster => easterSunday(2026),
          AchievementFamilyIds.occasionHalloween => DateTime(2026, 10, 31),
          AchievementFamilyIds.occasionCarnival => mardiGras(2026),
          _ => throw StateError('unreachable'),
        };
        expect(
          occasionMatches(familyId: familyId, localDate: probe, isBeer: false),
          isTrue,
          reason: familyId,
        );
      }
    });

    test('New Year matches Dec 31 and Jan 1 regardless of year pairing', () {
      expect(
        occasionMatches(familyId: AchievementFamilyIds.occasionNewYear, localDate: DateTime(2026, 12, 31), isBeer: false),
        isTrue,
      );
      expect(
        occasionMatches(familyId: AchievementFamilyIds.occasionNewYear, localDate: DateTime(2027, 1, 1), isBeer: false),
        isTrue,
      );
      expect(
        occasionMatches(familyId: AchievementFamilyIds.occasionNewYear, localDate: DateTime(2027, 1, 2), isBeer: false),
        isFalse,
      );
    });

    test('occasion year dedupe key uses the window\'s first-day year', () {
      expect(
        occasionYearForDate(familyId: AchievementFamilyIds.occasionNewYear, localDate: DateTime(2026, 12, 31)),
        2026,
      );
      expect(
        occasionYearForDate(familyId: AchievementFamilyIds.occasionNewYear, localDate: DateTime(2027, 1, 1)),
        2026,
      );
    });

    test('BeerWithMe-style imported historical dates evaluate from stored local dates', () {
      // The evaluator only ever reads AchievementEntry.achievementLocalDate;
      // it never derives dates from timestamps/timezones itself. Feeding a
      // pre-computed "imported" local date is sufficient proof.
      final AchievementEntry imported = _entry(DateTime(2019, 12, 25));
      final AchievementEvaluationContext ctx =
          AchievementEvaluationContext(entries: <AchievementEntry>[imported], now: DateTime(2026, 1, 1));
      final AchievementFamily christmas = achievementFamilyById(AchievementFamilyIds.occasionChristmas)!;
      expect(evaluateFamily(christmas, ctx).liveValue, 1);
    });

    test('one-time lifetime badges continue to be evaluable across many years', () {
      final AchievementEvaluationContext ctx = AchievementEvaluationContext(
        entries: <AchievementEntry>[_entry(DateTime(2026, 10, 31))],
        now: DateTime(2030, 1, 1),
      );
      final AchievementFamily halloween = achievementFamilyById(AchievementFamilyIds.occasionHalloween)!;
      expect(evaluateFamily(halloween, ctx).liveValue, 1);
    });

    test('firstSipAnniversaryAnchor recomputes from the earliest entry after import and deletion', () {
      // Anchor starts at the only entry's date.
      final DateTime original = DateTime(2022, 5, 1);
      final List<AchievementEntry> afterFirstLog = <AchievementEntry>[_entry(original)];
      expect(firstSipAnniversaryAnchor(afterFirstLog), original);

      // Importing older history moves the anchor earlier, regardless of
      // list order.
      final DateTime imported = DateTime(2018, 3, 10);
      final List<AchievementEntry> afterImport = <AchievementEntry>[
        _entry(original),
        _entry(imported),
      ];
      expect(firstSipAnniversaryAnchor(afterImport), imported);

      // Deleting the earliest (imported) entry re-anchors to the next
      // earliest remaining entry, not the original first-ever anchor.
      final List<AchievementEntry> afterDeletingImport = <AchievementEntry>[_entry(original)];
      expect(firstSipAnniversaryAnchor(afterDeletingImport), original);

      // Deleting every entry leaves no anchor at all.
      expect(firstSipAnniversaryAnchor(const <AchievementEntry>[]), isNull);
    });

    test('isEarnableToday for the anniversary badge tracks the re-anchored date after deletion', () {
      // With the imported Mar 10 entry present, the anchor is Mar 10, so
      // "today" being Mar 10 makes the (already-earned-by-definition, but
      // still occasion-window-matching) badge earnable.
      final AchievementFamily anniversary =
          achievementFamilyById(AchievementFamilyIds.occasionFirstSipAnniversary)!;
      final AchievementEvaluationContext beforeDeletion = AchievementEvaluationContext(
        entries: <AchievementEntry>[
          _entry(DateTime(2022, 5, 1)),
          _entry(DateTime(2018, 3, 10)),
        ],
        now: DateTime(2026, 3, 10),
      );
      expect(
        isEarnableToday(family: anniversary, ctx: beforeDeletion, alreadyEarned: false),
        isTrue,
      );

      // After deleting the imported entry, the anchor moves to May 1, so
      // the same March 10 "now" no longer matches the (re-anchored)
      // occasion window.
      final AchievementEvaluationContext afterDeletion = AchievementEvaluationContext(
        entries: <AchievementEntry>[_entry(DateTime(2022, 5, 1))],
        now: DateTime(2026, 3, 10),
      );
      expect(
        isEarnableToday(family: anniversary, ctx: afterDeletion, alreadyEarned: false),
        isFalse,
      );
    });
  });
}
