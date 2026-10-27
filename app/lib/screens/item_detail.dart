import 'dart:convert';

import 'package:flutter/material.dart';

import '../core/format.dart' as fmt;
import '../core/models.dart';
import '../widgets.dart';
import 'claim.dart';
import 'claim_review.dart';

// Screen 9: item details (FR-15, FR-20, FR-27)
class ItemDetailScreen extends StatefulWidget {
  const ItemDetailScreen({super.key, required this.report, this.guest = false});

  final Report report;
  final bool guest;

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  Future<Map<String, dynamic>?>? _private;

  @override
  void initState() {
    super.initState();
    if (widget.report.hasPhoto && !widget.guest) {
      // Allowed only for the finder, campus admins and an approved claimant.
      _private = AppScope.read(context).privateFor(widget.report.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final store = AppScope.of(context);
    final report = store.reportById(widget.report.id) ?? widget.report;
    final found = report.isFound;
    final mine = report.userId == store.uid;
    final claim = store.myClaimFor(report.id);
    final toReview = [
      for (final c in store.claimsToReview())
        if (c.foundReportId == report.id) c,
    ];
    final showFull = mine || store.isAdmin || (claim?.approved ?? false);
    return Scaffold(
      appBar: AppBar(
        title: Text(found ? 'Found item' : 'Lost item'),
        actions: [
          if (!widget.guest && !mine)
            IconButton(
              tooltip: 'More',
              icon: const Icon(Icons.more_vert),
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                showDragHandle: true,
                builder: (sheetContext) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: const Text('Report this post'),
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          showReportSheet(
                            context,
                            onReason: (reason) => store.flagReport(report, reason),
                          );
                        },
                      ),
                      ListTile(
                        title: const Text('Block this user'),
                        onTap: () async {
                          Navigator.of(sheetContext).pop();
                          final nav = Navigator.of(context);
                          await store.blockUser(report.userId);
                          if (!mounted) return;
                          toast(context, 'User blocked. Their posts are hidden.');
                          nav.pop();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: PageBody(
        children: [
          Container(
            height: 150,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: _photoArea(cs, report, showFull),
          ),
          SectionTitle(report.title,
              trailing: Tag(labelOf(report.type), kind: kindOf(report.type))),
          AppCard(
            child: Column(
              children: [
                KeyValue('Category', report.category),
                KeyValue('Colour', report.colour ?? 'Not given'),
                KeyValue('Zone', report.zone),
                KeyValue(found ? 'Found' : 'Lost', fmt.when(report.eventTime)),
                if (found)
                  KeyValue('Held at', report.desk ? 'Campus desk' : 'With finder'),
              ],
            ),
          ),
          if (report.description.isNotEmpty && (!found || showFull))
            AppCard(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(report.description),
              ),
            ),
          Text(
              'No names, phone numbers or emails are shown. Handover is at the campus desk.',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.5)),
          if (found && !mine && report.isOpen && claim == null)
            FilledButton(
              onPressed: widget.guest
                  ? null
                  : () => go(context, ClaimScreen(report: report)),
              child: Text(widget.guest ? 'Sign in to claim' : 'This is mine'),
            ),
          if (found && claim != null)
            OutlinedButton(
              onPressed: () => go(context, ClaimScreen(report: report)),
              child: const Text('View my claim'),
            ),
          if (toReview.isNotEmpty) ...[
            const SectionTitle('Claims on this item'),
            for (final c in toReview) ClaimReviewCard(claim: c),
          ],
        ],
      ),
    );
  }

  Widget _photoArea(ColorScheme cs, Report report, bool showFull) {
    final future = _private;
    if (report.hasPhoto && showFull && future != null) {
      return FutureBuilder<Map<String, dynamic>?>(
        future: future,
        builder: (context, snap) {
          final data = snap.data;
          final b64 = data == null ? null : data['photo'] as String?;
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (b64 == null) return _locked(cs);
          return Image.memory(base64Decode(b64),
              fit: BoxFit.cover, width: double.infinity);
        },
      );
    }
    return _locked(cs, noPhoto: !report.hasPhoto);
  }

  Widget _locked(ColorScheme cs, {bool noPhoto = false}) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(noPhoto ? Icons.image_not_supported_outlined : Icons.lock_outline,
                color: cs.onSurfaceVariant),
            const SizedBox(height: 4),
            Text(noPhoto ? 'No photo' : 'Photo is private',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            if (!noPhoto)
              Text(
                  'Shown to the finder, campus admins and an approved claimant.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.5)),
          ],
        ),
      );
}
