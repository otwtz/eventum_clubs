import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Форматирует [priceCents] как сумму в рублях с символом ₽.
String formatRubFromKopecks(BuildContext context, int priceCents) {
  if (priceCents <= 0) return '';
  final locale = Localizations.localeOf(context).toString();
  final amount = priceCents / 100.0;
  final decimals = (priceCents % 100 == 0) ? 0 : 2;
  return NumberFormat.currency(
    locale: locale,
    symbol: '₽',
    decimalDigits: decimals,
  ).format(amount);
}
