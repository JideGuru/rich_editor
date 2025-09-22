import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'custom_dialog_template.dart';

class InsertImageDialog extends StatefulWidget {
  final bool isVideo;

  const InsertImageDialog({super.key, this.isVideo = false});

  @override
  State<InsertImageDialog> createState() => _InsertImageDialogState();
}

class _InsertImageDialogState extends State<InsertImageDialog> {
  TextEditingController link = TextEditingController();

  TextEditingController alt = TextEditingController();
  bool picked = false;

  @override
  Widget build(BuildContext context) {
    return CustomDialogTemplate(
      body: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.isVideo ? 'Video link' : 'Image link'),
            ElevatedButton(
              onPressed: () => getImage(),
              child: const Text('...'),
            ),
          ],
        ),
        TextField(
          controller: link,
          decoration: const InputDecoration(
            hintText: '',
          ),
        ),
        Visibility(
          visible: !widget.isVideo,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20.0),
              const Text('Alt text (optional)'),
              TextField(
                controller: alt,
                decoration: const InputDecoration(
                  hintText: '',
                ),
              ),
            ],
          ),
        ),
      ],
      onDone: () => Navigator.pop(context, [link.text, alt.text, picked]),
      onCancel: () => Navigator.pop(context),
    );
  }

  Future getImage() async {
    final picker = ImagePicker();
    XFile? image;
    if (widget.isVideo) {
      image = await picker.pickVideo(source: ImageSource.gallery);
    } else {
      image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800.0,
        maxHeight: 600.0,
      );
    }

    if (image != null) {
      link.text = image.path;
      picked = true;
    }
  }
}
