import 'package:flutter/material.dart';

import '../data.dart';
import '../widgets.dart';
import 'claim.dart';
import 'matches.dart';

// Screen 11: notifications and my reports (FR-16, FR-17, FR-18, FR-26)
class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Activity'),
          bottom: const TabBar(tabs: [
            Tab(text: 'Notifications'),
            Tab(text: 'My reports'),
          ]),
        ),
        body: const TabBarView(children: [
          _Notifications(),
          _MyReports(),
        ]),
      ),
    );
  }
}

class _Notifications extends StatelessWidget {
  const _Notifications();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = <(String, String, String, Widget Function())>[
      ('Possible match', 'Dark school bag found at the Library. Score 0.89.',
          '2 min', () => const MatchesScreen()),
      ('Claim approved', 'Your claim for the bag was approved. Code ready.',
          '1 h', () => const ClaimScreen(startStage: 2)),
      ('Reminder',
          'Holding a found item for 3 days? Please take it to the campus desk.',
          '1 d', () => const MatchesScreen()),
    ];
    return PageBody(
      children: [
        for (final (title, body, time, page) in items)
          AppCard(
            onTap: () => go(context, page()),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(time,
                        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(body,
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
              ],
            ),
          ),
      ],
    );
  }
}

class _MyReports extends StatelessWidget {
  const _MyReports();

  void _demo(BuildContext context, String what) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$what (demo).')));

  @override
  Widget build(BuildContext context) {
    return PageBody(
      children: [
        const NoteBanner(
            'Day 25: renew or close "Phone charger". It will be archived on day 30 without activity.'),
        for (final r in myReports)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ReportCard(r),
              Row(
                children: [
                  TextButton(
                      onPressed: () => _demo(context, 'Report renewed'),
                      child: const Text('Renew')),
                  TextButton(
                      onPressed: () => _demo(context, 'Report closed'),
                      child: const Text('Close')),
                  TextButton(
                      onPressed: () => _demo(context, 'Notifications muted'),
                      child: const Text('Mute')),
                ],
              ),
            ],
          ),
      ],
    );
  }
}
