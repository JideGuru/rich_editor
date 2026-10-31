# ✨ rich_editor

[![pub package](https://img.shields.io/pub/v/rich_editor.svg)](https://pub.dev/packages/rich_editor)

WYSIWYG editor for Flutter with a rich set of supported formatting options.

Based on https://github.com/dankito/RichTextEditor, but for Flutter.

Supports **Android** and **iOS**. The editor runs in a WebView
([flutter_inappwebview](https://pub.dev/packages/flutter_inappwebview)).

## ✨ Features

- [x] Bold, Italic, Underline, Strike through, Subscript, Superscript
- [x] Heading 1 - 6, Text body, Preformatted, Block quote
- [x] Font (reads all system fonts) (Android only)
- [x] Font Size
- [x] Text Color
- [x] Text Background Color
- [x] Justify Left, Center, Right, Full
- [x] Indent, Outdent
- [x] Undo, Redo
- [x] Unordered List (Bullets)
- [x] Ordered List (Numbers)
- [x] Insert local or remote Image
- [x] Insert video (YouTube links or video files)
- [x] Insert Link
- [x] Insert Checkbox
- [x] Toolbar highlights active formatting
- [x] Change notifications (`onChanged`) and a controller
- [x] Customizable and localizable toolbar
- [x] Pasted HTML is sanitized
- [ ] Search

## 📸 Screenshots

<img src="https://github.com/JideGuru/rich_editor/raw/master/res/1.png" width="400">

## Usage

```dart
final controller = RichEditorController();

// Insert widget into tree
RichEditor(
  controller: controller,
  value: '<p>initial html here</p>',
  editorOptions: const RichEditorOptions(
    placeholder: 'Start typing',
    // backgroundColor: Colors.blueGrey, // Editor's bg color
    // baseTextColor: Colors.white,
    // editor padding
    padding: EdgeInsets.symmetric(horizontal: 5.0),
    // font name
    baseFontFamily: 'sans-serif',
    // Position of the editing bar (BarPosition.top, .bottom or .custom)
    barPosition: BarPosition.top,
  ),
  // Called with the new HTML whenever the user edits
  onChanged: (html) => print(html),
  // Return a link for a picked image: upload it to your storage first,
  // or use a data URI.
  getImageUrl: (image) async {
    final base64 = base64Encode(await image.readAsBytes());
    return 'data:image/png;base64,$base64';
  },
  onUploadError: (error, stackTrace) => print('Upload failed: $error'),
)
```

Dispose the controller when you're done with it.

Get or set the HTML

```dart
String html = await controller.getHtml(); // empty when the editor is empty
await controller.setHtml('<p>Hello</p>');
```

Set Focus and Unfocus

```dart
await controller.focus();
await controller.unFocus();
```

Clear Editor content

```dart
await controller.clear();
```

Run formatting commands

```dart
await controller.executor.setBold();
await controller.executor.insertLink('https://flutter.dev', 'Flutter');
```

`GlobalKey<RichEditorState>` still works too:
`keyEditor.currentState?.getHtml()`.

### Customize the toolbar

Choose and order the buttons, and translate the texts:

```dart
RichEditorOptions(
  toolbarItems: const [
    ToolbarItem.bold,
    ToolbarItem.italic,
    ToolbarItem.link,
    ToolbarItem.bulletList,
  ],
  labels: const RichEditorLabels(bold: 'Fett', italic: 'Kursiv'),
)
```

### Custom Toolbar

Set `barPosition: BarPosition.custom` and build your own toolbar from the
controller. It is a `ValueListenable<RichEditorValue>`, so buttons can show
the formatting at the cursor:

```dart
ValueListenableBuilder<RichEditorValue>(
  valueListenable: controller,
  builder: (context, value, _) => TabButton(
    icon: Icons.format_bold,
    selected: value.isActive(EditorCommand.bold),
    onTap: controller.executor.setBold,
  ),
)
```

See `custom_toolbar_demo.dart` in the example.

### Platform setup

Follow the setup of [flutter_inappwebview](https://inappwebview.dev/docs/intro)
and [image_picker](https://pub.dev/packages/image_picker) (for iOS, the photo
library usage description in `Info.plist`).

On iOS the editor is served from `http://localhost` inside your app. If
App Transport Security blocks it, set `NSAllowsLocalNetworking` to `true`
under `NSAppTransportSecurity` in `Info.plist`.

## License

    Copyright 2021 JideGuru

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
