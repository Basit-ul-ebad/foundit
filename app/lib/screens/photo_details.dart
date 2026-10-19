import 'package:flutter/material.dart';

import '../data.dart';
import '../widgets.dart';
import 'matches.dart';

// Screen 5: photo and details (FR-05, FR-06, FR-08)
class PhotoDetailsScreen extends StatefulWidget {
  const PhotoDetailsScreen({super.key, required this.type});

  final ReportType type;

  @override
  State<PhotoDetailsScreen> createState() => _PhotoDetailsScreenState();
}

class _PhotoDetailsScreenState extends State<PhotoDetailsScreen> {
  bool _consent = true;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final found = widget.type == ReportType.found;
    return Scaffold(
      appBar: AppBar(title: const Text('Photo and details')),
      body: PageBody(
        children: [
          const NoteBanner(
              'Do not photograph CNICs, bank cards or other ID documents. Admins can remove photos.'),
          Container(
            height: 130,
            decoration: BoxDecoration(
              border: Border.all(color: cs.outline, width: 2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.photo_camera_outlined, color: cs.onSurfaceVariant),
                  const SizedBox(height: 4),
                  const Text('Add one photo',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  Text('System picker or camera. Compressed before upload.',
                      style:
                          TextStyle(color: cs.onSurfaceVariant, fontSize: 12.5)),
                ],
              ),
            ),
          ),
          if (found)
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.lock_outline, color: cs.primary),
                    const SizedBox(width: 8),
                    const Text('Private verification details',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 4),
                  Text(
                      'Only you and campus admins can see these. The owner has to describe them to claim the item.',
                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                  const SizedBox(height: 10),
                  const TextField(
                      decoration: InputDecoration(
                          labelText: 'Detail 1',
                          hintText: 'A blue sticker inside the front pocket')),
                  const SizedBox(height: 10),
                  const TextField(
                      decoration: InputDecoration(
                          labelText: 'Detail 2',
                          hintText: 'Pencil case with a broken zip')),
                  const SizedBox(height: 10),
                  const TextField(
                      decoration:
                          InputDecoration(labelText: 'Detail 3 (optional)')),
                ],
              ),
            )
          else
            Text(
                'Photos help owners and finders recognise items. Found-item photos stay private until a claim is approved.',
                style: TextStyle(color: cs.onSurfaceVariant)),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _consent,
            onChanged: (v) => setState(() => _consent = v ?? false),
            title: Text(
              'Masked report text is processed by an AI service to find matches. CNIC, phone and card numbers are hidden first.',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
            ),
          ),
          FilledButton(
            onPressed: _consent ? () => go(context, const MatchesScreen()) : null,
            child: const Text('Submit report'),
          ),
        ],
      ),
    );
  }
}
