import 'package:flutter/material.dart';

import '../core/campus.dart';
import '../core/models.dart';
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
    final store = AppScope.of(context);
    final top = store.topMatches;
    final mine = store.myReports.where((r) => r.isOpen).take(2).toList();
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          const FounditMark(),
          const SizedBox(width: 8),
          Text('Hi ${store.user?.displayName ?? ''}'),
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
          if (store.syncError != null) NoteBanner(store.syncError!),
          Text(kCampusName, style: TextStyle(color: cs.onSurfaceVariant)),
          const Row(
            children: [
              Expanded(child: _BigAction(type: ReportType.lost)),
              SizedBox(width: 10),
              Expanded(child: _BigAction(type: ReportType.found)),
            ],
          ),
          SectionTitle('New matches',
              trailing: top.isEmpty
                  ? null
                  : Tag('${top.length} suggested', kind: TagKind.found)),
          if (top.isEmpty)
            Text(
                'No matches yet. When a similar report appears on campus, it shows up here.',
                style: TextStyle(color: cs.onSurfaceVariant))
          else
            _TopMatch(report: top.first.$1, match: top.first.$2),
          SectionTitle(
            'My open reports',
            trailing: TextButton(
              onPressed: () => go(context, const ActivityScreen()),
              child: const Text('See all'),
            ),
          ),
          if (mine.isEmpty)
            Text('You have no open reports.',
                style: TextStyle(color: cs.onSurfaceVariant)),
          for (final r in mine)
            ReportCard(r,
                status: store.statusLabel(r),
                onTap: () => go(context, MatchesScreen(report: r))),
        ],
      ),
    );
  }
}

class _TopMatch extends StatelessWidget {
  const _TopMatch({required this.report, required this.match});

  final Report report;
  final MatchRec match;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppCard(
      onTap: () => go(context, MatchesScreen(report: report)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Possible match for your ${report.title.toLowerCase()}',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(match.reason,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
          const SizedBox(height: 10),
          ScoreBar(match.score),
          const SizedBox(height: 4),
          Text('Score ${match.score.toStringAsFixed(2)}',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
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
