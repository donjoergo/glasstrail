import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Birthdays are stored/compared as month+day only (no year), so every
// birthday is pinned to this fixed, arbitrary reference year. 2000 is a leap
// year, which matters: it's what makes Feb 29 birthdays representable at all
// without special-casing them separately from every other date.
const int kBirthdayReferenceYear = 2000;

DateTime normalizeBirthday(DateTime value) {
  return DateTime(kBirthdayReferenceYear, value.month, value.day);
}

DateTime? normalizeBirthdayOrNull(DateTime? value) {
  return value == null ? null : normalizeBirthday(value);
}

String formatBirthdayMonthDay(DateTime value, String localeCode) {
  return DateFormat.MMMd(localeCode).format(normalizeBirthday(value));
}

Future<DateTime?> pickMonthDayBirthday(
  BuildContext context, {
  DateTime? initialValue,
}) async {
  final selected = await showDatePicker(
    context: context,
    initialDate:
        normalizeBirthdayOrNull(initialValue) ??
        DateTime(kBirthdayReferenceYear, 1, 1),
    // firstDate/lastDate are clamped to the single reference year so the
    // picker only ever offers month/day choices, never a real year, keeping
    // the UI consistent with the fact that no year is actually stored.
    firstDate: DateTime(kBirthdayReferenceYear, 1, 1),
    lastDate: DateTime(kBirthdayReferenceYear, 12, 31),
  );
  return normalizeBirthdayOrNull(selected);
}
