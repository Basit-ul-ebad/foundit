import 'package:flutter/material.dart';

import '../widgets.dart';
import 'login.dart';

// Screen 1: splash and onboarding (FR-01, FR-29)
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _pages = [
    (
      'Post what you lost or found',
      'One report takes about a minute. Add a photo and the place on campus.'
    ),
    (
      'We match by meaning',
      'Black backpack and dark school bag can still find each other, in English or Roman Urdu.'
    ),
    (
      'Claim it privately',
      'Only the real owner can describe the hidden details. Handover is at the campus desk.'
    ),
  ];

  int _page = 0;
  bool _terms = true;

  void _login() => Navigator.of(context)
      .pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final last = _page == _pages.length - 1;
    final (title, body) = _pages[_page];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const FounditMark(size: 34),
                  TextButton(onPressed: _login, child: const Text('Skip')),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                height: 170,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Center(child: FounditMark(size: 84)),
              ),
              const SizedBox(height: 22),
              Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(body, style: TextStyle(color: cs.onSurfaceVariant)),
              const SizedBox(height: 18),
              Row(
                children: [
                  for (var i = 0; i < _pages.length; i++)
                    Expanded(
                      child: Container(
                        height: 6,
                        margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                        decoration: BoxDecoration(
                          color: i <= _page ? cs.primary : cs.outlineVariant,
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                    ),
                ],
              ),
              if (last) ...[
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  initialValue: 'COMSATS University Islamabad (pilot, sample)',
                  decoration: const InputDecoration(labelText: 'Your campus'),
                  items: const [
                    DropdownMenuItem(
                      value: 'COMSATS University Islamabad (pilot, sample)',
                      child: Text('COMSATS University Islamabad (pilot, sample)'),
                    ),
                  ],
                  onChanged: (_) {},
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _terms,
                  onChanged: (v) => setState(() => _terms = v ?? false),
                  title: Text(
                    'I accept the terms. They ban objectionable content, and I can report or block anyone.',
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: last
                    ? (_terms ? _login : null)
                    : () => setState(() => _page++),
                child: Text(last ? 'Get started' : 'Next'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
