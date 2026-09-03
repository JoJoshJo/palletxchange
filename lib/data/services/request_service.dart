import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/request.dart';
import '../providers.dart';

class RequestService {
  RequestService(this.ref);

  final Ref ref;

  /// Creates a Special Request. For a targeted request (targetSellerId set),
  /// also opens a chat thread with that seller. Returns the stored request.
  Future<PalletRequest> create(PalletRequest request) async {
    final stored =
        await ref.read(requestRepositoryProvider).createRequest(request);

    if (stored.targetSellerId != null) {
      final seller = await ref
          .read(profileRepositoryProvider)
          .getProfileById(stored.targetSellerId!);
      if (seller != null) {
        await ref
            .read(messageServiceProvider)
            .openRequestThread(stored, seller);
      }
    }

    ref.invalidate(matchesForRequestProvider(stored.id));
    return stored;
  }
}
