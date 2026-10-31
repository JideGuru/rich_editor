import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rich_editor/src/models/rich_editor_labels.dart';

import 'custom_dialog_template.dart';

/// The result of [InsertImageDialog].
typedef InsertMediaResult = ({String url, String alt, bool picked});

/// Asks for an image or video link, or picks one from the gallery.
///
/// Pops with an [InsertMediaResult] whose `picked` is true when the URL is
/// the path of a file picked from the gallery, or null.
class InsertImageDialog extends StatefulWidget {
  final bool isVideo;
  final RichEditorLabels labels;

  const InsertImageDialog({
    super.key,
    this.isVideo = false,
    this.labels = const RichEditorLabels(),
  });

  @override
  State<InsertImageDialog> createState() => _InsertImageDialogState();
}

class _InsertImageDialogState extends State<InsertImageDialog> {
  final _link = TextEditingController();
  final _alt = TextEditingController();
  String? _pickedPath;

  @override
  void dispose() {
    _link.dispose();
    _alt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labels = widget.labels;
    return CustomDialogTemplate(
      labels: labels,
      body: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.isVideo ? labels.videoLink : labels.imageLink),
            IconButton(
              tooltip: labels.pickFromGallery,
              onPressed: _pick,
              icon: Icon(widget.isVideo ? Icons.video_library : Icons.photo),
            ),
          ],
        ),
        TextField(
          controller: _link,
          keyboardType: TextInputType.url,
        ),
        if (!widget.isVideo) ...[
          const SizedBox(height: 20.0),
          Text(labels.altText),
          TextField(controller: _alt),
        ],
      ],
      onDone: () {
        final url = _link.text.trim();
        Navigator.pop<InsertMediaResult>(
          context,
          (url: url, alt: _alt.text, picked: url == _pickedPath),
        );
      },
      onCancel: () => Navigator.pop(context),
    );
  }

  Future<void> _pick() async {
    final picker = ImagePicker();
    final XFile? file;
    if (widget.isVideo) {
      file = await picker.pickVideo(source: ImageSource.gallery);
    } else {
      file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800.0,
        maxHeight: 600.0,
      );
    }

    if (file != null && mounted) {
      _pickedPath = file.path;
      _link.text = file.path;
    }
  }
}
