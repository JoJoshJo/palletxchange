import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/profile.dart';
import '../repositories/profile_repository.dart';

/// Real [ProfileRepository] backed by the Supabase `profiles` table. RLS is the
/// enforcement layer — reads/writes are gated server-side.
class SupabaseProfileRepository implements ProfileRepository {
  SupabaseClient get _c => Supabase.instance.client;

  static const _cols =
      'id, name, email, phone, business_name, account_type, is_admin, '
      'address, city, state, zip, latitude, longitude, verified_status, '
      'rating, driver_approved, driver_license_url, driver_insurance_url, '
      'banned, created_at';

  @override
  Future<Profile> getCurrentProfile() async {
    final uid = _c.auth.currentUser?.id;
    if (uid == null) {
      throw StateError('No signed-in user');
    }
    final row =
        await _c.from('profiles').select(_cols).eq('id', uid).single();
    return Profile.fromJson(row);
  }

  @override
  Future<Profile?> getProfileById(String id) async {
    final row =
        await _c.from('profiles').select(_cols).eq('id', id).maybeSingle();
    return row == null ? null : Profile.fromJson(row);
  }

  @override
  Future<List<Profile>> getAllProfiles({int limit = 25, int offset = 0}) async {
    final rows = await _c
        .from('profiles')
        .select(_cols)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return (rows as List).map((r) => Profile.fromJson(r)).toList();
  }

  @override
  Future<Profile> updateProfile(Profile profile) async {
    final payload = profile.toJson()
      ..remove('id')
      ..remove('created_at');
    await _c.from('profiles').update(payload).eq('id', profile.id);
    return profile;
  }
}
