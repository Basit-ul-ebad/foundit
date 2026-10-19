import 'package:flutter/material.dart';

import '../data.dart';
import '../widgets.dart';
import 'item_detail.dart';

// Screen 7: search and filters (FR-13, FR-14)
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _type = 'All';
  String _category = 'Bag';
  String _zone = 'Library';
  String _date = '7 days';
  final _keyword = TextEditingController(text: 'backpack');

  @override
  void dispose() {
    _keyword.dispose();
    super.dispose();
  }

  Widget _group(String label, List<String> options, String value,
      void Function(String) set) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final o in options)
              PickChip(o, selected: value == o, onTap: () => setState(() => set(o))),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const results = <Report>[
      Report(ReportType.found, 'Bag', 'Library', 'Mon 3:40 pm', colour: 'Dark'),
      Report(ReportType.found, 'Backpack', 'Library', 'Sun 6:10 pm',
          colour: 'Grey'),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: PageBody(
        children: [
          TextField(
            controller: _keyword,
            decoration: const InputDecoration(labelText: 'Keyword'),
          ),
          const NoteBanner('Also matching: bag, basta, school bag',
              lost: false),
          _group('Type', const ['All', 'Lost', 'Found'], _type,
              (v) => _type = v),
          _group('Category', const ['Bag', 'Phone', 'Wallet', 'Keys'], _category,
              (v) => _category = v),
          _group('Zone', const ['Library', 'Cafeteria', 'Block A'], _zone,
              (v) => _zone = v),
          _group('Date range', const ['Today', '7 days', '14 days'], _date,
              (v) => _date = v),
          const SectionTitle('2 results'),
          for (final r in results)
            ReportCard(r, onTap: () => go(context, ItemDetailScreen(report: r))),
        ],
      ),
    );
  }
}
