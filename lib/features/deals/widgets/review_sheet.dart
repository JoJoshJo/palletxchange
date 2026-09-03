import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// The values collected by [ReviewSheet].
class ReviewResult {
  const ReviewResult({
    required this.overall,
    required this.communication,
    required this.accuracy,
    required this.delivery,
    this.text,
  });

  final int overall;
  final int communication;
  final int accuracy;
  final int delivery;
  final String? text;
}

/// A bottom sheet collecting an overall rating + three category ratings +
/// optional text (BRAIN §8 — four-category reviews).
class ReviewSheet extends StatefulWidget {
  const ReviewSheet({super.key});

  @override
  State<ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<ReviewSheet> {
  int _overall = 0;
  int _communication = 0;
  int _accuracy = 0;
  int _delivery = 0;
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Leave a review',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _StarRow(
            label: 'Overall',
            value: _overall,
            onChanged: (v) => setState(() => _overall = v),
          ),
          _StarRow(
            label: 'Communication',
            value: _communication,
            onChanged: (v) => setState(() => _communication = v),
          ),
          _StarRow(
            label: 'Accuracy',
            value: _accuracy,
            onChanged: (v) => setState(() => _accuracy = v),
          ),
          _StarRow(
            label: 'Delivery',
            value: _delivery,
            onChanged: (v) => setState(() => _delivery = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _text,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Add a note (optional)',
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _overall == 0
                ? null
                : () => Navigator.pop(
                      context,
                      ReviewResult(
                        overall: _overall,
                        communication:
                            _communication == 0 ? _overall : _communication,
                        accuracy: _accuracy == 0 ? _overall : _accuracy,
                        delivery: _delivery == 0 ? _overall : _delivery,
                        text: _text.text.trim().isEmpty
                            ? null
                            : _text.text.trim(),
                      ),
                    ),
            child: const Text('Submit review'),
          ),
        ],
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const Spacer(),
          for (var i = 1; i <= 5; i++)
            IconButton(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              onPressed: () => onChanged(i),
              icon: Icon(
                i <= value ? Icons.star_rounded : Icons.star_outline_rounded,
                color: i <= value ? AppColors.orange : AppColors.border,
                size: 28,
              ),
            ),
        ],
      ),
    );
  }
}
