import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../config/app_config.dart';

abstract final class Fmt {
  static final _money = NumberFormat.currency(symbol: AppConfig.currencySymbol, decimalDigits: 2);
  static final _moneyCompact = NumberFormat.compactCurrency(symbol: AppConfig.currencySymbol, decimalDigits: 1);
  static final _compact = NumberFormat.compact();
  static final _date = DateFormat('EEE, d MMM yyyy');
  static final _shortDate = DateFormat('d MMM');
  static final _monthDay = DateFormat('MMM d');
  static final _time = DateFormat('h:mm a');

  static String money(num value) => _money.format(value);

  static String moneyCompact(num value) =>
      value < 10000 ? money(value) : _moneyCompact.format(value);

  static String compact(num value) => _compact.format(value);

  static String date(DateTime? value) => value == null ? 'Date TBA' : _date.format(value);

  static String shortDate(DateTime? value) => value == null ? 'TBA' : _shortDate.format(value);

  static String monthDay(DateTime? value) => value == null ? 'TBA' : _monthDay.format(value);

  static String day(DateTime? value) => value == null ? '--' : value.day.toString();

  static String monthShort(DateTime? value) =>
      value == null ? '' : DateFormat('MMM').format(value).toUpperCase();

  /// `14:30:00` → `2:30 PM`
  static String time(String? value) {
    final parsed = parseTime(value);
    if (parsed == null) return value ?? '';
    return _time.format(DateTime(2000, 1, 1, parsed.hour, parsed.minute));
  }

  static TimeOfDay? parseTime(String? value) {
    if (value == null || value.isEmpty) return null;
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  /// `TimeOfDay(14, 5)` → `14:05`
  static String apiTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  static String relative(DateTime? value) {
    if (value == null) return '';
    final diff = DateTime.now().difference(value);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return _shortDate.format(value);
  }

  static String clock(DateTime? value) => value == null ? '' : _time.format(value);

  static String countdown(DateTime? date) {
    if (date == null) return '';
    final today = DateTime.now();
    final days = DateTime(date.year, date.month, date.day)
        .difference(DateTime(today.year, today.month, today.day))
        .inDays;
    if (days == 0) return 'Today';
    if (days == 1) return 'Tomorrow';
    if (days > 1) return 'In $days days';
    if (days == -1) return 'Yesterday';
    return '${-days} days ago';
  }

  static String capitalize(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1).replaceAll('_', ' ');
}
