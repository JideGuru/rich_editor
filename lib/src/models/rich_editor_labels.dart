import 'toolbar_item.dart';

/// User-facing text of the editor's toolbar and dialogs.
///
/// Defaults are English; pass a translated instance to
/// [RichEditorOptions.labels] to localize the editor.
class RichEditorLabels {
  const RichEditorLabels({
    this.bold = 'Bold',
    this.italic = 'Italic',
    this.insertLink = 'Insert Link',
    this.insertImage = 'Insert Image',
    this.insertVideo = 'Insert video',
    this.underline = 'Underline',
    this.strikeThrough = 'Strike through',
    this.superscript = 'Superscript',
    this.subscript = 'Subscript',
    this.clearFormat = 'Clear format',
    this.undo = 'Undo',
    this.redo = 'Redo',
    this.blockquote = 'Blockquote',
    this.textFormat = 'Font format',
    this.fontFace = 'Font face',
    this.fontSize = 'Font Size',
    this.textColor = 'Text Color',
    this.backgroundColor = 'Background Color',
    this.indent = 'Increase Indent',
    this.outdent = 'Decrease Indent',
    this.alignLeft = 'Align Left',
    this.alignCenter = 'Align Center',
    this.alignRight = 'Align Right',
    this.justify = 'Justify',
    this.bulletList = 'Bullet List',
    this.numberedList = 'Numbered List',
    this.checkbox = 'Checkbox',
    this.done = 'Done',
    this.cancel = 'Cancel',
    this.link = 'Link',
    this.linkHint = 'type link here',
    this.linkLabel = 'Label',
    this.linkLabelHint = 'type label text here',
    this.imageLink = 'Image link',
    this.videoLink = 'Video link',
    this.pickFromGallery = 'Pick from gallery',
    this.altText = 'Alt text (optional)',
    this.checkboxTitle = 'Checkbox title',
    this.heading = 'Heading',
    this.paragraph = 'Text body',
    this.preformat = 'Preformat',
    this.quote = 'Quote',
    this.fontSizes = const [
      'Teeny',
      'Very small',
      'Small',
      'Medium',
      'Large',
      'Very large',
      'Huge',
    ],
    this.noFonts = 'No system fonts found',
    this.loadingEditor = 'Loading editor...',
    this.uploading = 'Uploading...',
  });

  final String bold;
  final String italic;
  final String insertLink;
  final String insertImage;
  final String insertVideo;
  final String underline;
  final String strikeThrough;
  final String superscript;
  final String subscript;
  final String clearFormat;
  final String undo;
  final String redo;
  final String blockquote;
  final String textFormat;
  final String fontFace;
  final String fontSize;
  final String textColor;
  final String backgroundColor;
  final String indent;
  final String outdent;
  final String alignLeft;
  final String alignCenter;
  final String alignRight;
  final String justify;
  final String bulletList;
  final String numberedList;
  final String checkbox;
  final String done;
  final String cancel;
  final String link;
  final String linkHint;
  final String linkLabel;
  final String linkLabelHint;
  final String imageLink;
  final String videoLink;
  final String pickFromGallery;
  final String altText;
  final String checkboxTitle;

  /// Prefix of the heading names, e.g. "Heading" becomes "Heading 1".
  final String heading;
  final String paragraph;
  final String preformat;
  final String quote;

  /// Names of the seven font sizes, smallest first. Must have 7 entries.
  final List<String> fontSizes;
  final String noFonts;
  final String loadingEditor;
  final String uploading;

  /// The tooltip of a toolbar button.
  String tooltip(ToolbarItem item) {
    return switch (item) {
      ToolbarItem.bold => bold,
      ToolbarItem.italic => italic,
      ToolbarItem.link => insertLink,
      ToolbarItem.image => insertImage,
      ToolbarItem.video => insertVideo,
      ToolbarItem.underline => underline,
      ToolbarItem.strikeThrough => strikeThrough,
      ToolbarItem.superscript => superscript,
      ToolbarItem.subscript => subscript,
      ToolbarItem.clearFormat => clearFormat,
      ToolbarItem.undo => undo,
      ToolbarItem.redo => redo,
      ToolbarItem.blockquote => blockquote,
      ToolbarItem.textFormat => textFormat,
      ToolbarItem.fontFace => fontFace,
      ToolbarItem.fontSize => fontSize,
      ToolbarItem.textColor => textColor,
      ToolbarItem.backgroundColor => backgroundColor,
      ToolbarItem.indent => indent,
      ToolbarItem.outdent => outdent,
      ToolbarItem.alignLeft => alignLeft,
      ToolbarItem.alignCenter => alignCenter,
      ToolbarItem.alignRight => alignRight,
      ToolbarItem.justify => justify,
      ToolbarItem.bulletList => bulletList,
      ToolbarItem.numberedList => numberedList,
      ToolbarItem.checkbox => checkbox,
    };
  }
}
