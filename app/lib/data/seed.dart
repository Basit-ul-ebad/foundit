import '../core/campus.dart';
import '../core/models.dart';
import 'storage.dart';

// Sample reports from other students, so local mode has something to match.
// Local mode only. Every name and item is made up.
Future<void> seedLocalData(Storage storage) async {
  final now = DateTime.now();
  DateTime ago(Duration d) => now.subtract(d);

  final rows = <(Report, List<String>)>[
    (
      _r('seed-1', 'seed-sara', ReportType.found, 'Dark school bag', 'Left outside the main library.',
          'Bag', 'Black', 'Library', ago(const Duration(hours: 3)),
          questions: ['What is stuck inside the front pocket?', 'What is in the small case?']),
      ['A blue sticker', 'A pencil case with a broken zip'],
    ),
    (
      _r('seed-2', 'seed-omar', ReportType.found, 'Grey backpack', 'Handed in after the evening class.',
          'Bag', 'Grey', 'Library', ago(const Duration(hours: 28)),
          questions: ['What brand is the bag?']),
      ['Jansport'],
    ),
    (
      _r('seed-3', 'seed-hina', ReportType.found, 'Black sports bag', 'Found on a bench near Block A.',
          'Bag', 'Black', 'Block A', ago(const Duration(hours: 5)),
          questions: ['What is written on the bag?']),
      ['Gym 2026'],
    ),
    (
      _r('seed-4', 'seed-bilal', ReportType.found, 'Wallet', 'Found on a cafeteria table.',
          'Wallet', 'Brown', 'Cafeteria', ago(const Duration(hours: 30)),
          questions: ['What card is in the front slot?']),
      ['A blue library card'],
    ),
    (
      _r('seed-5', 'seed-sara', ReportType.found, 'Keys', 'Key ring found on the sports ground.',
          'Keys', 'Grey', 'Sports ground', ago(const Duration(days: 2)),
          questions: ['What is attached to the key ring?']),
      ['A small red tag'],
    ),
    (
      _r('seed-6', 'seed-omar', ReportType.lost, 'Black umbrella', 'Lost after the Block A lecture.',
          'Other', 'Black', 'Block A', ago(const Duration(hours: 6))),
      [],
    ),
    (
      _r('seed-7', 'seed-hina', ReportType.lost, 'Calculator (Casio)', 'Lost in Block B lab.',
          'Other', 'Black', 'Block B', ago(const Duration(days: 2))),
      [],
    ),
  ];

  for (final (r, answers) in rows) {
    await storage.put('reports', r.id, r.toMap());
    if (r.isFound) {
      await storage.put('reportPrivate', r.id,
          {'ownerId': r.userId, 'photo': null, 'answers': answers});
    }
  }
}

Report _r(String id, String user, ReportType type, String title, String desc,
    String category, String colour, String zone, DateTime when,
    {List<String> questions = const []}) {
  return Report(
    id: id,
    userId: user,
    type: type,
    title: title,
    description: desc,
    category: category,
    colour: colour,
    zone: zone,
    eventTime: when,
    createdAt: when,
    lastActivityAt: when,
    questions: questions,
    campusId: kCampusId,
  );
}
