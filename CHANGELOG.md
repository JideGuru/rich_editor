## Unreleased

### Added
* `onChanged` callback: the editor now reports every content change to Flutter.
* `RichEditorController`: read and set HTML, focus, clear and run commands
  (`controller.executor`) without a `GlobalKey`. It is a `ValueListenable` of
  `RichEditorValue`, which carries the HTML and the formatting at the cursor.
* The toolbar highlights active formatting (bold, italic, lists, alignment, headings, ...).
* `RichEditorOptions.toolbarItems` chooses and orders the toolbar buttons,
  `toolbarHeight` sets its height, and `RichEditor.toolbarBuilder` replaces it.
* `RichEditorOptions.labels` (`RichEditorLabels`) localizes every toolbar and dialog text.
* `RichEditor.onUploadError` is called when `getImageUrl` / `getVideoUrl` throws;
  nothing is inserted then.
* The placeholder is shown while the editor is empty.
* `RichEditor.readOnly` shows the content without the toolbar and without letting
  the user edit it; `RichEditor.autofocus` focuses the editor once it has loaded.
* Pasted and dropped images are uploaded with `getImageUrl` (or inserted as `data:`
  URLs without it), at the caret and without distortion.
* Undo and Redo are greyed out when there is nothing to undo or redo.
* Links can be edited and removed: the Link button is highlighted while the caret is
  in a link and opens it for editing. `executor.editLink` / `removeLink`, and
  `EditorCommand.link` reports the link at the caret.
* `controller.getText()` returns the content as plain text.
* The editor follows the app's light or dark theme unless `backgroundColor` /
  `baseTextColor` are set, and colors links, checkboxes and the caret to match.
* The editor page has a Content-Security-Policy that only runs the editor's own
  scripts, so scripts and inline handlers in the content never run.
* Colors keep their transparency; the color picker opens at the color under the cursor
  and has a Cancel button.

### Fixed
* On iOS, inserted links, images and the text around them no longer get a
  `style="-webkit-text-size-adjust: 100%;"` attribute in the HTML.
* On Android, links and images inserted at the end of a paragraph no longer get the
  editor's background color as a `style` attribute in the HTML.
* The Quote button removes the quote when the caret is in one, instead of nesting
  another quote inside it.
* Text containing `+` (e.g. "C++") lost characters when set with `setHtml`.
* `getHtml` no longer decodes HTML entities, which turned typed text like `<b>` into real markup.
* Strings with quotes or backslashes (fonts, placeholder, checkbox text, `insertHtml`, ...)
  no longer break or inject JavaScript; every argument is passed with `jsonEncode`.
* Links, checkboxes, images and videos are built with the DOM instead of string
  concatenation; `javascript:` and other unsafe URLs are rejected.
* Checkboxes no longer store an inline `onclick` handler in the HTML, and their label text is shown.
* Pasted HTML is sanitized (scripts, event handlers, unsafe URLs and Word markup removed);
  `setHtml`/`insertHtml` strip scripts and event handlers.
* The editor HTML no longer contains zero-width spaces, and is empty when the editor is.
* `isEmpty()` works for any empty content, not one exact string.
* Backspace could not delete the last character.
* Deleting everything left the editor without a paragraph to type into.
* Crash in the paste handler when pasted text was inserted late.
* YouTube links in any form (youtu.be, shorts, live, extra parameters) are embedded;
  other video links play in a `<video>` element.
* Background colors were applied without CSS (`styleWithCSS` was never enabled).
* The Android font list skipped aliases, mis-parsed one fallback font and could crash;
  it is now read once, off the UI thread.
* Image resizing stores numeric sizes, rotation applies per image, and the broken
  drag-to-move was removed.
* A `//` comment in style.css disabled the `sup` rule.
* `RichEditor()` crashed without `editorOptions`, and on macOS when disposed.
* iOS: the asset server could be requested before it started, never finished starting
  when its port was taken, used a fixed port shared by all editors, and served every app asset.
  It now uses a free port and only serves the editor files.
* Changing `value` or `editorOptions` after the first build had no effect.
* `focus()` opened the keyboard for Flutter's own text input, which had no text field,
  instead of the editor. This is behind reports of the cursor disappearing (#13), Samsung
  keyboards failing with Vietnamese (#15) and crashes in `onCreateInputConnection` (#22).
  The keyboard is now opened for the editor itself, on Android once the user has
  interacted with the editor.
* The editor no longer changes the page while the keyboard composes a word, which
  cancelled composing input (Vietnamese, Chinese, Japanese, swipe typing).
* Dragging across an image didn't scroll the editor. Images now take touches for
  resizing and rotating only once tapped, and are outlined then.
* Android: YouTube embeds failed with "Error 153", because the editor page had no
  origin. Android now serves the editor under `https://appassets.androidplatform.net`
  with `WebViewAssetLoader`, instead of loading it from `file:///android_asset`.
* Typing in large documents sent the whole HTML to Flutter on every keystroke and
  selection change; reports are now batched (at most every 50 ms, less often for
  large documents).
* `setState` after dispose when an upload finished late.
* Dialog text fields leaked their controllers.
* The editor no longer forces mixed content on, and only logs WebView console
  messages in debug builds.

### Breaking
* Without `getImageUrl`, picked images are embedded as `data:` URLs instead of being
  inserted by their file path, which the editor page can no longer load (and never
  could on iOS). Picking videos needs `getVideoUrl`; without it the video dialog
  only takes links.
* `RichEditor.editorOptions` and `RichEditor.disableVideo` are non-nullable;
  `RichEditorOptions` is immutable with `barPosition` defaulting to `BarPosition.top`.
* Executor methods return `Future<void>` (`getCurrentHtml` returns `Future<String>`),
  color setters take a non-null `Color`, `setFontSize` / `setHeading` throw
  `ArgumentError` for out-of-range values.
* Removed `JavascriptExecutorBase.encodeHtml`, `decodeHtml`, `getCachedHtml`
  and its unused listener fields, and the unused callback and model classes.
* `RichEditorState` fields `port`, `html`, `assetPath` and `localServer` are private;
  `javascriptExecutor` is read-only.
* `TabButton.onTap` is a `VoidCallback`; `disabled` now fades the button.
* `getHtml()` returns an empty string for an empty editor instead of `<p>​</p>`.
* Requires Flutter 3.27 and Dart 3.6. Depends on stable `flutter_inappwebview` 6.1.5;
  dropped `mime`, `path`, `xml2json` and `flutter_widget_from_html_core`.
* Declares Android and iOS as the supported platforms.

## 0.3.0

* Encode HTML correctly before setting it.

## 0.2.4 - 0.2.5

* Fix HTML encoding/decoding and URL escaping.

## 0.2.0 - 0.2.3

* Add lint rules and refactor.
* Show a loading indicator while the editor loads and while media uploads.
* Prevent the editor from getting stuck on loading.
* Escape special characters in commands.

## 0.1.1

* Encode HTML before injecting it into JavaScript.

## 0.1.0

* Update dependencies.

## 0.0.7

* Update flutter_inappwebview and flutter_widget_from_html_core.

## 0.0.6

* Refactor for flutter 3.10

## 0.0.5

* Update dependencies; fix `Platform._operatingSystem` error on web.

## 0.0.3

* Editor specific settings
* Video addition feature

## 0.0.1

* Initial release with basic features
