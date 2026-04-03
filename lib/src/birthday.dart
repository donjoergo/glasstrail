import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'app_language.dart';

const int kBirthdayReferenceYear = 2000;

DateTime normalizeBirthday(DateTime value) {
  return DateTime(kBirthdayReferenceYear, value.month, value.day);
}

DateTime? normalizeBirthdayOrNull(DateTime? value) {
  return value == null ? null : normalizeBirthday(value);
}

String formatBirthdayMonthDay(DateTime value, String localeCode) {
  return DateFormat.MMMd(
    resolveFrameworkLocaleCode(localeCode),
  ).format(normalizeBirthday(value));
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
    firstDate: DateTime(kBirthdayReferenceYear, 1, 1),
    lastDate: DateTime(kBirthdayReferenceYear, 12, 31),
  );
  return normalizeBirthdayOrNull(selected);
}
