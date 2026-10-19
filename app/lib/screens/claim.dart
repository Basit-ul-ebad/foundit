import 'package:flutter/material.dart';

import '../data.dart';
import '../widgets.dart';

// Screen 10: ownership claim (FR-19 to FR-23)
class ClaimScreen extends StatefulWidget {
  const ClaimScreen({super.key, this.startStage = 0});

  final int startStage;

  @override
  State<ClaimScreen> createState() => _ClaimScreenState();
}

class _ClaimScreenState extends State<ClaimScreen> {
  late int _stage = widget.startStage;

  Widget _steps(ColorScheme cs) {
    const labels = ['Submitted', 'Approved', 'Handed over'];
    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < 3; i++)
              Expanded(
                child: Container(
                  height: 6,
                  margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                  decoration: BoxDecoration(
                    color: i <= _stage ? cs.primary : cs.outlineVariant,
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final l in labels)
              Text(l, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Claim this item')),
      body: PageBody(
        children: [
          if (_stage == 0) ...[
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    Expanded(
                        child: Text('Verification questions',
                            style: TextStyle(fontWeight: FontWeight.w700))),
                    AiBadge(),
                  ]),
                  const SizedBox(height: 4),
                  Text(
                      "Drafted from the finder's hidden details and approved by the finder.",
                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                ],
              ),
            ),
            const TextField(
                decoration: InputDecoration(
                    labelText: 'What is stuck inside the front pocket?')),
            const TextField(
                decoration:
                    InputDecoration(labelText: 'What is in the small case?')),
            const TextField(
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                    labelText: 'Note (optional)',
                    hintText: 'Anything else that proves it is yours')),
            Text('Optional proof photo. No ID documents.',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
            Text('Limits: 3 pending claims, 1 per item.',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.5)),
            FilledButton(
                onPressed: () => setState(() => _stage = 1),
                child: const Text('Submit claim')),
          ],
          if (_stage == 1) ...[
            _steps(cs),
            const AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Waiting for review',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  SizedBox(height: 4),
                  Text(
                      'The finder or campus desk compares your answers with the hidden details. You will get a notification.'),
                ],
              ),
            ),
            OutlinedButton(
                onPressed: () => setState(() => _stage = 2),
                child: const Text('Demo: approve this claim')),
          ],
          if (_stage == 2) ...[
            _steps(cs),
            const NoteBanner('Approved. Show this code at the campus desk.',
                lost: false, icon: Icons.check_circle_outline),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Text('482913',
                    style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 34,
                        letterSpacing: 6,
                        fontWeight: FontWeight.w600)),
              ),
            ),
            const AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Handover place',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  SizedBox(height: 4),
                  Text('Campus desk, Admin block, 9:00 am to 4:00 pm (sample)'),
                ],
              ),
            ),
            ListenableBuilder(
              listenable: appState,
              builder: (context, _) => AppCard(
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Share contact details',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text(
                      'Only if both of you are 18+ and both agree.'),
                  value: appState.shareContact,
                  onChanged: (v) =>
                      appState.update(() => appState.shareContact = v),
                ),
              ),
            ),
            FilledButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
                child: const Text('Done')),
          ],
        ],
      ),
    );
  }
}
