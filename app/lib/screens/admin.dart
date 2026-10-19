import 'package:flutter/material.dart';

import '../widgets.dart';

// Admin section (FR-20, FR-25, FR-28). Role-protected in the real app.
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final Map<String, String> _done = {};

  Widget _decision(String key, List<String> actions) {
    final done = _done[key];
    if (done != null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Tag('$done (logged)', kind: TagKind.found),
      );
    }
    return Row(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          i == 0
              ? FilledButton(
                  style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 16)),
                  onPressed: () => setState(() => _done[key] = actions[i]),
                  child: Text(actions[i]),
                )
              : OutlinedButton(
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 16)),
                  onPressed: () => setState(() => _done[key] = actions[i]),
                  child: Text(actions[i]),
                ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Campus admin'),
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 16),
              child: Tag('Admin', kind: TagKind.lost),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Flags'),
              Tab(text: 'Claims'),
              Tab(text: 'Desk'),
              Tab(text: 'Stats'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Flags
            PageBody(children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Post: "Black wallet, reply for number"',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    Text('Reported for personal data',
                        style: TextStyle(color: cs.onSurfaceVariant)),
                    const SizedBox(height: 10),
                    _decision('flag0', const ['Hidden', 'Dismissed']),
                  ],
                ),
              ),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('User: anon_4410',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    Text('Reported 3 times',
                        style: TextStyle(color: cs.onSurfaceVariant)),
                    const SizedBox(height: 10),
                    _decision('flag1', const ['Suspended', 'Dismissed']),
                  ],
                ),
              ),
            ]),
            // Claims
            PageBody(children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(children: [
                      Expanded(
                          child: Text('Claim: dark school bag',
                              style: TextStyle(fontWeight: FontWeight.w700))),
                      AiBadge(),
                    ]),
                    const SizedBox(height: 6),
                    const Row(children: [
                      Tag('Strong hint', kind: TagKind.found),
                      SizedBox(width: 8),
                      Text('Hint only. You decide.'),
                    ]),
                    const SizedBox(height: 6),
                    Text('Hidden detail 1 matches the answer. Detail 2 partly matches.',
                        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                    const SizedBox(height: 10),
                    _decision('claim0', const ['Approved', 'Rejected']),
                  ],
                ),
              ),
            ]),
            // Desk inventory
            PageBody(children: [
              FilledButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Log item form (demo)'))),
                  child: const Text('Log a handed-in item')),
              for (final (name, when) in const [
                ('Umbrella, black', 'Handed in Mon'),
                ('Student card (masked)', 'Handed in Sun'),
                ('Bottle, steel', 'Handed in Fri'),
              ])
                AppCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text(when, style: TextStyle(color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
            ]),
            // Stats
            PageBody(children: [
              Text('Sample numbers for layout only.',
                  style: TextStyle(color: cs.onSurfaceVariant)),
              GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 1.7,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  _Stat('Open reports', '42'),
                  _Stat('Claims pending', '3'),
                  _Stat('Returned this week', '9'),
                  _Stat('Flags open', '2'),
                ],
              ),
              const NoteBanner('Gender stats appear only for groups of 10 or more.',
                  lost: false),
            ]),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
          Text(value,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
