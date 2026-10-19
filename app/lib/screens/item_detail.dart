import 'package:flutter/material.dart';

import '../data.dart';
import '../widgets.dart';
import 'claim.dart';

// Screen 9: item details (FR-15, FR-20, FR-27)
class ItemDetailScreen extends StatelessWidget {
  const ItemDetailScreen({super.key, required this.report, this.guest = false});

  final Report report;
  final bool guest;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final found = report.type == ReportType.found;
    return Scaffold(
      appBar: AppBar(
        title: Text(found ? 'Found item' : 'Lost item'),
        actions: [
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
                        showReportSheet(context);
                      },
                    ),
                    ListTile(
                      title: const Text('Block this user'),
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('User blocked (demo).')));
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
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline, color: cs.onSurfaceVariant),
                  const SizedBox(height: 4),
                  const Text('Photo is private',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  Text(
                      'Shown to the finder, campus admins and an approved claimant.',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(color: cs.onSurfaceVariant, fontSize: 12.5)),
                ],
              ),
            ),
          ),
          SectionTitle(report.title,
              trailing: Tag(labelOf(report.type), kind: kindOf(report.type))),
          AppCard(
            child: Column(
              children: [
                KeyValue('Colour', report.colour ?? 'Not given'),
                KeyValue('Zone', report.zone),
                KeyValue(found ? 'Found' : 'Lost',
                    report.when.isEmpty ? 'Mon 12 Oct' : report.when),
                if (found) const KeyValue('Held at', 'With finder'),
              ],
            ),
          ),
          Text(
              'No names, phone numbers or emails are shown. Handover is at the campus desk.',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.5)),
          if (found)
            FilledButton(
              onPressed: guest ? null : () => go(context, const ClaimScreen()),
              child: Text(guest ? 'Sign in to claim' : 'This is mine'),
            ),
        ],
      ),
    );
  }
}
