import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _inrFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final NumberFormat _inrFormatWithDecimals = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  /// Converts paise (integer) to formatted currency string (e.g. 145000 -> ₹1,450)
  static String formatPaise(int paise, {bool includeDecimals = false}) {
    final double rupees = paise / 100.0;
    if (includeDecimals || (paise % 100 != 0)) {
      return _inrFormatWithDecimals.format(rupees);
    }
    return _inrFormat.format(rupees);
  }

  /// Converts rupees (int/double) to paise (integer)
  static int rupeesToPaise(num rupees) {
    return (rupees * 100).round();
  }
}
