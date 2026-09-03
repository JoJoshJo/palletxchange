import '../../models/profile.dart';

abstract interface class ProfileRepository {
  /// The signed-in user's profile (a fixed demo trader until auth lands).
  Future<Profile> getCurrentProfile();

  Future<Profile?> getProfileById(String id);
}
