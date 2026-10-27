import 'dart:math';

import 'campus.dart';
import 'models.dart';
import 'text_tools.dart';

// Starting weights from the proposal. They are values to tune on a labelled
// test set, not validated results.
const weightText = 0.5;
const weightCategory = 0.2;
const weightPlace = 0.2;
const weightTime = 0.1;

// Suggest a match at or above this score (initial threshold).
const matchThreshold = 0.55;
const maxMatches = 5;
const matchWindowDays = 14;

class Score {
  const Score(this.text, this.category, this.place, this.time, this.reason);

  final double text;
  final double category;
  final double place;
  final double time;
  final String reason;

  double get total =>
      weightText * text +
      weightCategory * category +
      weightPlace * place +
      weightTime * time;
}

String _textOf(Report r) =>
    '${r.title} ${r.description} ${r.colour ?? ''} ${r.category}';

/// Stand-in for the embedding similarity: cosine of the two sets of
/// normalised words (English and Roman Urdu synonyms map to one word).
double textSimilarity(Report a, Report b) {
  final x = tokens(_textOf(a));
  final y = tokens(_textOf(b));
  if (x.isEmpty || y.isEmpty) return 0;
  return x.intersection(y).length / sqrt(x.length * y.length);
}

double categoryScore(String a, String b) {
  if (a == b) return 1;
  if (relatedCategories.contains('$a|$b')) return 0.5;
  return 0;
}

double placeScore(String a, String b) {
  if (a == b) return 1;
  if ((zoneNeighbours[a] ?? const []).contains(b)) return 0.6;
  return 0.3;
}

/// 1 if found within 24 hours of the loss, falling in a straight line to 0 at
/// 14 days. A found time more than a day before the loss scores 0.
double timeScore(DateTime lost, DateTime found) {
  final hours = found.difference(lost).inMinutes / 60.0;
  if (hours < -24) return 0;
  if (hours <= 24) return 1;
  const end = matchWindowDays * 24.0;
  if (hours >= end) return 0;
  return 1 - (hours - 24) / (end - 24);
}

bool inWindow(Report lost, Report found) {
  final hours = found.eventTime.difference(lost.eventTime).inMinutes / 60.0;
  return hours >= -24 && hours <= matchWindowDays * 24.0;
}

String _gap(DateTime lost, DateTime found) {
  final minutes = found.difference(lost).inMinutes.abs();
  if (minutes < 90) return 'about an hour apart';
  final hours = (minutes / 60).round();
  if (hours < 48) return '$hours hours apart';
  return '${(hours / 24).round()} days apart';
}

String _reason(Report lost, Report found, double category, double place) {
  final lostColours = tokens('${lost.colour ?? ''} ${lost.title}')
      .where(colourWords.contains)
      .toSet();
  final foundColours = tokens('${found.colour ?? ''} ${found.title}')
      .where(colourWords.contains)
      .toSet();
  final shared = lostColours.intersection(foundColours);
  final item = found.category.toLowerCase();
  final what = shared.isNotEmpty
      ? 'Both are ${shared.first} ${item}s'
      : (category == 1 ? 'Both are $item reports' : 'The items look related');
  final where = place == 1
      ? 'in the ${found.zone}'
      : place == 0.6
          ? 'in neighbouring zones (${lost.zone} and ${found.zone})'
          : 'on the same campus';
  return '$what $where, ${_gap(lost.eventTime, found.eventTime)}.';
}

Score scorePair(Report lost, Report found) {
  final text = textSimilarity(lost, found);
  final cat = categoryScore(lost.category, found.category);
  final place = placeScore(lost.zone, found.zone);
  final time = timeScore(lost.eventTime, found.eventTime);
  return Score(text, cat, place, time, _reason(lost, found, cat, place));
}

/// Hint for a claim reviewer. The reviewer always decides.
class ClaimHint {
  const ClaimHint(this.label, this.detail);
  final String label;
  final String detail;
}

ClaimHint claimHint(List<String> expected, List<String> given) {
  if (expected.isEmpty) {
    return const ClaimHint('Weak hint', 'No hidden details to compare.');
  }
  var total = 0.0;
  var strong = 0;
  for (var i = 0; i < expected.length; i++) {
    final answer = i < given.length ? given[i] : '';
    final c = containment(expected[i], answer);
    total += c;
    if (c >= 0.6) strong++;
  }
  final avg = total / expected.length;
  final detail = '$strong of ${expected.length} answers match the hidden details.';
  if (avg >= 0.6) return ClaimHint('Strong hint', detail);
  if (avg >= 0.3) return ClaimHint('Partial hint', detail);
  return ClaimHint('Weak hint', detail);
}
