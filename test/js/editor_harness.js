// Loads the real editor page into jsdom. jsdom has no editing commands,
// so document.execCommand and friends are stubbed and recorded.
const path = require('node:path');
const { JSDOM } = require('jsdom');

const editorHtml = path.join(__dirname, '../../assets/editor/editor.html');

async function loadEditor() {
  const executed = [];
  const sentToFlutter = [];

  const dom = await JSDOM.fromFile(editorHtml, {
    runScripts: 'dangerously',
    resources: 'usable',
    pretendToBeVisual: true,
    beforeParse(window) {
      window.document.execCommand = (command, _ui, value) => {
        executed.push([command, value]);
        return true;
      };
      window.document.queryCommandEnabled = () => true;
      window.document.queryCommandState = () => false;
      window.document.queryCommandValue = () => '';
      window.flutter_inappwebview = {
        callHandler: (name, data) =>
          sentToFlutter.push([name, data === undefined ? undefined : JSON.parse(JSON.stringify(data))]),
      };
    },
  });

  await new Promise((resolve) => dom.window.addEventListener('load', resolve));

  const { window } = dom;
  return {
    window,
    editor: window.editor,
    executed,
    sentToFlutter,
    html: () => decodeURIComponent(window.editor.getEncodedHtml()),
    // Puts the caret at the end of the content, like a user tapping there.
    placeCaretAtEnd() {
      const range = window.document.createRange();
      range.selectNodeContents(window.editor._textField);
      range.collapse(false);
      window.getSelection().removeAllRanges();
      window.getSelection().addRange(range);
      window.editor._backupRange();
    },
    close: () => window.close(),
  };
}

module.exports = { loadEditor };
