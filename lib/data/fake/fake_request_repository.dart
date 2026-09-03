import '../../models/request.dart';
import '../repositories/request_repository.dart';

/// In-memory [RequestRepository]. Empty to start — Special Requests are a
/// later milestone.
class FakeRequestRepository implements RequestRepository {
  final List<PalletRequest> _requests = [];
  int _idSeq = 1;

  @override
  Future<List<PalletRequest>> getOpenRequests() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return _requests.where((r) => r.targetSellerId == null).toList();
  }

  @override
  Future<List<PalletRequest>> getRequestsByBuyer(String buyerId) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return _requests.where((r) => r.buyerId == buyerId).toList();
  }

  @override
  Future<PalletRequest> createRequest(PalletRequest request) async {
    final stored = request.copyWith(
      id: 'r_${_idSeq++}',
      createdAt: DateTime.now(),
    );
    _requests.add(stored);
    return stored;
  }
}
