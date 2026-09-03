import '../../models/request.dart';

abstract interface class RequestRepository {
  /// Open broadcast requests visible in the market.
  Future<List<PalletRequest>> getOpenRequests();

  /// Requests created by one buyer.
  Future<List<PalletRequest>> getRequestsByBuyer(String buyerId);

  Future<PalletRequest?> getRequestById(String id);

  Future<PalletRequest> createRequest(PalletRequest request);
}
