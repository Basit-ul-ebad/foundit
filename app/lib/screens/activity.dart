import 'package:flutter/material.dart';

import '../core/format.dart' as fmt;
import '../core/models.dart';
import '../widgets.dart';
import 'claim.dart';
import 'claim_review.dart';
import 'item_detail.dart';
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

  void _open(BuildContext context, Notice n) {
    final store = AppScope.of(context);
    store.markRead(n);
    final report = n.reportId == null ? null : store.reportById(n.reportId!);
    if (report == null) return;
    if (n.kind == 'match') {
      go(context, MatchesScreen(report: report));
    } else if (n.kind == 'claim' && report.userId != store.uid) {
      go(context, ClaimScreen(report: report));
    } else {
      go(context, ItemDetailScreen(report: report));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = AppScope.of(context).visibleNotices;
    return PageBody(
      children: [
        if (items.isEmpty)
          Text('No notifications yet.',
              style: TextStyle(color: cs.onSurfaceVariant)),
        for (final n in items)
          AppCard(
            onTap: () => _open(context, n),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      if (!n.read)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                              color: cs.primary, shape: BoxShape.circle),
                        ),
                      Text(n.title,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ]),
                    Text(fmt.ago(n.createdAt),
                        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(n.body,
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final store = AppScope.of(context);
    final mine = store.myReports;
    final myClaims = store.myClaims;
    final review = store.claimsToReview().where((c) => c.finderId == store.uid).toList();
    return PageBody(
      children: [
        if (mine.isEmpty && myClaims.isEmpty)
          Text('You have not posted anything yet.',
              style: TextStyle(color: cs.onSurfaceVariant)),
        for (final r in mine)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (store.needsRenewal(r))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: NoteBanner(
                      'Day 25: renew or close "${r.title}". It is archived on day 30 without activity.'),
                ),
              if (store.needsDeskReminder(r))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: NoteBanner(
                      'Still holding "${r.title}"? Please take it to the campus desk.'),
                ),
              ReportCard(r,
                  status: store.statusLabel(r),
                  onTap: () => go(context, MatchesScreen(report: r))),
              Wrap(
                children: [
                  if (r.status == statusOpen || r.status == statusArchived)
                    TextButton(
                        onPressed: () async {
                          await store.renewReport(r);
                          if (context.mounted) toast(context, 'Report renewed.');
                        },
                        child: const Text('Renew')),
                  if (r.status == statusOpen)
                    TextButton(
                        onPressed: () async {
                          await store.closeReport(r);
                          if (context.mounted) toast(context, 'Report closed.');
                        },
                        child: const Text('Close')),
                  TextButton(
                      onPressed: () async {
                        await store.toggleMute(r);
                        if (context.mounted) {
                          toast(
                              context,
                              store.user!.muted.contains(r.id)
                                  ? 'Notifications muted for this report.'
                                  : 'Notifications turned on.');
                        }
                      },
                      child: Text(store.user!.muted.contains(r.id) ? 'Unmute' : 'Mute')),
                  TextButton(
                      onPressed: () async {
                        await store.deleteReport(r);
                        if (context.mounted) toast(context, 'Report deleted.');
                      },
                      child: const Text('Delete')),
                ],
              ),
            ],
          ),
        if (review.isNotEmpty) const SectionTitle('Claims to review'),
        for (final c in review) ClaimReviewCard(claim: c),
        if (myClaims.isNotEmpty) const SectionTitle('My claims'),
        for (final c in myClaims)
          AppCard(
            onTap: () {
              final r = store.reportById(c.foundReportId);
              if (r != null) go(context, ClaimScreen(report: r));
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                    child: Text(c.foundTitle,
                        style: const TextStyle(fontWeight: FontWeight.w700))),
                Tag(c.status, kind: c.pending ? TagKind.lost : TagKind.found),
              ],
            ),
          ),
      ],
    );
  }
}
