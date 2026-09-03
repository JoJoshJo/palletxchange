import '../../models/report.dart';

abstract interface class ReportRepository {
  Future<List<Report>> getAllReports();

  Future<Report> createReport(Report report);

  Future<Report> updateReport(Report report);
}
