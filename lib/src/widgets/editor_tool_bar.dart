import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:rich_editor/src/extensions/extensions.dart';
import 'package:rich_editor/src/models/rich_editor_labels.dart';
import 'package:rich_editor/src/models/rich_editor_value.dart';
import 'package:rich_editor/src/models/toolbar_item.dart';
import 'package:rich_editor/src/utils/javascript_executor_base.dart';
import 'package:rich_editor/src/utils/video_url.dart';
import 'package:rich_editor/src/widgets/check_dialog.dart';
import 'package:rich_editor/src/widgets/fonts_dialog.dart';
import 'package:rich_editor/src/widgets/insert_image_dialog.dart';
import 'package:rich_editor/src/widgets/insert_link_dialog.dart';
import 'package:rich_editor/src/widgets/tab_button.dart';

import 'color_picker_dialog.dart';
import 'font_size_dialog.dart';
import 'heading_dialog.dart';

class EditorToolBar extends StatelessWidget {
  final Future<String> Function(File image)? getImageUrl;
  final Future<String> Function(File video)? getVideoUrl;
  final JavascriptExecutorBase javascriptExecutor;
  final bool enableVideo;
  final bool disableVideo;
  final VoidCallback? onDisabledVideoTap;
  final bool isWebViewLoaded;

  /// Buttons to show, in display order.
  final List<ToolbarItem> items;
  final double height;
  final RichEditorLabels labels;

  /// Formatting state at the cursor, used to highlight active buttons.
  final Map<String, CommandState> commandStates;

  /// Called when [getImageUrl] or [getVideoUrl] throws; the media is not
  /// inserted then.
  final void Function(Object error, StackTrace stackTrace)? onUploadError;

  const EditorToolBar({
    super.key,
    this.getImageUrl,
    this.getVideoUrl,
    required this.javascriptExecutor,
    this.enableVideo = true,
    this.disableVideo = false,
    this.onDisabledVideoTap,
    this.isWebViewLoaded = false,
    this.items = ToolbarItem.values,
    this.height = 54.0,
    this.labels = const RichEditorLabels(),
    this.commandStates = const {},
    this.onUploadError,
  });

  @override
  Widget build(BuildContext context) {
    if (!isWebViewLoaded) {
      final theme = Theme.of(context);
      return SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      theme.primaryColor.withValues(alpha: 0.6)),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                labels.loadingEditor,
                style: theme.textTheme.bodySmall?.copyWith(
                  color:
                      theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: height,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final item in items)
            if (_isAvailable(item))
              TabButton(
                tooltip: labels.tooltip(item),
                icon: _icon(item),
                selected: _isSelected(item),
                disabled: !_canUse(item) ||
                    (item == ToolbarItem.video && disableVideo),
                onTap: _canUse(item) ? () => _onTap(context, item) : null,
              ),
        ],
      ),
    );
  }

  bool _isAvailable(ToolbarItem item) {
    return switch (item) {
      ToolbarItem.video => enableVideo,
      // Fonts are read from the Android system font list.
      ToolbarItem.fontFace => Platform.isAndroid,
      _ => true,
    };
  }

  /// False while there is nothing to undo or redo.
  bool _canUse(ToolbarItem item) {
    return switch (item) {
      ToolbarItem.undo => commandStates[EditorCommand.undo]?.enabled ?? true,
      ToolbarItem.redo => commandStates[EditorCommand.redo]?.enabled ?? true,
      _ => true,
    };
  }

  bool _isActive(String command) => commandStates[command]?.active ?? false;

  String _blockFormat() =>
      (commandStates[EditorCommand.formatBlock]?.value ?? '').toLowerCase();

  bool _isSelected(ToolbarItem item) {
    return switch (item) {
      ToolbarItem.bold => _isActive(EditorCommand.bold),
      ToolbarItem.italic => _isActive(EditorCommand.italic),
      ToolbarItem.underline => _isActive(EditorCommand.underline),
      ToolbarItem.strikeThrough => _isActive(EditorCommand.strikeThrough),
      ToolbarItem.superscript => _isActive(EditorCommand.superscript),
      ToolbarItem.subscript => _isActive(EditorCommand.subscript),
      ToolbarItem.blockquote => _blockFormat() == 'blockquote',
      ToolbarItem.textFormat =>
        RegExp(r'^(h[1-6]|pre)$').hasMatch(_blockFormat()),
      ToolbarItem.alignCenter => _isActive(EditorCommand.justifyCenter),
      ToolbarItem.alignRight => _isActive(EditorCommand.justifyRight),
      ToolbarItem.justify => _isActive(EditorCommand.justifyFull),
      ToolbarItem.bulletList => _isActive(EditorCommand.insertUnorderedList),
      ToolbarItem.numberedList => _isActive(EditorCommand.insertOrderedList),
      _ => false,
    };
  }

  IconData _icon(ToolbarItem item) {
    return switch (item) {
      ToolbarItem.bold => Icons.format_bold,
      ToolbarItem.italic => Icons.format_italic,
      ToolbarItem.link => Icons.link,
      ToolbarItem.image => Icons.image,
      ToolbarItem.video => Icons.video_call_sharp,
      ToolbarItem.underline => Icons.format_underline,
      ToolbarItem.strikeThrough => Icons.format_strikethrough,
      ToolbarItem.superscript => Icons.superscript,
      ToolbarItem.subscript => Icons.subscript,
      ToolbarItem.clearFormat => Icons.format_clear,
      ToolbarItem.undo => Icons.undo,
      ToolbarItem.redo => Icons.redo,
      ToolbarItem.blockquote => Icons.format_quote,
      ToolbarItem.textFormat => Icons.text_format,
      ToolbarItem.fontFace => Icons.font_download,
      ToolbarItem.fontSize => Icons.format_size,
      ToolbarItem.textColor => Icons.format_color_text,
      ToolbarItem.backgroundColor => Icons.format_color_fill,
      ToolbarItem.indent => Icons.format_indent_increase,
      ToolbarItem.outdent => Icons.format_indent_decrease,
      ToolbarItem.alignLeft => Icons.format_align_left_outlined,
      ToolbarItem.alignCenter => Icons.format_align_center,
      ToolbarItem.alignRight => Icons.format_align_right,
      ToolbarItem.justify => Icons.format_align_justify,
      ToolbarItem.bulletList => Icons.format_list_bulleted,
      ToolbarItem.numberedList => Icons.format_list_numbered,
      ToolbarItem.checkbox => Icons.check_box_outlined,
    };
  }

  Future<void> _onTap(BuildContext context, ToolbarItem item) async {
    final executor = javascriptExecutor;
    switch (item) {
      case ToolbarItem.bold:
        await executor.setBold();
      case ToolbarItem.italic:
        await executor.setItalic();
      case ToolbarItem.link:
        final link = await showDialog<({String url, String label})>(
          context: context,
          barrierDismissible: false,
          builder: (_) => InsertLinkDialog(labels: labels),
        );
        if (link != null) await executor.insertLink(link.url, link.label);
      case ToolbarItem.image:
        await _insertImage(context);
      case ToolbarItem.video:
        if (disableVideo) {
          onDisabledVideoTap?.call();
        } else {
          await _insertVideo(context);
        }
      case ToolbarItem.underline:
        await executor.setUnderline();
      case ToolbarItem.strikeThrough:
        await executor.setStrikeThrough();
      case ToolbarItem.superscript:
        await executor.setSuperscript();
      case ToolbarItem.subscript:
        await executor.setSubscript();
      case ToolbarItem.clearFormat:
        await executor.removeFormat();
      case ToolbarItem.undo:
        await executor.undo();
      case ToolbarItem.redo:
        await executor.redo();
      case ToolbarItem.blockquote:
        await executor.setBlockQuote();
      case ToolbarItem.textFormat:
        final format = await showDialog<BlockFormat>(
          context: context,
          builder: (_) => HeadingDialog(labels: labels),
        );
        switch (format) {
          case null:
            break;
          case BlockFormat.paragraph:
            await executor.setFormattingToParagraph();
          case BlockFormat.preformat:
            await executor.setPreformat();
          case BlockFormat.blockquote:
            await executor.setBlockQuote();
          default:
            await executor.setHeading(format.index + 1);
        }
      case ToolbarItem.fontFace:
        final font = await showDialog<String>(
          context: context,
          builder: (_) => FontsDialog(labels: labels),
        );
        if (font != null) await executor.setFontName(font);
      case ToolbarItem.fontSize:
        final size = await showDialog<int>(
          context: context,
          builder: (_) => FontSizeDialog(labels: labels),
        );
        if (size != null) await executor.setFontSize(size);
      case ToolbarItem.textColor:
        final color = await _pickColor(context, EditorCommand.foreColor);
        if (color != null) await executor.setTextColor(color);
      case ToolbarItem.backgroundColor:
        final color = await _pickColor(context, EditorCommand.backColor);
        if (color != null) await executor.setTextBackgroundColor(color);
      case ToolbarItem.indent:
        await executor.setIndent();
      case ToolbarItem.outdent:
        await executor.setOutdent();
      case ToolbarItem.alignLeft:
        await executor.setJustifyLeft();
      case ToolbarItem.alignCenter:
        await executor.setJustifyCenter();
      case ToolbarItem.alignRight:
        await executor.setJustifyRight();
      case ToolbarItem.justify:
        await executor.setJustifyFull();
      case ToolbarItem.bulletList:
        await executor.insertBulletList();
      case ToolbarItem.numberedList:
        await executor.insertNumberedList();
      case ToolbarItem.checkbox:
        final text = await showDialog<String>(
          context: context,
          builder: (_) => CheckDialog(labels: labels),
        );
        if (text != null) await executor.insertCheckbox(text);
    }
  }

  /// Opens the color picker at the color currently applied by [command].
  Future<Color?> _pickColor(BuildContext context, String command) {
    final current = parseCssColor(commandStates[command]?.value ?? '');
    return showDialog<Color>(
      context: context,
      builder: (_) => ColorPickerDialog(
        color: current == null || current.a == 0 ? Colors.blue : current,
        labels: labels,
      ),
    );
  }

  Future<void> _insertImage(BuildContext context) async {
    final result = await showDialog<InsertMediaResult>(
      context: context,
      builder: (_) => InsertImageDialog(labels: labels),
    );
    if (result == null || result.url.isEmpty) return;

    final url = await _upload(result, getImageUrl ?? _imageDataUrl);
    if (url != null) await javascriptExecutor.insertImage(url, alt: result.alt);
  }

  Future<void> _insertVideo(BuildContext context) async {
    final result = await showDialog<InsertMediaResult>(
      context: context,
      builder: (_) => InsertImageDialog(
        isVideo: true,
        labels: labels,
        // the editor page can't play videos from the device
        canPick: getVideoUrl != null,
      ),
    );
    if (result == null || result.url.isEmpty) return;

    final url = await _upload(result, getVideoUrl);
    if (url == null) return;
    // Links that aren't YouTube videos are played in a <video> element.
    await javascriptExecutor.insertVideo(
      url,
      fromDevice: result.picked || youtubeEmbedUrl(url) == null,
    );
  }

  /// Embeds a picked image without [getImageUrl]: the editor page can't
  /// load device files, and the HTML stays usable on other devices.
  static Future<String> _imageDataUrl(File image) async {
    final extension = image.path.split('.').last.toLowerCase();
    final type = switch (extension) {
      'png' || 'gif' || 'webp' || 'bmp' => extension,
      _ => 'jpeg',
    };
    return 'data:image/$type;base64,${base64Encode(await image.readAsBytes())}';
  }

  /// Uploads picked media with [upload], if given. Returns the URL to
  /// insert, or null if the upload failed.
  Future<String?> _upload(
    InsertMediaResult result,
    Future<String> Function(File file)? upload,
  ) async {
    if (!result.picked || upload == null) return result.url;
    try {
      return await upload(File(result.url));
    } catch (error, stackTrace) {
      onUploadError?.call(error, stackTrace);
      return null;
    }
  }
}
