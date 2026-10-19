import 'package:flutter/material.dart';

import '../data.dart';
import '../widgets.dart';
import 'activity.dart';
import 'create_report.dart';
import 'matches.dart';
import 'search.dart';

// Screen 3: home dashboard (FR-04, FR-16)
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final top = sampleMatches.first;
    return Scaffold(
      appBar: AppBar(
        title: const Row(children: [
          FounditMark(),
          SizedBox(width: 8),
          Text('Hi Ali'),
        ]),
        actions: [
          IconButton(
            tooltip: 'Search',
            icon: const Icon(Icons.search),
            onPressed: () => go(context, const SearchScreen()),
          ),
        ],
      ),
      body: PageBody(
        children: [
          Text('COMSATS Islamabad (sample campus)',
              style: TextStyle(color: cs.onSurfaceVariant)),
          const Row(
            children: [
              Expanded(child: _BigAction(type: ReportType.lost)),
              SizedBox(width: 10),
              Expanded(child: _BigAction(type: ReportType.found)),
            ],
          ),
          const SectionTitle('New matches', trailing: Tag('1 new', kind: TagKind.found)),
          AppCard(
            onTap: () => go(context, const MatchesScreen()),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Possible match for your black backpack',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                    '${top.title} found at the main Library, 3 hours after your loss.',
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                const SizedBox(height: 10),
                ScoreBar(top.score),
                const SizedBox(height: 4),
                Text('Score ${top.score.toStringAsFixed(2)} (illustrative)',
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
              ],
            ),
          ),
          SectionTitle(
            'My open reports',
            trailing: TextButton(
              onPressed: () => go(context, const ActivityScreen()),
              child: const Text('See all'),
            ),
          ),
          for (final r in myReports.take(2)) ReportCard(r),
        ],
      ),
    );
  }
}

class _BigAction extends StatelessWidget {
  const _BigAction({required this.type});

  final ReportType type;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final lost = type == ReportType.lost;
    return Material(
      color: lost ? cs.secondaryContainer : cs.primaryContainer,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => go(context, CreateReportScreen(type: type)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: SizedBox(
            height: 84,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Tag(labelOf(type), kind: kindOf(type)),
                Text(lost ? 'I lost something' : 'I found something',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
