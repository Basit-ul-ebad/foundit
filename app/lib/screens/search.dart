import 'package:flutter/material.dart';

import '../core/campus.dart';
import '../core/models.dart';
import '../core/text_tools.dart';
import '../widgets.dart';
import 'item_detail.dart';

// Screen 7: search and filters (FR-13, FR-14)
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.guest = false});

  final bool guest;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _type = 'All';
  String _category = 'Any';
  String _zone = 'Any';
  String _date = 'Any';
  final _keyword = TextEditingController();

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
              PickChip(o,
                  selected: value == o, onTap: () => setState(() => set(o))),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final results = store.search(
      keyword: _keyword.text,
      type: _type == 'All' ? null : (_type == 'Lost' ? ReportType.lost : ReportType.found),
      category: _category == 'Any' ? null : _category,
      zone: _zone == 'Any' ? null : _zone,
      days: switch (_date) {
        'Today' => 1,
        '7 days' => 7,
        '14 days' => 14,
        _ => null,
      },
    );
    final words = tokens(_keyword.text);
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: PageBody(
        children: [
          TextField(
            controller: _keyword,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
                labelText: 'Keyword', hintText: 'backpack, basta, kala batua'),
          ),
          if (words.isNotEmpty)
            NoteBanner('Searching for: ${words.join(', ')}', lost: false),
          _group('Type', const ['All', 'Lost', 'Found'], _type, (v) => _type = v),
          _group('Category', ['Any', ...categories], _category,
              (v) => _category = v),
          _group('Zone', ['Any', ...campusZones], _zone, (v) => _zone = v),
          _group('Date range', const ['Any', 'Today', '7 days', '14 days'], _date,
              (v) => _date = v),
          SectionTitle('${results.length} results'),
          for (final r in results)
            ReportCard(r,
                onTap: () => go(
                    context, ItemDetailScreen(report: r, guest: widget.guest))),
        ],
      ),
    );
  }
}
