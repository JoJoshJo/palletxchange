/// Enums mirroring the Supabase schema (BRAIN §6).
///
/// Each enum stores its DB wire value in [value] and a human [label] for the
/// UI. `fromValue` tolerates unknown strings by returning null so future DB
/// additions never crash the client.
library;

enum AccountType {
  individual('individual', 'Individual'),
  warehouse('warehouse', 'Warehouse'),
  driver('driver', 'Driver');

  const AccountType(this.value, this.label);
  final String value;
  final String label;

  static AccountType? fromValue(String? v) =>
      _byValue(AccountType.values, v);
}

enum PalletType {
  standardWooden('Standard wooden pallets'),
  heatTreated('Heat-treated pallets'),
  plastic('Plastic pallets'),
  euro('Euro pallets'),
  stringer('Stringer pallets'),
  block('Block pallets'),
  custom('Custom-size pallets'),
  brokenRecyclable('Broken or recyclable pallets');

  const PalletType(this.value);
  final String value;
  String get label => value;

  static PalletType? fromValue(String? v) => _byValue(PalletType.values, v);
}

enum PalletCondition {
  isNew('New'),
  likeNew('Like new'),
  usedGood('Used, good condition'),
  usedRepairable('Used, repairable'),
  damaged('Damaged'),
  scrap('Scrap/recycling only');

  const PalletCondition(this.value);
  final String value;
  String get label => value;

  /// Short grade badge shown on cards.
  String get grade => switch (this) {
        PalletCondition.isNew => 'New',
        PalletCondition.likeNew => 'Like new',
        PalletCondition.usedGood => 'Good',
        PalletCondition.usedRepairable => 'Repairable',
        PalletCondition.damaged => 'Damaged',
        PalletCondition.scrap => 'Scrap',
      };

  /// Recyclable filter = Damaged or Scrap (BRAIN §4, §7).
  bool get isRecyclable =>
      this == PalletCondition.damaged || this == PalletCondition.scrap;

  static PalletCondition? fromValue(String? v) =>
      _byValue(PalletCondition.values, v);
}

enum PalletSize {
  s48x40('48 x 40'),
  s42x42('42 x 42'),
  s48x48('48 x 48'),
  s36x36('36 x 36'),
  euro('Euro pallet'),
  custom('Custom size');

  const PalletSize(this.value);
  final String value;
  String get label => value;

  static PalletSize? fromValue(String? v) => _byValue(PalletSize.values, v);
}

enum ListingStatus {
  active('active'),
  unavailable('unavailable'),
  soldOut('sold_out'),
  archived('archived');

  const ListingStatus(this.value);
  final String value;

  static ListingStatus? fromValue(String? v) =>
      _byValue(ListingStatus.values, v);
}

enum RequestStatus {
  open('open'),
  matched('matched'),
  closed('closed'),
  cancelled('cancelled');

  const RequestStatus(this.value);
  final String value;

  static RequestStatus? fromValue(String? v) =>
      _byValue(RequestStatus.values, v);
}

enum DealStatus {
  pending('pending'),
  accepted('accepted'),
  completed('completed'),
  cancelled('cancelled'),
  declined('declined');

  const DealStatus(this.value);
  final String value;

  static DealStatus? fromValue(String? v) => _byValue(DealStatus.values, v);
}

enum PaymentStatus {
  notRequired('not_required'),
  unpaid('unpaid'),
  paid('paid');

  const PaymentStatus(this.value);
  final String value;

  static PaymentStatus? fromValue(String? v) =>
      _byValue(PaymentStatus.values, v);
}

enum FulfillmentMethod {
  pickup('pickup'),
  delivery('delivery');

  const FulfillmentMethod(this.value);
  final String value;
  String get label => this == pickup ? 'Pickup' : 'Delivery';

  static FulfillmentMethod? fromValue(String? v) =>
      _byValue(FulfillmentMethod.values, v);
}

enum DeliveryStatus {
  requested('requested', 'Requested'),
  accepted('accepted', 'Accepted'),
  driverAssigned('driver_assigned', 'Driver assigned'),
  pickedUp('picked_up', 'Picked up'),
  inTransit('in_transit', 'In transit'),
  delivered('delivered', 'Delivered'),
  completed('completed', 'Completed'),
  cancelled('cancelled', 'Cancelled');

  const DeliveryStatus(this.value, this.label);
  final String value;
  final String label;

  static DeliveryStatus? fromValue(String? v) =>
      _byValue(DeliveryStatus.values, v);
}

enum ReportStatus {
  open('open', 'Open'),
  resolved('resolved', 'Resolved');

  const ReportStatus(this.value, this.label);
  final String value;
  final String label;

  static ReportStatus? fromValue(String? v) => _byValue(ReportStatus.values, v);
}

T? _byValue<T extends Enum>(List<T> values, String? v) {
  if (v == null) return null;
  for (final e in values) {
    if ((e as dynamic).value == v) return e;
  }
  return null;
}
