import 'package:flutter/material.dart';

import 'screens/onboarding.dart';
import 'theme.dart';

void main() => runApp(const FounditApp());

class FounditApp extends StatelessWidget {
  const FounditApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Foundit',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      home: const OnboardingScreen(),
    );
  }
}
