import 'package:flutter/material.dart';

import '../data.dart';
import '../widgets.dart';
import 'admin.dart';
import 'onboarding.dart';

// Screen 12: profile and settings (FR-02, FR-22, FR-30)
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _handover = 'At the desk';

  Future<void> _confirmDelete() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete account and data?'),
        content: const Text(
            'This cannot be undone. Your data is removed within 7 days.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Yes, delete')),
        ],
      ),
    );
    if (yes == true && mounted) {
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: PageBody(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 27,
                backgroundColor: cs.primaryContainer,
                child: Text('AL',
                    style: TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ali (sample)',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  Text('COMSATS Islamabad, age band ${appState.ageBand}',
                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: 'Prefer not to say',
                decoration: const InputDecoration(labelText: 'Gender (optional)'),
                items: const [
                  DropdownMenuItem(
                      value: 'Prefer not to say', child: Text('Prefer not to say')),
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                ],
                onChanged: (_) {},
              ),
              const SizedBox(height: 6),
              Text(
                  'Never shown to others and never changes matches or access. Used only for anonymous stats in groups of 10 or more.',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.5)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Handover preference',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final h in const [
                    'At the desk',
                    'With a female staff member present',
                  ])
                    PickChip(h,
                        selected: _handover == h,
                        onTap: () => setState(() => _handover = h)),
                ],
              ),
              const SizedBox(height: 6),
              Text('The second option is shown where the campus offers it.',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.5)),
            ],
          ),
          ListenableBuilder(
            listenable: appState,
            builder: (context, _) => AppCard(
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Push notifications',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                value: appState.pushOn,
                onChanged: (v) => appState.update(() => appState.pushOn = v),
              ),
            ),
          ),
          AppCard(
            child: Column(
              children: [
                for (final t in const [
                  'Privacy policy',
                  'Terms of use',
                  'Contact support',
                ])
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(t),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$t opens here (demo)'))),
                  ),
              ],
            ),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
                side: BorderSide(color: cs.onSurface, width: 2)),
            onPressed: _confirmDelete,
            child: const Text('Delete account'),
          ),
          Center(
            child: TextButton(
              onPressed: () => go(context, const AdminScreen()),
              child: const Text('Open admin view (demo only)'),
            ),
          ),
        ],
      ),
    );
  }
}
