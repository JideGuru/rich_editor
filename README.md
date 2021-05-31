# ✨ rich_editor
[![pub package](https://img.shields.io/pub/v/rich_editor.svg)](https://pub.dartlang.org/packages/rich_editor)
[![pub points](https://badges.bar/rich_editor/pub%20points)](https://pub.dev/packages/rich_editor/score)

WYSIWYG editor for Android and JavaFX with a rich set of supported formatting options.

Based on https://github.com/dankito/RichTextEditor, but for Flutter.

## ✨ Features
- [x] Bold, Italic, Underline, Strike through, Subscript, Superscript
- [x] Heading 1 - 6, Text body, Preformatted, Block quote
- [ ] Font (reads all system fonts)
- [x] Font Size
- [x] Text Color
- [x] Text Background Color
- [x] Highlight text
- [x] Justify Left, Center, Right, Blockquote
- [x] Indent, Outdent
- [x] Undo, Redo
- [x] Unordered List (Bullets)
- [x] Ordered List (Numbers)
- [x] Insert local or remote Image
- [x] Insert Link
- [x] Insert Checkbox
- [ ] Search

## 📸 Screenshots
<img src="res/1.png" width="400">
<img src="res/2.png" width="400">

## Usage
```dart
      RichEditor(
        key: keyEditor,
        value: 'initial html here',
        // You can return a Link (maybe you need to upload the image to your
        // storage before displaying in the editor or you can also use base64
        getImageUrl: (image) {
          String link = 'https://avatars.githubusercontent.com/u/24323581?v=4';
          String base64 = base64Encode(image.readAsBytesSync());
          String base64String = 'data:image/png;base64, $base64';
          return base64String;
        },
      )
```

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