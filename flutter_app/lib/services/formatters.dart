import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'es_CL',
    symbol: '\$',
    decimalDigits: 0,
  );

  static final NumberFormat _compact = NumberFormat.compactCurrency(
    locale: 'es_CL',
    symbol: '\$',
    decimalDigits: 0,
  );

  static final DateFormat _date = DateFormat('d MMM yyyy', 'es_CL');
  static final DateFormat _dateShort = DateFormat('d MMM', 'es_CL');
  static final DateFormat _monthYear = DateFormat('MMMM yyyy', 'es_CL');

  static String currency(int amount) => _currency.format(amount);

  static String currencyCompact(int amount) => _compact.format(amount);

  static String date(DateTime date) => _date.format(date);

  static String dateShort(DateTime date) => _dateShort.format(date);

  static String monthYear(DateTime date) => _monthYear.format(date);

  static String percentage(double value) => '${value.toStringAsFixed(0)}%';
}
