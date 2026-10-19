import 'package:flutter/foundation.dart';

// Sample data for the UI stage. Replaced by Firestore and the backend later.

enum ReportType { lost, found }

class Report {
  const Report(this.type, this.title, this.zone, this.when,
      {this.colour, this.status});

  final ReportType type;
  final String title;
  final String zone;
  final String when;
  final String? colour;
  final String? status;
}

const campusZones = [
  'Library',
  'Cafeteria',
  'Block A',
  'Block B',
  'Sports ground',
];

const categories = [
  'Bag',
  'Phone',
  'Wallet',
  'Keys',
  'Student card',
  'Charger',
];

const sampleFeed = <Report>[
  Report(ReportType.found, 'Bag', 'Library', 'Mon 3:40 pm', colour: 'Dark'),
  Report(ReportType.lost, 'Black umbrella', 'Block A', 'Mon 1:15 pm'),
  Report(ReportType.found, 'Wallet', 'Cafeteria', 'Sun 5:00 pm',
      colour: 'Brown'),
  Report(ReportType.lost, 'Calculator (Casio)', 'Block B', 'Sat 11:20 am'),
  Report(ReportType.found, 'Keys', 'Sports ground', 'Sat 9:05 am',
      colour: 'Silver'),
];

const myReports = <Report>[
  Report(ReportType.lost, 'Black backpack', 'Library', 'Mon 12:30 pm',
      status: 'Matched'),
  Report(ReportType.lost, 'Phone charger', 'Cafeteria', 'Sun 4:10 pm',
      status: 'Open'),
  Report(ReportType.found, 'Dark school bag', 'Library', 'Mon 3:40 pm',
      status: 'Claim pending'),
];

// Starting weights from the proposal. They are values to tune on a labelled
// test set, not validated results.
const weightText = 0.5;
const weightCategory = 0.2;
const weightPlace = 0.2;
const weightTime = 0.1;

class MatchResult {
  const MatchResult(this.title, this.where, this.text, this.category,
      this.place, this.time, this.reason);

  final String title;
  final String where;
  final double text;
  final double category;
  final double place;
  final double time;
  final String reason;

  double get score =>
      weightText * text +
      weightCategory * category +
      weightPlace * place +
      weightTime * time;
}

const sampleMatches = <MatchResult>[
  MatchResult('Dark school bag', 'Library, Mon 3:40 pm', 0.78, 1.0, 1.0, 1.0,
      'Both are black or dark bags reported near the Library, 3 hours apart.'),
  MatchResult('Grey backpack', 'Library, Sun 6:10 pm', 0.62, 1.0, 1.0, 0.4,
      'Both are backpacks near the Library, about a day apart. Colour differs.'),
  MatchResult('Black sports bag', 'Block A, Mon 5:20 pm', 0.55, 1.0, 0.6, 0.9,
      'Both are black bags on campus, in neighbouring zones.'),
];

class AppState extends ChangeNotifier {
  bool pushOn = true;
  bool shareContact = false;
  String ageBand = '18-24';
  final Set<int> dismissed = {};

  void update(VoidCallback change) {
    change();
    notifyListeners();
  }
}

final appState = AppState();
