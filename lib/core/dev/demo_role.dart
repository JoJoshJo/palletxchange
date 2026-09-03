import 'package:flutter_riverpod/flutter_riverpod.dart';

/// DEV-ONLY: which surface the demo user is viewing. Real auth (Milestone 3)
/// replaces this with the authenticated account's type + is_admin flag.
enum DemoRole {
  trader('Trader', '/browse'),
  driver('Driver', '/driver'),
  admin('Admin', '/admin');

  const DemoRole(this.label, this.home);
  final String label;
  final String home;
}

final demoRoleProvider = StateProvider<DemoRole>((ref) => DemoRole.trader);
