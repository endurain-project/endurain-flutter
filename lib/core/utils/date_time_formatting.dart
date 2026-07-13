import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

String formatLocalDateTime(
  BuildContext context,
  DateTime value, {
  bool includeSeconds = false,
}) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  final formatter = includeSeconds
      ? DateFormat.yMd(locale).add_jms()
      : DateFormat.yMd(locale).add_jm();
  return formatter.format(value.toLocal());
}
