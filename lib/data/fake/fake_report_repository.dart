import '../../models/enums.dart';
import '../../models/report.dart';
import '../repositories/report_repository.dart';

/// In-memory [ReportRepository], seeded with a couple of open reports.
class FakeReportRepository implements ReportRepository {
  FakeReportRepository() : _reports = _seed();

  final List<Report> _reports;
  int _idSeq = 100;

  static List<Report> _seed() {
    final now = DateTime(2026, 8, 25, 14);
    return [
      Report(
        id: 'rep1',
        reportedBy: 's3',
        reportedUser: 's4',
        listingId: 'l4',
        reason: 'Misleading condition',
        description: 'Listed as usable but pallets were mostly scrap.',
        status: ReportStatus.open,
        subjectLabel: 'FREE broken pallets — you haul',
        createdAt: now.subtract(const Duration(hours: 8)),
      ),
      Report(
        id: 'rep2',
        reportedBy: 's1',
        reportedUser: 's2',
        dealId: 'd1',
        reason: 'No-show at pickup',
        description: 'Buyer did not show for the scheduled pickup window.',
        status: ReportStatus.open,
        subjectLabel: 'Deal · Heat-treated export pallets',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ];
  }

  Future<void> _latency() =>
      Future<void>.delayed(const Duration(milliseconds: 150));

  @override
  Future<List<Report>> getAllReports() async {
    await _latency();
    return _reports.toList()
      ..sort((a, b) => (b.createdAt ?? DateTime(0))
          .compareTo(a.createdAt ?? DateTime(0)));
  }

  @override
  Future<Report> createReport(Report report) async {
    await _latency();
    final stored = Report(
      id: 'rep_${_idSeq++}',
      reportedBy: report.reportedBy,
      reportedUser: report.reportedUser,
      listingId: report.listingId,
      dealId: report.dealId,
      reason: report.reason,
      description: report.description,
      status: ReportStatus.open,
      subjectLabel: report.subjectLabel,
      createdAt: DateTime.now(),
    );
    _reports.add(stored);
    return stored;
  }

  @override
  Future<Report> updateReport(Report report) async {
    await _latency();
    final i = _reports.indexWhere((r) => r.id == report.id);
    if (i != -1) _reports[i] = report;
    return report;
  }
}
