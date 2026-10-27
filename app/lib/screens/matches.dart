import 'package:flutter/material.dart';

import '../core/format.dart' as fmt;
import '../core/models.dart';
import '../widgets.dart';
import 'item_detail.dart';

// Screen 8: match results (FR-10, FR-11, FR-12)
class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key, required this.report});

  final Report report;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final store = AppScope.of(context);
    final list = store.matchesFor(report);
    return Scaffold(
      appBar: AppBar(title: const Text('Matches')),
      body: PageBody(
        children: [
          ReportCard(report, status: store.statusLabel(report)),
          Text(
              'Scores use the starting weights and are suggestions only: a person confirms ownership.',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.5)),
          if (list.isEmpty)
            const NoteBanner(
                'No matches yet. We will add a notification when a similar report appears on campus.',
                lost: false),
          for (final m in list) _MatchCard(match: m, mine: report),
        ],
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.match, required this.mine});

  final MatchRec match;
  final Report mine;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final store = AppScope.of(context);
    final other = store.otherSide(match, mine);
    if (other == null) return const SizedBox.shrink();
    Widget part(String label, double v) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11.5)),
              Text(v.toStringAsFixed(2),
                  style: const TextStyle(
                      fontFamily: 'monospace', fontWeight: FontWeight.w600)),
            ],
          ),
        );
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                  child: Text(other.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15))),
              Text(match.score.toStringAsFixed(2),
                  style: const TextStyle(
                      fontFamily: 'monospace', fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 2),
          Text('${other.zone}, ${fmt.when(other.eventTime)}',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
          const SizedBox(height: 8),
          ScoreBar(match.score),
          const SizedBox(height: 8),
          Row(children: [
            part('Text', match.text),
            part('Category', match.category),
            part('Place', match.place),
            part('Time', match.time),
          ]),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AiBadge(),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(match.reason,
                      style:
                          TextStyle(color: cs.onSurfaceVariant, fontSize: 13))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              FilledButton(
                style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 16)),
                onPressed: () => go(context, ItemDetailScreen(report: other)),
                child: const Text('View'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 16)),
                onPressed: () => store.dismissMatch(match),
                child: const Text('Dismiss'),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => showReportSheet(
                  context,
                  what: 'suggestion',
                  onReason: (reason) => store.flagOther(
                      'ai', 'Match suggestion: ${other.title}', reason),
                ),
                child: const Text('Report'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
