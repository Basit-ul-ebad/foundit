import 'package:flutter/material.dart';

import '../data.dart';
import '../widgets.dart';
import 'photo_details.dart';

// Screen 4: create report (FR-04, FR-06, FR-07)
class CreateReportScreen extends StatefulWidget {
  const CreateReportScreen({super.key, required this.type});

  final ReportType type;

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  late ReportType _type = widget.type;
  late final TextEditingController _title;
  late final TextEditingController _desc;
  String _category = categories.first;
  String _zone = campusZones.first;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController();
    _desc = TextEditingController();
    _fill();
  }

  void _fill() {
    final lost = _type == ReportType.lost;
    _title.text = lost ? 'Black backpack' : 'Dark school bag';
    _desc.text = lost
        ? 'Lost near the library yesterday afternoon.'
        : 'Left outside the main library.';
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('New report')),
      body: PageBody(
        children: [
          SegmentedButton<ReportType>(
            segments: const [
              ButtonSegment(value: ReportType.lost, label: Text('I lost it')),
              ButtonSegment(value: ReportType.found, label: Text('I found it')),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() {
              _type = s.first;
              _fill();
            }),
          ),
          TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title')),
          TextField(
              controller: _desc,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Description')),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: [
              for (final c in categories)
                DropdownMenuItem(value: c, child: Text(c)),
            ],
            onChanged: (v) => setState(() => _category = v ?? _category),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Campus zone',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final z in campusZones)
                    PickChip(z,
                        selected: _zone == z,
                        onTap: () => setState(() => _zone = z)),
                ],
              ),
            ],
          ),
          const Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                      labelText: 'Date', hintText: 'Mon 12 Oct'),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                      labelText: 'Time', hintText: '12:30 pm'),
                ),
              ),
            ],
          ),
          AppCard(
            color: cs.primaryContainer,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('A quick question',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    const AiBadge(),
                    TextButton(
                      onPressed: () =>
                          showReportSheet(context, what: 'AI message'),
                      child: const Text('Report'),
                    ),
                  ],
                ),
                const Text(
                    'What colour is it, and does it have a brand or sticker?'),
                const SizedBox(height: 8),
                const TextField(
                  decoration: InputDecoration(
                      hintText: 'Black, small white sticker',
                      isDense: true),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: () => go(context, PhotoDetailsScreen(type: _type)),
            child: const Text('Next: photo and details'),
          ),
        ],
      ),
    );
  }
}
