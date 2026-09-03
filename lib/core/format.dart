import 'package:intl/intl.dart';

import '../models/listing.dart';

final _currency = NumberFormat.currency(locale: 'en_US', symbol: '\$');
final _currencyWhole =
    NumberFormat.currency(locale: 'en_US', symbol: '\$', decimalDigits: 0);

/// "$12.50" style money.
String money(double v) => _currency.format(v);

/// "$320" style whole-dollar money (for totals in headers).
String moneyWhole(double v) => _currencyWhole.format(v);

/// Price line for a listing: "Free" or "$12.50 / pallet".
String pricePerPalletLabel(Listing l) =>
    l.isFree ? 'Free' : '${money(l.pricePerPallet)} / pallet';

/// Distance like "3.1 mi" or empty when unknown.
String distanceLabel(double? miles) =>
    miles == null ? '' : '${miles.toStringAsFixed(1)} mi';

/// Compact relative timestamp for chat rows: "now", "5m", "3h", "2d", or a
/// date for anything older.
String shortTimestamp(DateTime? t) {
  if (t == null) return '';
  final diff = DateTime.now().difference(t);
  if (diff.inMinutes < 1) return 'now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  return DateFormat('MMM d').format(t);
}

/// Time-of-day label for message bubbles, e.g. "8:04 AM".
String clockTime(DateTime? t) => t == null ? '' : DateFormat('h:mm a').format(t);

