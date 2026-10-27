import 'package:flutter/material.dart';

import '../core/format.dart' as fmt;
import '../core/models.dart';
import '../widgets.dart';
import 'claim_review.dart';
import 'create_report.dart';
import 'item_detail.dart';

// Admin section (FR-20, FR-25, FR-28). Only users with the admin role see it.
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final store = AppScope.of(context);
    final openFlags = store.flags.where((f) => f.status == 'open').toList();
    final pending = store.claims.where((c) => c.pending).toList();
    final done = store.claims.where((c) => !c.pending).toList();
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Campus admin'),
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 16),
              child: Tag('Admin', kind: TagKind.lost),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Flags'),
              Tab(text: 'Claims'),
              Tab(text: 'Desk'),
              Tab(text: 'Stats'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Flags
            PageBody(children: [
              if (openFlags.isEmpty)
                Text('No open flags.', style: TextStyle(color: cs.onSurfaceVariant)),
              for (final f in openFlags)
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${f.targetType == 'report' ? 'Post' : f.targetType == 'ai' ? 'Suggestion' : 'User'}: ${f.summary}',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text('Reported for: ${f.reason} (${fmt.ago(f.createdAt)})',
                          style: TextStyle(color: cs.onSurfaceVariant)),
                      const SizedBox(height: 10),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        if (f.targetType == 'report')
                          FilledButton(
                            style: FilledButton.styleFrom(
                                minimumSize: const Size(0, 40),
                                padding: const EdgeInsets.symmetric(horizontal: 16)),
                            onPressed: () => store.resolveFlag(f, outcome: 'hidden'),
                            child: const Text('Hide post'),
                          ),
                        if (f.targetUserId.isNotEmpty)
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 40),
                                padding: const EdgeInsets.symmetric(horizontal: 16)),
                            onPressed: () =>
                                store.resolveFlag(f, outcome: 'suspended'),
                            child: const Text('Suspend user'),
                          ),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 40),
                              padding: const EdgeInsets.symmetric(horizontal: 16)),
                          onPressed: () => store.resolveFlag(f, outcome: 'dismissed'),
                          child: const Text('Dismiss'),
                        ),
                      ]),
                    ],
                  ),
                ),
            ]),
            // Claims
            PageBody(children: [
              if (pending.isEmpty && done.isEmpty)
                Text('No claims yet.', style: TextStyle(color: cs.onSurfaceVariant)),
              for (final c in pending) ClaimReviewCard(claim: c),
              if (done.isNotEmpty) const SectionTitle('Decided'),
              for (final c in done) ClaimReviewCard(claim: c),
            ]),
            // Desk inventory
            PageBody(children: [
              FilledButton(
                  onPressed: () => go(
                      context,
                      const CreateReportScreen(
                          type: ReportType.found, desk: true)),
                  child: const Text('Log a handed-in item')),
              if (store.deskReports.isEmpty)
                Text('No items logged at the desk yet.',
                    style: TextStyle(color: cs.onSurfaceVariant)),
              for (final r in store.deskReports)
                ReportCard(r,
                    onTap: () => go(context, ItemDetailScreen(report: r))),
            ]),
            // Stats
            PageBody(children: [
              GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 1.7,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (final e in store.stats.entries) _Stat(e.key, '${e.value}'),
                ],
              ),
              const NoteBanner(
                  'Gender stats are not shown until a group has 10 or more people.',
                  lost: false),
            ]),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
          Text(value,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
