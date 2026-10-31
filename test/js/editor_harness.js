// Loads the real editor page, with its Tiptap bundle, into jsdom.
const path = require('node:path');
const { JSDOM } = require('jsdom');

const editorHtml = path.join(__dirname, '../../assets/editor/editor.html');

async function loadEditor() {
  const sentToFlutter = [];

  const dom = await JSDOM.fromFile(editorHtml, {
    runScripts: 'dangerously',
    resources: 'usable',
    pretendToBeVisual: true,
    beforeParse(window) {
      // jsdom does no layout, which ProseMirror asks about when scrolling the caret into view
      const noRect = { top: 0, bottom: 0, left: 0, right: 0, width: 0, height: 0, x: 0, y: 0 };
      window.Range.prototype.getClientRects = () => [];
      window.Range.prototype.getBoundingClientRect = () => noRect;
      window.Element.prototype.getClientRects = () => [];
      window.Element.prototype.scrollIntoView = () => {};
      window.document.elementFromPoint = () => null;
      window.flutter_inappwebview = {
        callHandler: (name, data) =>
          sentToFlutter.push([name, data === undefined ? undefined : JSON.parse(JSON.stringify(data))]),
      };
    },
  });

  await new Promise((resolve) => dom.window.addEventListener('load', resolve));

  const { window } = dom;
  const editor = window.editor;
  return {
    window,
    editor,
    tiptap: editor._tiptap,
    sentToFlutter,
    html: () => decodeURIComponent(editor.getEncodedHtml()),
    text: () => decodeURIComponent(editor.getEncodedText()),
    json: () => JSON.parse(decodeURIComponent(editor.getEncodedJson())),
    // Puts the caret at a ProseMirror position (or the end), like a user tapping there.
    caret(position) {
      const doc = editor._tiptap.state.doc;
      editor._tiptap.commands.setTextSelection(position == null ? doc.content.size - 1 : position);
    },
    // Selects the first occurrence of text.
    select(text) {
      let found = null;
      editor._tiptap.state.doc.descendants((node, pos) => {
        if (found == null && node.isText && node.text.includes(text)) {
          found = pos + node.text.indexOf(text);
        }
      });
      if (found == null) throw new Error(`"${text}" not found`);
      editor._tiptap.commands.setTextSelection({ from: found, to: found + text.length });
    },
    // Types text at the caret, the way ProseMirror receives keyboard input.
    type(text) {
      const view = editor._tiptap.view;
      const { from, to } = view.state.selection;
      if (!view.someProp('handleTextInput', (f) => f(view, from, to, text))) {
        view.dispatch(view.state.tr.insertText(text, from, to));
      }
    },
    close: () => window.close(),
  };
}

module.exports = { loadEditor };
