import '../../models/profile.dart';
import '../repositories/profile_repository.dart';
import 'fake_seed.dart';

class FakeProfileRepository implements ProfileRepository {
  @override
  Future<Profile> getCurrentProfile() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return FakeSeed.currentUser;
  }

  @override
  Future<Profile?> getProfileById(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return FakeSeed.sellerById(id);
  }
}
