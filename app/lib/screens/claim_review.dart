import 'package:flutter/material.dart';

import '../core/matching.dart';
import '../core/models.dart';
import '../data/store.dart';
import '../widgets.dart';

/// A claim for the finder or a campus admin to review (FR-20, FR-25).
/// The hint is a comparison of words only. The reviewer always decides.
class ClaimReviewCard extends StatefulWidget {
  const ClaimReviewCard({super.key, required this.claim});

  final Claim claim;

  @override
  State<ClaimReviewCard> createState() => _ClaimReviewCardState();
}

class _ClaimReviewCardState extends State<ClaimReviewCard> {
  Future<Map<String, dynamic>?>? _private;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final store = AppScope.read(context);
    if (store.canReview(widget.claim)) {
      _private = store.privateFor(widget.claim.foundReportId);
    }
  }

  Future<void> _decide(bool approve) async {
    final store = AppScope.of(context);
    setState(() => _busy = true);
    try {
      await store.decideClaim(widget.claim, approve: approve);
    } on StoreError catch (e) {
      if (mounted) toast(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _enterCode() async {
    final store = AppScope.of(context);
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Enter the handover code'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(hintText: '6-digit code'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text),
              child: const Text('Confirm')),
        ],
      ),
    );
    controller.dispose();
    if (code == null) return;
    final ok = await store.completeClaim(widget.claim, code);
    if (!mounted) return;
    toast(context, ok ? 'Marked as returned.' : 'That code does not match.');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final store = AppScope.of(context);
    // Always show the latest state of this claim.
    final c = store.claims.firstWhere((x) => x.id == widget.claim.id,
        orElse: () => widget.claim);
    final report = store.reportById(c.foundReportId);
    final canReview = store.canReview(c);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
                child: Text('Claim: ${c.foundTitle}',
                    style: const TextStyle(fontWeight: FontWeight.w700))),
            Tag(c.status, kind: c.pending ? TagKind.lost : TagKind.found),
          ]),
          const SizedBox(height: 6),
          if (c.requiresAdmin)
            Text('Admin review needed: a user under 18 is involved.',
                style: TextStyle(color: cs.secondary, fontSize: 12.5)),
          if (canReview)
            FutureBuilder<Map<String, dynamic>?>(
              future: _private,
              builder: (context, snap) {
                final expected = ((snap.data?['answers']) as List?)
                        ?.map((e) => e.toString())
                        .toList() ??
                    <String>[];
                final questions = report?.questions ?? const <String>[];
                final hint = claimHint(expected, c.answers);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Tag(hint.label,
                          kind: hint.label == 'Strong hint'
                              ? TagKind.found
                              : TagKind.neutral),
                      const SizedBox(width: 8),
                      const AiBadge(),
                      const SizedBox(width: 6),
                      const Expanded(child: Text('Hint only. You decide.')),
                    ]),
                    const SizedBox(height: 4),
                    Text(hint.detail,
                        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                    const SizedBox(height: 8),
                    for (var i = 0; i < c.answers.length; i++) ...[
                      Text(i < questions.length ? questions[i] : 'Question ${i + 1}',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text('Claimant: ${c.answers[i].isEmpty ? '(blank)' : c.answers[i]}'),
                      if (i < expected.length)
                        Text('Hidden answer: ${expected[i]}',
                            style: TextStyle(color: cs.onSurfaceVariant)),
                      const SizedBox(height: 6),
                    ],
                    if (c.note.isNotEmpty) Text('Note: ${c.note}'),
                  ],
                );
              },
            )
          else
            Text('Only the finder or a campus admin can review this claim.',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
          const SizedBox(height: 8),
          if (c.pending && canReview)
            Row(children: [
              FilledButton(
                style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 16)),
                onPressed: _busy ? null : () => _decide(true),
                child: const Text('Approve'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 16)),
                onPressed: _busy ? null : () => _decide(false),
                child: const Text('Reject'),
              ),
            ]),
          if (c.approved && canReview)
            OutlinedButton(
                onPressed: _enterCode, child: const Text('Enter handover code')),
        ],
      ),
    );
  }
}
