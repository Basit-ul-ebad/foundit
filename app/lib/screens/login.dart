import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/campus.dart';
import '../data/storage.dart';
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
  bool _busy = false;
  String? _age;
  String? _error;
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final store = AppScope.of(context);
    final email = _email.text.trim();
    final password = _password.text;
    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    if (password.length < 8) {
      setState(() => _error = 'Use a password with at least 8 characters.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_signUp) {
        await store.signUp(email, password, _age);
      } else {
        await store.signIn(email, password);
      }
      if (!mounted) return;
      await Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AppShell()), (r) => false);
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Something went wrong. Check your connection and try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _guest() async {
    final store = AppScope.of(context);
    await store.enterGuest();
    if (!mounted) return;
    await go(context, const BrowseScreen(guest: true));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final store = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome to Foundit')),
      body: PageBody(
        children: [
          if (store.localMode)
            const NoteBanner(
                'Local mode: accounts and reports stay on this phone only. Firebase is not connected in this build.'),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Sign in')),
              ButtonSegment(value: true, label: Text('Sign up')),
            ],
            selected: {_signUp},
            onSelectionChanged: (s) => setState(() {
              _signUp = s.first;
              _error = null;
            }),
          ),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: const InputDecoration(
                labelText: 'Email', hintText: 'you@university.edu.pk'),
          ),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(
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
                    for (final a in ageBands)
                      PickChip(a,
                          selected: _age == a,
                          onTap: () =>
                              setState(() => _age = _age == a ? null : a)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Skip it and the 13-17 safety defaults apply. We never ask for a date of birth.',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.5),
                ),
              ],
            ),
          if (_error != null)
            Text(_error!,
                style: TextStyle(
                    color: cs.secondary, fontWeight: FontWeight.w600)),
          FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5))
                  : Text(_signUp ? 'Create account' : 'Sign in')),
          Center(
              child:
                  Text('or', style: TextStyle(color: cs.onSurfaceVariant))),
          OutlinedButton(
              onPressed: () =>
                  toast(context, 'Google sign-in is added in the next update.'),
              child: const Text('Continue with Google')),
          if (defaultTargetPlatform == TargetPlatform.iOS)
            OutlinedButton(
                onPressed: () => toast(
                    context, 'Sign in with Apple is added with the iOS build.'),
                child: const Text('Sign in with Apple')),
          Center(
            child: TextButton(
              onPressed: _busy ? null : _guest,
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
