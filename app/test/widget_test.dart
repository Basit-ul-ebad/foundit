import 'package:flutter_test/flutter_test.dart';
import 'package:foundit/data.dart';
import 'package:foundit/main.dart';

void main() {
  testWidgets('app opens on the first onboarding card', (tester) async {
    await tester.pumpWidget(const FounditApp());
    expect(find.text('Post what you lost or found'), findsOneWidget);
  });

  test('sample match scores follow the starting weights', () {
    expect(sampleMatches[0].score, closeTo(0.89, 0.001));
    expect(sampleMatches[1].score, closeTo(0.75, 0.001));
    expect(sampleMatches[2].score, closeTo(0.685, 0.001));
  });
}
