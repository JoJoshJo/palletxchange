import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/report.dart';
import '../repositories/report_repository.dart';

/// Real [ReportRepository]. Any authed user may file; only admins read/resolve
/// (enforced by RLS).
class SupabaseReportRepository implements ReportRepository {
  SupabaseClient get _c => Supabase.instance.client;

  @override
  Future<List<Report>> getAllReports() async {
    final rows = await _c
        .from('reports')
        .select()
        .order('created_at', ascending: false);
    return (rows as List).map((r) => Report.fromJson(r)).toList();
  }

  @override
  Future<Report> createReport(Report report) async {
    final uid = _c.auth.currentUser?.id;
    if (uid == null) throw StateError('No signed-in user');
    final payload = report.toJson()
      ..remove('id')
      ..remove('created_at')
      ..remove('subject_label'); // UI-only, not a column
    payload['reported_by'] = uid;
    final row = await _c.from('reports').insert(payload).select().single();
    return Report.fromJson(row);
  }

  @override
  Future<Report> updateReport(Report report) async {
    final payload = report.toJson()
      ..remove('id')
      ..remove('created_at')
      ..remove('subject_label');
    final row = await _c
        .from('reports')
        .update(payload)
        .eq('id', report.id)
        .select()
        .maybeSingle();
    return row == null ? report : Report.fromJson(row);
  }
}
