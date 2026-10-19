import 'package:flutter/material.dart';

import '../data.dart';
import '../widgets.dart';
import 'item_detail.dart';

// Screen 8: match results (FR-10, FR-11, FR-12)
class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const mine = Report(ReportType.lost, 'Black backpack', 'Library', 'Mon 12:30 pm');
    return Scaffold(
      appBar: AppBar(title: const Text('Matches')),
      body: PageBody(
        children: [
          const ReportCard(mine),
          Text(
              'Scores use the starting weights and are illustrative. These are suggestions only: a person confirms ownership.',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.5)),
          for (var i = 0; i < sampleMatches.length; i++)
            if (!appState.dismissed.contains(i)) _matchCard(context, i),
        ],
      ),
    );
  }

  Widget _matchCard(BuildContext context, int i) {
    final cs = Theme.of(context).colorScheme;
    final m = sampleMatches[i];
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
                  child: Text(m.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15))),
              Text(m.score.toStringAsFixed(2),
                  style: const TextStyle(
                      fontFamily: 'monospace', fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 2),
          Text(m.where, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
          const SizedBox(height: 8),
          ScoreBar(m.score),
          const SizedBox(height: 8),
          Row(children: [
            part('Text', m.text),
            part('Category', m.category),
            part('Place', m.place),
            part('Time', m.time),
          ]),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AiBadge(),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(m.reason,
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
                onPressed: () => go(
                  context,
                  ItemDetailScreen(
                    report: Report(ReportType.found, m.title, m.where, ''),
                  ),
                ),
                child: const Text('View'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 16)),
                onPressed: () => setState(() => appState.dismissed.add(i)),
                child: const Text('Dismiss'),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => showReportSheet(context, what: 'AI message'),
                child: const Text('Report'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
