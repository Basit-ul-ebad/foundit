import 'package:flutter_test/flutter_test.dart';
import 'package:foundit/core/matching.dart';
import 'package:foundit/core/models.dart';
import 'package:foundit/core/text_tools.dart';
import 'package:foundit/data/store.dart';
import 'package:foundit/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

Report _report(ReportType type, String title, String desc, String category,
    String? colour, String zone, DateTime when) {
  return Report(
    id: title,
    userId: 'u',
    type: type,
    title: title,
    description: desc,
    category: category,
    colour: colour,
    zone: zone,
    eventTime: when,
    createdAt: when,
    lastActivityAt: when,
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('app opens on the first onboarding card', (tester) async {
    final store = (await tester.runAsync(bootstrap))!;
    await tester.pumpWidget(FounditApp(store: store));
    expect(find.text('Post what you lost or found'), findsOneWidget);
  });

  group('text tools', () {
    test('Roman Urdu and English words map to the same tokens', () {
      expect(tokens('kala basta'), tokens('black backpack'));
      expect(tokens('Dark school bag'), containsAll(['black', 'bag']));
    });

    test('CNIC, phone and card numbers are masked', () {
      expect(maskPersonalData('id 35202-1234567-1 ok').text,
          isNot(contains('1234567')));
      expect(maskPersonalData('call 0300-1234567').text,
          isNot(contains('1234567')));
      expect(maskPersonalData('card 4111 1111 1111 1111').text,
          isNot(contains('4111')));
      expect(maskPersonalData('Black backpack near the library').changed,
          isFalse);
    });

    test('word filter blocks listed words only', () {
      expect(containsBlockedWord('you idiot'), isTrue);
      expect(containsBlockedWord('black backpack'), isFalse);
    });
  });

  group('matching', () {
    final t = DateTime(2026, 10, 12, 12, 0);

    test('component scores follow the brief', () {
      expect(categoryScore('Bag', 'Bag'), 1);
      expect(categoryScore('Phone', 'Charger'), 0.5);
      expect(categoryScore('Bag', 'Keys'), 0);
      expect(placeScore('Library', 'Library'), 1);
      expect(placeScore('Library', 'Block A'), 0.6);
      expect(placeScore('Library', 'Sports ground'), 0.3);
      expect(timeScore(t, t.add(const Duration(hours: 3))), 1);
      expect(timeScore(t, t.add(const Duration(days: 14))), 0);
      expect(timeScore(t, t.subtract(const Duration(days: 2))), 0);
      expect(timeScore(t, t.add(const Duration(days: 8))), inInclusiveRange(0.1, 0.9));
    });

    test('the worked example is suggested', () {
      final lost = _report(ReportType.lost, 'Black backpack',
          'Lost near the library yesterday afternoon.', 'Bag', 'Black', 'Library', t);
      final found = _report(ReportType.found, 'Dark school bag',
          'Left outside the main library.', 'Bag', 'Black', 'Library',
          t.add(const Duration(hours: 3)));
      final s = scorePair(lost, found);
      expect(s.total, greaterThanOrEqualTo(matchThreshold));
      expect(s.reason, contains('Library'));
    });

    test('an unrelated item is not suggested', () {
      final lost = _report(ReportType.lost, 'Black backpack', 'Lost near the library.',
          'Bag', 'Black', 'Library', t);
      final found = _report(ReportType.found, 'Keys', 'Key ring found.', 'Keys',
          'Grey', 'Sports ground', t.add(const Duration(hours: 3)));
      expect(scorePair(lost, found).total, lessThan(matchThreshold));
    });
  });

  group('store flow in local mode', () {
    test('report, match, claim, approve and hand over', () async {
      final store = await bootstrap();
      expect(store.localMode, isTrue);
      await store.signUp('ali@example.com', 'password123', '25+');
      expect(store.signedIn, isTrue);

      final report = await store.createReport(ReportDraft(
        type: ReportType.lost,
        title: 'Black backpack',
        description: 'Lost near the library',
        category: 'Bag',
        colour: 'Black',
        zone: 'Library',
        eventTime: DateTime.now().subtract(const Duration(hours: 5)),
      ));
      final list = store.matchesFor(report);
      expect(list, isNotEmpty);
      expect(list.first.score, greaterThanOrEqualTo(matchThreshold));

      final found = store.reportById('seed-1')!;
      await store.submitClaim(found, ['A blue sticker', 'pencil case broken zip'], '');
      final claim = store.myClaimFor('seed-1')!;
      expect(claim.pending, isTrue);

      final secret = await store.privateFor('seed-1');
      final hint = claimHint(
          (secret!['answers'] as List).cast<String>(), claim.answers);
      expect(hint.label, 'Strong hint');

      await store.decideClaim(claim, approve: true);
      final approved = store.myClaimFor('seed-1')!;
      expect(approved.handoverCode, hasLength(6));
      expect(await store.completeClaim(approved, '000000'), isFalse);
      expect(await store.completeClaim(approved, approved.handoverCode!), isTrue);
      expect(store.reportById('seed-1')!.status, statusReturned);
    });

    test('a found report needs a verification question', () async {
      final store = await bootstrap();
      await store.signUp('sara@example.com', 'password123', '25+');
      expect(
        () => store.createReport(ReportDraft(
          type: ReportType.found,
          title: 'Wallet',
          description: 'Found',
          category: 'Wallet',
          zone: 'Library',
          eventTime: DateTime.now(),
        )),
        throwsA(isA<StoreError>()),
      );
    });
  });
}
