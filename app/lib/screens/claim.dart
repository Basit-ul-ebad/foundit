import 'package:flutter/material.dart';

import '../core/campus.dart';
import '../core/models.dart';
import '../data/store.dart';
import '../widgets.dart';

// Screen 10: ownership claim (FR-19 to FR-23)
class ClaimScreen extends StatefulWidget {
  const ClaimScreen({super.key, required this.report});

  final Report report;

  @override
  State<ClaimScreen> createState() => _ClaimScreenState();
}

class _ClaimScreenState extends State<ClaimScreen> {
  late final List<TextEditingController> _answers = [
    for (final _ in widget.report.questions) TextEditingController(),
  ];
  final _note = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    for (final c in _answers) {
      c.dispose();
    }
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final store = AppScope.of(context);
    setState(() => _busy = true);
    try {
      await store.submitClaim(
          widget.report, [for (final c in _answers) c.text], _note.text);
    } on StoreError catch (e) {
      if (mounted) toast(context, e.message);
    } catch (_) {
      if (mounted) toast(context, 'Could not submit the claim. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _steps(ColorScheme cs, int stage) {
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
                    color: i <= stage ? cs.primary : cs.outlineVariant,
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
    final store = AppScope.of(context);
    final claim = store.myClaimFor(widget.report.id);
    return Scaffold(
      appBar: AppBar(title: const Text('Claim this item')),
      body: PageBody(
        children: [
          if (claim == null) ..._form(cs),
          if (claim != null && claim.pending) ...[
            _steps(cs, 0),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Waiting for review',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(claim.requiresAdmin
                      ? 'A campus admin reviews this claim because a user under 18 is involved. You will get a notification.'
                      : 'The finder or campus desk compares your answers with the hidden details. You will get a notification.'),
                ],
              ),
            ),
            OutlinedButton(
                onPressed: () async {
                  final nav = Navigator.of(context);
                  await store.withdrawClaim(claim);
                  nav.pop();
                },
                child: const Text('Withdraw claim')),
          ],
          if (claim != null && claim.approved) ...[
            _steps(cs, 1),
            const NoteBanner('Approved. Show this code at the campus desk.',
                lost: false, icon: Icons.check_circle_outline),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(claim.handoverCode ?? '------',
                    style: const TextStyle(
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
                  Text(deskInfo),
                ],
              ),
            ),
            Text(
                'The finder or desk types this code to mark the item as returned. Contact details are not shared in this version.',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.5)),
          ],
          if (claim != null && claim.status == 'completed') ...[
            _steps(cs, 2),
            const NoteBanner('Handed over. The item is marked as returned.',
                lost: false, icon: Icons.check_circle_outline),
          ],
          if (claim != null && claim.status == 'rejected')
            const NoteBanner(
                'This claim was not approved. If you think this is a mistake, visit the campus desk.'),
          FilledButton(
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
              child: const Text('Done')),
        ],
      ),
    );
  }

  List<Widget> _form(ColorScheme cs) {
    return [
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Verification questions',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Written by the finder. Only the real owner should know the answers.',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
          ],
        ),
      ),
      for (var i = 0; i < _answers.length; i++)
        TextField(
          controller: _answers[i],
          decoration: InputDecoration(labelText: widget.report.questions[i]),
        ),
      if (_answers.isEmpty)
        const NoteBanner('This item has no questions. Ask the campus desk.'),
      TextField(
          controller: _note,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
              labelText: 'Note (optional)',
              hintText: 'Anything else that proves it is yours')),
      Text('Limits: 3 pending claims, 1 per item.',
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.5)),
      FilledButton(
          onPressed: _busy || _answers.isEmpty ? null : _submit,
          child: _busy
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5))
              : const Text('Submit claim')),
    ];
  }
}
