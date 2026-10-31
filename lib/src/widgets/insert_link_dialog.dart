import 'package:flutter/material.dart';
import 'package:rich_editor/src/models/rich_editor_labels.dart';

import 'custom_dialog_template.dart';

/// The result of [InsertLinkDialog]: the entered link, or [remove] when
/// the user removed the link being edited.
typedef InsertLinkResult = ({String url, String label, bool remove});

/// Asks for a link; pops with an [InsertLinkResult] or null.
///
/// With [url], edits that existing link: the label is kept, and the link
/// can be removed.
class InsertLinkDialog extends StatefulWidget {
  final RichEditorLabels labels;

  /// The URL of the link being edited, or null for a new link.
  final String? url;

  const InsertLinkDialog({
    super.key,
    this.labels = const RichEditorLabels(),
    this.url,
  });

  @override
  State<InsertLinkDialog> createState() => _InsertLinkDialogState();
}

class _InsertLinkDialogState extends State<InsertLinkDialog> {
  late final _link = TextEditingController(text: widget.url);
  final _label = TextEditingController();

  bool get _isEditing => widget.url != null;

  @override
  void dispose() {
    _link.dispose();
    _label.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labels = widget.labels;
    return CustomDialogTemplate(
      labels: labels,
      body: [
        Text(labels.link),
        TextField(
          controller: _link,
          keyboardType: TextInputType.url,
          autofocus: true,
          decoration: InputDecoration(hintText: labels.linkHint),
        ),
        if (!_isEditing) ...[
          const SizedBox(height: 20.0),
          Text(labels.linkLabel),
          TextField(
            controller: _label,
            decoration: InputDecoration(hintText: labels.linkLabelHint),
          ),
        ],
      ],
      extraActions: [
        if (_isEditing)
          TextButton(
            onPressed: () => Navigator.pop<InsertLinkResult>(
                context, (url: '', label: '', remove: true)),
            child: Text(labels.removeLink),
          ),
      ],
      onDone: () => Navigator.pop<InsertLinkResult>(
          context, (url: _link.text.trim(), label: _label.text, remove: false)),
      onCancel: () => Navigator.pop(context),
    );
  }
}
