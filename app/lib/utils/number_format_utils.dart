import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Formats a number compactly based on the current locale
/// Korean: 1000 → 1천, 10000 → 1만
/// English: 1000 → 1K, 1000000 → 1M
String formatCompactNumber(int number, Locale locale) {
  if (locale.languageCode == 'ko') {
    // Korean formatting
    if (number >= 10000) {
      final value = number / 10000;
      return value % 1 == 0
          ? '${value.toInt()}만'
          : '${value.toStringAsFixed(1)}만';
    }
    if (number >= 1000) {
      final value = number / 1000;
      return value % 1 == 0
          ? '${value.toInt()}천'
          : '${value.toStringAsFixed(1)}천';
    }
    return number.toString();
  } else {
    // English formatting (K, M, B)
    final formatter = NumberFormat.compact(locale: locale.toString());
    return formatter.format(number);
  }
}

/// Formats books count with proper pluralization
/// Korean: always "권" suffix
/// English: "book" or "books" based on count
String formatBooksCount(int count, BuildContext context) {
  final locale = Localizations.localeOf(context);

  if (locale.languageCode == 'ko') {
    return '$count권';
  } else {
    return count == 1 ? '$count book' : '$count books';
  }
}
