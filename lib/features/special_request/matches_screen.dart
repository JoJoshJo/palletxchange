import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../data/providers.dart';
import '../../data/services/matching_service.dart';
import '../marketplace/widgets/listing_card.dart';

class MatchesScreen extends ConsumerWidget {
  const MatchesScreen({super.key, required this.requestId});

  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestAsync = ref.watch(requestByIdProvider(requestId));
    final matchesAsync = ref.watch(matchesForRequestProvider(requestId));

    return Scaffold(
      appBar: AppBar(title: const Text('Matches')),
      body: matchesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text("Couldn't run matching")),
        data: (matches) {
          final request = requestAsync.valueOrNull;
          final targeted = request?.targetSellerId != null;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _Banner(targeted: targeted),
              const SizedBox(height: 8),
              const _PathHint(),
              const SizedBox(height: 16),
              Text(
                matches.isEmpty
                    ? 'No matches yet'
                    : '${matches.length} matching ${matches.length == 1 ? 'listing' : 'listings'}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              if (matches.isEmpty)
                const _NoMatches()
              else
                for (final m in matches) ...[
                  _MatchTile(scored: m),
                  const SizedBox(height: 14),
                ],
            ],
          );
        },
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.targeted});

  final bool targeted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.green.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.green.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.green, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              targeted
                  ? 'Request sent — a chat thread with the seller is open in Chat.'
                  : 'Request broadcast — nearby sellers were notified.',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PathHint extends StatelessWidget {
  const _PathHint();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Icon(Icons.info_outline, size: 15, color: AppColors.textMuted),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Found what you need? Deal on the listing directly — Special '
            "Request is for when it isn't posted.",
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _MatchTile extends StatelessWidget {
  const _MatchTile({required this.scored});

  final ScoredListing scored;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MatchBadge(score: scored.score),
        const SizedBox(height: 6),
        ListingCard(
          listing: scored.listing,
          onTap: () => context.push('/listing/${scored.listing.id}'),
        ),
      ],
    );
  }
}

class _MatchBadge extends StatelessWidget {
  const _MatchBadge({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final strong = score >= 8;
    final label = strong
        ? 'Strong match'
        : score >= 5
            ? 'Good match'
            : 'Partial match';
    final color = strong ? AppColors.green : AppColors.teal;
    return Row(
      children: [
        Icon(Icons.auto_awesome, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          '$label · $score/${MatchingService.maxScore}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _NoMatches extends StatelessWidget {
  const _NoMatches();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(Icons.search_off, size: 40, color: AppColors.textMuted),
          SizedBox(height: 10),
          Text(
            'Nothing matches right now',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            "We'll keep your request open and notify you when supply shows up.",
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
