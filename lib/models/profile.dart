import 'enums.dart';

/// A user profile (BRAIN §6). `id` equals the auth UID in Supabase.
class Profile {
  const Profile({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.businessName,
    required this.accountType,
    this.isAdmin = false,
    this.address,
    this.city,
    this.state,
    this.zip,
    this.latitude,
    this.longitude,
    this.verifiedStatus = false,
    this.rating,
    this.driverApproved = false,
    this.createdAt,
  });

  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? businessName;
  final AccountType accountType;
  final bool isAdmin;
  final String? address;
  final String? city;
  final String? state;
  final String? zip;
  final double? latitude;
  final double? longitude;
  final bool verifiedStatus;

  /// Computed from reviews server-side; may be null when unrated.
  final double? rating;

  /// Driver vetting: approved to claim jobs (admin-granted).
  final bool driverApproved;
  final DateTime? createdAt;

  /// Name shown on cards: business name when present, else personal name.
  String get displayName =>
      (businessName != null && businessName!.isNotEmpty)
          ? businessName!
          : name;

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        email: json['email'] as String?,
        phone: json['phone'] as String?,
        businessName: json['business_name'] as String?,
        accountType: AccountType.fromValue(json['account_type'] as String?) ??
            AccountType.individual,
        isAdmin: json['is_admin'] as bool? ?? false,
        address: json['address'] as String?,
        city: json['city'] as String?,
        state: json['state'] as String?,
        zip: json['zip'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        verifiedStatus: json['verified_status'] as bool? ?? false,
        rating: (json['rating'] as num?)?.toDouble(),
        driverApproved: json['driver_approved'] as bool? ?? false,
        createdAt: json['created_at'] == null
            ? null
            : DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'business_name': businessName,
        'account_type': accountType.value,
        'is_admin': isAdmin,
        'address': address,
        'city': city,
        'state': state,
        'zip': zip,
        'latitude': latitude,
        'longitude': longitude,
        'verified_status': verifiedStatus,
        'rating': rating,
        'created_at': createdAt?.toIso8601String(),
      };

  Profile copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? businessName,
    AccountType? accountType,
    bool? isAdmin,
    String? address,
    String? city,
    String? state,
    String? zip,
    double? latitude,
    double? longitude,
    bool? verifiedStatus,
    double? rating,
    bool? driverApproved,
    DateTime? createdAt,
  }) =>
      Profile(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        businessName: businessName ?? this.businessName,
        accountType: accountType ?? this.accountType,
        isAdmin: isAdmin ?? this.isAdmin,
        address: address ?? this.address,
        city: city ?? this.city,
        state: state ?? this.state,
        zip: zip ?? this.zip,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        verifiedStatus: verifiedStatus ?? this.verifiedStatus,
        rating: rating ?? this.rating,
        driverApproved: driverApproved ?? this.driverApproved,
        createdAt: createdAt ?? this.createdAt,
      );
}
