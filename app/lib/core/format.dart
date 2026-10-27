const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String clock(DateTime t) {
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m ${t.hour < 12 ? 'am' : 'pm'}';
}

/// "Mon 3:40 pm" for this week, "12 Oct, 3:40 pm" for older times.
String when(DateTime t) {
  final age = DateTime.now().difference(t);
  if (age.inDays < 6 && !age.isNegative) {
    return '${_days[t.weekday - 1]} ${clock(t)}';
  }
  return '${t.day} ${_months[t.month - 1]}, ${clock(t)}';
}

String dateOnly(DateTime t) => '${t.day} ${_months[t.month - 1]} ${t.year}';

String ago(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'now';
  if (d.inMinutes < 60) return '${d.inMinutes} min';
  if (d.inHours < 24) return '${d.inHours} h';
  return '${d.inDays} d';
}
