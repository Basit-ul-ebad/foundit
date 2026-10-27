import 'package:flutter/material.dart';

import '../widgets.dart';
import 'admin.dart';
import 'onboarding.dart';

// Screen 12: profile and settings (FR-02, FR-22, FR-30)
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _leave(BuildContext context) async {
    await Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      (route) => false,
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final store = AppScope.of(context);
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete account and data?'),
        content: const Text(
            'This cannot be undone. Your reports, claims and notifications are deleted.'),
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
    if (yes != true || !context.mounted) return;
    try {
      await store.deleteAccount();
      if (context.mounted) await _leave(context);
    } catch (e) {
      if (context.mounted) toast(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final store = AppScope.of(context);
    final me = store.user;
    if (me == null) return const Scaffold(body: SizedBox.shrink());
    final initials = me.displayName.isEmpty
        ? '?'
        : me.displayName.substring(0, me.displayName.length > 1 ? 2 : 1).toUpperCase();
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: PageBody(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 27,
                backgroundColor: cs.primaryContainer,
                child: Text(initials,
                    style: TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(me.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text('${me.email}\nCOMSATS Islamabad, age band ${me.ageBand}',
                        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          if (store.localMode)
            const NoteBanner(
                'Local mode: your data stays on this phone. In this mode you are also the campus admin so you can try every step.'),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: me.gender,
                decoration: const InputDecoration(labelText: 'Gender (optional)'),
                items: const [
                  DropdownMenuItem(
                      value: 'Prefer not to say', child: Text('Prefer not to say')),
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                ],
                onChanged: (v) {
                  if (v != null) store.saveProfile(me.copyWith(gender: v));
                },
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
                        selected: me.handoverPref == h,
                        onTap: () =>
                            store.saveProfile(me.copyWith(handoverPref: h))),
                ],
              ),
              const SizedBox(height: 6),
              Text('The second option is shown where the campus offers it.',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.5)),
            ],
          ),
          AppCard(
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Notifications',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('In-app list. Push alerts are added later.'),
              value: me.pushOn,
              onChanged: (v) => store.saveProfile(me.copyWith(pushOn: v)),
            ),
          ),
          AppCard(
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Share contact after approval',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(me.isMinor
                  ? 'Not available for ages 13-17. Handover is at the desk.'
                  : 'Saved for later. Contact sharing is not active yet.'),
              value: me.shareContactOptIn && !me.isMinor,
              onChanged: me.isMinor
                  ? null
                  : (v) => store.saveProfile(me.copyWith(shareContactOptIn: v)),
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
                    onTap: () =>
                        toast(context, '$t page is linked when it is published.'),
                  ),
              ],
            ),
          ),
          if (store.isAdmin)
            OutlinedButton(
              onPressed: () => go(context, const AdminScreen()),
              child: const Text('Open campus admin'),
            ),
          OutlinedButton(
            onPressed: () async {
              await store.signOut();
              if (context.mounted) await _leave(context);
            },
            child: const Text('Sign out'),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
                side: BorderSide(color: cs.onSurface, width: 2)),
            onPressed: () => _confirmDelete(context),
            child: const Text('Delete account'),
          ),
        ],
      ),
    );
  }
}
