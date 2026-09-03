import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import 'create_listing_screen.dart';

/// Loads a listing then opens the create form in edit mode.
class EditListingScreen extends ConsumerWidget {
  const EditListingScreen({super.key, required this.listingId});

  final String listingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(listingByIdProvider(listingId));
    return async.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => const Scaffold(
        body: Center(child: Text("Couldn't load listing")),
      ),
      data: (listing) => listing == null
          ? const Scaffold(body: Center(child: Text('Listing not found')))
          : CreateListingScreen(initial: listing),
    );
  }
}
