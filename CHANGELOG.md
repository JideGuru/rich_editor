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
* Colors keep their transparency; the color picker opens at the color under the cursor
  and has a Cancel button.

### Fixed
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
* `setState` after dispose when an upload finished late.
* Dialog text fields leaked their controllers.
* The editor no longer forces mixed content on, and only logs WebView console
  messages in debug builds.

### Breaking
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
