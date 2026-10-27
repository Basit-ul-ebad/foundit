import 'package:flutter/material.dart';

import 'core/format.dart' as fmt;
import 'core/models.dart';
import 'data/store.dart';

Future<T?> go<T>(BuildContext context, Widget page) =>
    Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => page));

List<Widget> spaced(List<Widget> items, {double gap = 14}) {
  final out = <Widget>[];
  for (var i = 0; i < items.length; i++) {
    if (i > 0) out.add(SizedBox(height: gap));
    out.add(items[i]);
  }
  return out;
}

class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.children, this.gap = 14});

  final List<Widget> children;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: spaced(children, gap: gap),
    );
  }
}

class FounditMark extends StatelessWidget {
  const FounditMark({super.key, this.size = 28});

  final double size;

  @override
  Widget build(BuildContext context) {
    // A baggage tag, the lost-property symbol.
    return Icon(Icons.sell,
        size: size, color: Theme.of(context).colorScheme.primary);
  }
}

enum TagKind { lost, found, neutral }

class Tag extends StatelessWidget {
  const Tag(this.label, {super.key, this.kind = TagKind.neutral});

  final String label;
  final TagKind kind;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final Color bg;
    final Color fg;
    switch (kind) {
      case TagKind.lost:
        bg = cs.secondaryContainer;
        fg = cs.secondary;
      case TagKind.found:
        bg = cs.primaryContainer;
        fg = cs.primary;
      case TagKind.neutral:
        bg = cs.surfaceContainerHighest;
        fg = cs.onSurface;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style:
              TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

TagKind kindOf(ReportType type) =>
    type == ReportType.lost ? TagKind.lost : TagKind.found;

String labelOf(ReportType type) => type == ReportType.lost ? 'Lost' : 'Found';

// Marks text written by the app's own rules, not by a person.
class AiBadge extends StatelessWidget {
  const AiBadge({super.key, this.label = 'Auto'});

  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        border: Border.all(color: cs.outline),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: cs.onSurfaceVariant)),
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.onTap, this.color});

  final Widget child;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: color ?? cs.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(12), child: child),
      ),
    );
  }
}

class NoteBanner extends StatelessWidget {
  const NoteBanner(this.text,
      {super.key, this.lost = true, this.icon = Icons.info_outline});

  final String text;
  final bool lost;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = lost ? cs.secondaryContainer : cs.primaryContainer;
    final fg = lost ? cs.secondary : cs.primary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: fg),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: TextStyle(color: cs.onSurface, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class ScoreBar extends StatelessWidget {
  const ScoreBar(this.value, {super.key});

  final double value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: LinearProgressIndicator(
        value: value,
        minHeight: 8,
        color: cs.primary,
        backgroundColor: cs.surfaceContainerHighest,
      ),
    );
  }
}

// Selected chip is filled with ink, so selection never borrows teal or amber.
class PickChip extends StatelessWidget {
  const PickChip(this.label,
      {super.key, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        borderRadius: BorderRadius.circular(99),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 40),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected ? cs.onSurface : cs.surface,
            border: Border.all(color: selected ? cs.onSurface : cs.outline),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: selected ? cs.surface : cs.onSurface)),
        ),
      ),
    );
  }
}

class KeyValue extends StatelessWidget {
  const KeyValue(this.label, this.value, {super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: cs.onSurfaceVariant)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(text,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        ?trailing,
      ],
    );
  }
}

class ReportCard extends StatelessWidget {
  const ReportCard(this.report, {super.key, this.onTap, this.status});

  final Report report;
  final VoidCallback? onTap;
  final String? status;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final parts = [
      if (report.colour != null && report.colour!.isNotEmpty)
        'Colour: ${report.colour}',
      report.zone,
      fmt.when(report.eventTime),
    ];
    final label = status;
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(report.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
              ),
              Tag(labelOf(report.type), kind: kindOf(report.type)),
            ],
          ),
          const SizedBox(height: 4),
          Text(parts.join('  ·  '),
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
          if (label != null) ...[
            const SizedBox(height: 8),
            Tag(label,
                kind: label == 'Matched' || label == 'Returned'
                    ? TagKind.found
                    : TagKind.lost),
          ],
        ],
      ),
    );
  }
}

/// Asks for a reason, then calls [onReason]. The report goes to campus admins.
Future<void> showReportSheet(
  BuildContext context, {
  String what = 'post',
  required Future<void> Function(String reason) onReason,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Report this $what',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            for (final reason in const [
              'Offensive or unsafe',
              'Shows personal data',
              'Wrong or misleading',
            ])
              ListTile(
                title: Text(reason),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await onReason(reason);
                    messenger.showSnackBar(const SnackBar(
                        content: Text('Thanks. A campus admin will review it.')));
                  } catch (_) {
                    messenger.showSnackBar(const SnackBar(
                        content: Text('Could not send the report. Try again.')));
                  }
                },
              ),
          ],
        ),
      ),
    ),
  );
}

/// Shows a short message at the bottom of the screen.
void toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Gives screens access to the store.
class AppScope extends InheritedNotifier<AppStore> {
  const AppScope({super.key, required AppStore store, required super.child})
      : super(notifier: store);

  static AppStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// For initState, where listening to changes is not allowed.
  static AppStore read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
