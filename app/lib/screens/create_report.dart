import 'package:flutter/material.dart';

import '../core/campus.dart';
import '../core/format.dart' as fmt;
import '../core/models.dart';
import '../core/text_tools.dart';
import '../data/store.dart';
import '../widgets.dart';
import 'photo_details.dart';

// Screen 4: create report (FR-04, FR-06, FR-07)
class CreateReportScreen extends StatefulWidget {
  const CreateReportScreen({super.key, required this.type, this.desk = false});

  final ReportType type;

  /// True when campus desk staff log a handed-in item.
  final bool desk;

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  late ReportType _type = widget.desk ? ReportType.found : widget.type;
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _answer = TextEditingController();
  String _category = categories.first;
  String _zone = campusZones.first;
  String? _colour;
  DateTime _when = DateTime.now();

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _answer.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _when,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now,
    );
    if (d != null) {
      setState(() => _when =
          DateTime(d.year, d.month, d.day, _when.hour, _when.minute));
    }
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(_when));
    if (t != null) {
      setState(() => _when =
          DateTime(_when.year, _when.month, _when.day, t.hour, t.minute));
    }
  }

  // FR-07: ask a follow-up if there is no colour, brand or unique mark.
  bool get _needsFollowUp =>
      !hasColourOrMark('${_title.text} ${_desc.text} ${_answer.text}', _colour);

  void _next() {
    if (_title.text.trim().isEmpty) {
      toast(context, 'Add a short title.');
      return;
    }
    if (_when.isAfter(DateTime.now())) {
      toast(context, 'The time cannot be in the future.');
      return;
    }
    final desc = [
      _desc.text.trim(),
      if (_answer.text.trim().isNotEmpty) _answer.text.trim(),
    ].where((e) => e.isNotEmpty).join('. ');
    go(
      context,
      PhotoDetailsScreen(
        desk: widget.desk,
        draft: ReportDraft(
          type: _type,
          title: _title.text,
          description: desc,
          category: _category,
          colour: _colour,
          zone: _zone,
          eventTime: _when,
          desk: widget.desk,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final found = _type == ReportType.found;
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.desk ? 'Log a handed-in item' : 'New report')),
      body: PageBody(
        children: [
          if (!widget.desk)
            SegmentedButton<ReportType>(
              segments: const [
                ButtonSegment(value: ReportType.lost, label: Text('I lost it')),
                ButtonSegment(value: ReportType.found, label: Text('I found it')),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
          TextField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                  labelText: 'Title',
                  hintText: found ? 'Dark school bag' : 'Black backpack')),
          TextField(
              controller: _desc,
              minLines: 3,
              maxLines: 5,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                  labelText: 'Description',
                  helperText: found
                      ? 'Keep it general. Put hidden details in the next step.'
                      : null,
                  hintText: found
                      ? 'Left outside the main library.'
                      : 'Lost near the library yesterday afternoon.')),
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
              const Text('Colour (optional)',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in colourOptions)
                    PickChip(c,
                        selected: _colour == c,
                        onTap: () =>
                            setState(() => _colour = _colour == c ? null : c)),
                ],
              ),
            ],
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
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today_outlined, size: 18),
                  label: Text(fmt.dateOnly(_when)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickTime,
                  icon: const Icon(Icons.schedule, size: 18),
                  label: Text(fmt.clock(_when)),
                ),
              ),
            ],
          ),
          if (_needsFollowUp)
            AppCard(
              color: cs.primaryContainer,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Expanded(
                        child: Text('A quick question',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                      AiBadge(),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                      'What colour is it, and does it have a brand or sticker?'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _answer,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                        hintText: 'Black, small white sticker', isDense: true),
                  ),
                ],
              ),
            ),
          FilledButton(
            onPressed: _next,
            child: const Text('Next: photo and details'),
          ),
        ],
      ),
    );
  }
}
