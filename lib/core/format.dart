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
