import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data.dart';
import '../widgets.dart';
import 'browse.dart';
import 'shell.dart';

// Screen 2: login and sign-up (FR-01, FR-02, FR-03)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _signUp = false;
  String _age = '18-24';

  void _enter() {
    appState.ageBand = _age;
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (_) => const AppShell()));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome to Foundit')),
      body: PageBody(
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Sign in')),
              ButtonSegment(value: true, label: Text('Sign up')),
            ],
            selected: {_signUp},
            onSelectionChanged: (s) => setState(() => _signUp = s.first),
          ),
          const TextField(
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
                labelText: 'Email', hintText: 'you@university.edu.pk'),
          ),
          const TextField(
            obscureText: true,
            decoration: InputDecoration(
                labelText: 'Password', hintText: 'At least 8 characters'),
          ),
          if (_signUp)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Age band',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final a in const ['13-17', '18-24', '25+'])
                      PickChip(a,
                          selected: _age == a,
                          onTap: () => setState(() => _age = a)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Skip it and the 13-17 safety defaults apply. We never ask for a date of birth.',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.5),
                ),
              ],
            ),
          FilledButton(
              onPressed: _enter,
              child: Text(_signUp ? 'Create account' : 'Sign in')),
          Center(
              child:
                  Text('or', style: TextStyle(color: cs.onSurfaceVariant))),
          OutlinedButton(
              onPressed: _enter, child: const Text('Continue with Google')),
          if (defaultTargetPlatform == TargetPlatform.iOS)
            OutlinedButton(
                onPressed: _enter,
                child: const Text('Sign in with Apple')),
          Center(
            child: TextButton(
              onPressed: () => go(context, const BrowseScreen(guest: true)),
              child: const Text('Browse as guest'),
            ),
          ),
          Text(
            'Guests can browse one campus but cannot post, claim or see matches.',
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}
