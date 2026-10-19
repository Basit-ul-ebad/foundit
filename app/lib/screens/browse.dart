import 'package:flutter/material.dart';

import '../data.dart';
import '../widgets.dart';
import 'item_detail.dart';
import 'search.dart';

// Screen 6: browse reports (FR-03, FR-13, FR-15)
class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key, this.guest = false});

  final bool guest;

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  String _tab = 'All';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = sampleFeed.where((r) =>
        _tab == 'All' || labelOf(r.type) == _tab);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse'),
        actions: [
          IconButton(
            tooltip: 'Search and filters',
            icon: const Icon(Icons.search),
            onPressed: () => go(context, const SearchScreen()),
          ),
        ],
      ),
      body: PageBody(
        children: [
          if (widget.guest)
            const NoteBanner(
                'You are browsing as a guest. Sign in to post, claim or see matches.'),
          Wrap(
            spacing: 8,
            children: [
              for (final t in const ['All', 'Lost', 'Found'])
                PickChip(t,
                    selected: _tab == t, onTap: () => setState(() => _tab = t)),
            ],
          ),
          for (final r in items)
            ReportCard(
              r,
              onTap: () =>
                  go(context, ItemDetailScreen(report: r, guest: widget.guest)),
            ),
          Text(
              'Sample feed. Photos and full descriptions are hidden on found items.',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.5)),
        ],
      ),
    );
  }
}
