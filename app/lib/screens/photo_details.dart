import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/models.dart';
import '../data/store.dart';
import '../widgets.dart';
import 'matches.dart';

// Screen 5: photo and details (FR-05, FR-06, FR-08)
class PhotoDetailsScreen extends StatefulWidget {
  const PhotoDetailsScreen({super.key, required this.draft, this.desk = false});

  final ReportDraft draft;
  final bool desk;

  @override
  State<PhotoDetailsScreen> createState() => _PhotoDetailsScreenState();
}

class _PhotoDetailsScreenState extends State<PhotoDetailsScreen> {
  bool _consent = true;
  bool _busy = false;
  Uint8List? _photo;
  final _q = [for (var i = 0; i < 3; i++) TextEditingController()];
  final _a = [for (var i = 0; i < 3; i++) TextEditingController()];

  @override
  void dispose() {
    for (final c in [..._q, ..._a]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    try {
      // Small and compressed: the photo is stored inside the report record.
      final x = await ImagePicker().pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 55,
      );
      if (x == null) return;
      final bytes = await x.readAsBytes();
      if (bytes.length > 450 * 1024) {
        if (mounted) toast(context, 'That photo is too large. Try another.');
        return;
      }
      if (mounted) setState(() => _photo = bytes);
    } catch (_) {
      if (mounted) toast(context, 'Could not open the photo. Try again.');
    }
  }

  void _chooseSource() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.of(sheet).pop();
                _pick(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.of(sheet).pop();
                _pick(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final store = AppScope.of(context);
    final details = <QA>[
      for (var i = 0; i < 3; i++)
        if (_q[i].text.trim().isNotEmpty && _a[i].text.trim().isNotEmpty)
          QA(_q[i].text.trim(), _a[i].text.trim()),
    ];
    setState(() => _busy = true);
    try {
      final report = await store.createReport(
        widget.draft,
        photoBase64: _photo == null ? null : base64Encode(_photo!),
        details: details,
      );
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => MatchesScreen(report: report)));
    } on StoreError catch (e) {
      if (mounted) toast(context, e.message);
    } catch (_) {
      if (mounted) toast(context, 'Could not save the report. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final found = widget.draft.type == ReportType.found;
    return Scaffold(
      appBar: AppBar(title: const Text('Photo and details')),
      body: PageBody(
        children: [
          const NoteBanner(
              'Do not photograph CNICs, bank cards or other ID documents. Admins can remove photos.'),
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: _chooseSource,
            child: Container(
              height: 150,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                border: Border.all(color: cs.outline, width: 2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: _photo != null
                  ? Image.memory(_photo!, fit: BoxFit.cover, width: double.infinity)
                  : Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.photo_camera_outlined,
                              color: cs.onSurfaceVariant),
                          const SizedBox(height: 4),
                          const Text('Add one photo (optional)',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                          Text('System picker or camera. Shrunk before saving.',
                              style: TextStyle(
                                  color: cs.onSurfaceVariant, fontSize: 12.5)),
                        ],
                      ),
                    ),
            ),
          ),
          if (_photo != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                  onPressed: () => setState(() => _photo = null),
                  child: const Text('Remove photo')),
            ),
          if (found)
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.lock_outline, color: cs.primary),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('Verification questions',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text(
                      'Write a question only the owner can answer, and the right answer. The answer stays hidden from other users. Add 1 to 3.',
                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                  const SizedBox(height: 10),
                  for (var i = 0; i < 3; i++) ...[
                    TextField(
                        controller: _q[i],
                        decoration: InputDecoration(
                            labelText: 'Question ${i + 1}${i == 0 ? '' : ' (optional)'}',
                            hintText: 'What is stuck inside the front pocket?')),
                    const SizedBox(height: 8),
                    TextField(
                        controller: _a[i],
                        decoration: InputDecoration(
                            labelText: 'Answer ${i + 1}',
                            hintText: 'A blue sticker')),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            )
          else
            Text(
                'Photos help finders recognise your item. Add details such as a sticker or brand in the description.',
                style: TextStyle(color: cs.onSurfaceVariant)),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _consent,
            onChanged: (v) => setState(() => _consent = v ?? false),
            title: Text(
              'CNIC, phone and card numbers in my text are hidden before the report is saved. Matching runs inside the app for now; no text is sent to an AI service.',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
            ),
          ),
          FilledButton(
            onPressed: _consent && !_busy ? _submit : null,
            child: _busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5))
                : const Text('Submit report'),
          ),
        ],
      ),
    );
  }
}
