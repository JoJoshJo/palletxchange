import '../../models/profile.dart';
import '../repositories/profile_repository.dart';
import 'fake_seed.dart';

/// In-memory [ProfileRepository]. Holds a mutable copy of the seed profiles so
/// admin verify-toggles persist within the session.
class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository() {
    for (final p in [
      FakeSeed.currentUser,
      FakeSeed.demoDriver,
      ...FakeSeed.sellers,
    ]) {
      _profiles[p.id] = p;
    }
  }

  final Map<String, Profile> _profiles = {};

  Future<void> _latency() =>
      Future<void>.delayed(const Duration(milliseconds: 120));

  @override
  Future<Profile> getCurrentProfile() async {
    await _latency();
    return _profiles[FakeSeed.currentUser.id] ?? FakeSeed.currentUser;
  }

  @override
  Future<Profile?> getProfileById(String id) async {
    await _latency();
    return _profiles[id];
  }

  @override
  Future<List<Profile>> getAllProfiles({int limit = 25, int offset = 0}) async {
    await _latency();
    final all = _profiles.values.toList();
    if (offset >= all.length) return const [];
    return all.sublist(offset, (offset + limit).clamp(0, all.length));
  }

  @override
  Future<Profile> updateProfile(Profile profile) async {
    await _latency();
    _profiles[profile.id] = profile;
    return profile;
  }
}
