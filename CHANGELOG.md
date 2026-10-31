## 0.0.1

* Initial release with basic features

# 0.0.3

* Editor specific settings
* Video addition feature


# 0.0.6
* Refactor for flutter 3.10

# Unreleased
* Fix: text containing `+` (e.g. "C++") lost characters when set with `setHtml`.
* Fix: `getHtml` no longer decodes HTML entities, which turned typed text like `<b>` into real markup.
* Fix: strings with quotes or backslashes (fonts, placeholder, checkbox text, `insertHtml`, ...) no longer break or inject JavaScript; every argument is passed with `jsonEncode`.
* Fix: links, checkboxes, images and videos are built with the DOM instead of string concatenation; `javascript:` and other unsafe URLs are rejected.
* Fix: checkboxes no longer store an inline `onclick` handler in the HTML, and their label text is now shown.
* Fix: pasted HTML is sanitized (scripts, event handlers, unsafe URLs and Word markup removed); `setHtml`/`insertHtml` strip scripts and event handlers.
* Fix: crash in the paste handler when pasted text was inserted late.
* Breaking: removed `JavascriptExecutorBase.encodeHtml`/`decodeHtml`, and `setHeading` now throws `ArgumentError` outside 1-6.
