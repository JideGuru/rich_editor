const { describe, it, beforeEach, afterEach } = require('node:test');
const assert = require('node:assert');
const { loadEditor } = require('./editor_harness');

let e;
beforeEach(async () => (e = await loadEditor()));
afterEach(() => e.close());

const wait = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

const lastState = () => {
  const states = e.sentToFlutter.filter(([name]) => name === 'editorStateChanged');
  return states[states.length - 1][1];
};

const commandState = (command) => e.editor._determineCommandStates()[command];

describe('content', () => {
  it('round-trips HTML with characters the old encoding broke', () => {
    const html = '<p>C++ 100% &lt;b&gt; &amp; "quotes" \'it\'s\' 🎉</p>';
    e.editor.setHtml(html);
    assert.equal(e.html(), html);
  });

  it('reports an empty editor as empty HTML', () => {
    assert.equal(e.html(), '');
    assert.equal(e.editor.isEmpty(), true);
    e.editor.setHtml('<p>​</p><p> </p>');
    assert.equal(e.html(), '');
    assert.equal(e.editor.isEmpty(), true);
  });

  it('counts media as content', () => {
    e.editor.setHtml('<p><img src="a.png"></p>');
    assert.equal(e.editor.isEmpty(), false);
    e.editor.setHtml('<p><input type="checkbox"></p>');
    assert.equal(e.editor.isEmpty(), false);
  });

  it('loads HTML saved by the previous editor', () => {
    e.editor.setHtml(
      '<p><b>b</b> <font color="#ff0000" face="Arial" size="5">f</font> <strike>s</strike>​</p>' +
      '<blockquote style="margin: 0 0 0 40px; border: none; padding: 0px;">indented' +
      '<blockquote style="margin: 0 0 0 40px; border: none; padding: 0px;"><p>twice</p></blockquote></blockquote>' +
      '<blockquote>quote</blockquote>' +
      '<p><img src="a.png" class="resizable selected-image rotate90deg" width="200" height="100">' +
      '<img src="b.png" style="width: 120px; height: 80px; transform: rotate(180deg);"></p>');
    assert.equal(e.html(),
      '<p><strong>b</strong> <span style="color: rgb(255, 0, 0); font-family: Arial; font-size: x-large;">f</span> <s>s</s></p>' +
      '<p style="margin-inline-start: 40px;">indented</p><p style="margin-inline-start: 80px;">twice</p>' +
      '<blockquote><p>quote</p></blockquote>' +
      '<p><img src="a.png" width="200" height="100" style="transform: rotate(90deg);">' +
      '<img src="b.png" width="120" height="80" style="transform: rotate(180deg);"></p>');
  });

  it('gives the same HTML when its own HTML is loaded again', () => {
    e.editor.setHtml('<h2 style="text-align:center">T</h2><ul><li>a<ul><li>b</li></ul></li></ul><pre>x\n  y</pre>' +
      '<p><a href="https://e.com" title="t">l</a> <input type="checkbox" checked name="n" value="n">&nbsp;n</p>' +
      '<video width="300" height="220" controls><source src="https://e.com/v.mp4"></video><hr>');
    const html = e.html();
    e.editor.setHtml(html);
    assert.equal(e.html(), html);
  });
});

describe('JSON', () => {
  it('is the Tiptap document', () => {
    e.editor.setHtml('<p>a <b>b</b></p>');
    assert.deepEqual(e.json(), {
      type: 'doc',
      content: [{ type: 'paragraph', attrs: { textAlign: null, indent: 0 }, content: [
        { type: 'text', text: 'a ' },
        { type: 'text', text: 'b', marks: [{ type: 'bold' }] },
      ] }],
    });
  });

  it('round-trips through setJson', () => {
    e.editor.setHtml('<h1>t</h1><p><img src="a.png" width="10"> <a href="https://e.com">l</a></p>');
    const json = e.json();
    const html = e.html();
    e.editor.setHtml('');
    assert.equal(e.editor.setJson(json), true);
    assert.equal(e.html(), html);
    assert.equal(lastState().fromApplication, true);
  });

  it('rejects documents that do not fit the schema, keeping the content', () => {
    e.editor.setHtml('<p>kept</p>');
    assert.equal(e.editor.setJson({ type: 'doc', content: [{ type: 'table' }] }), false);
    assert.equal(e.editor.setJson({ type: 'doc', content: [{ type: 'text', text: 'not in a paragraph' }] }), false);
    assert.equal(e.html(), '<p>kept</p>');
  });

  it('never renders unsafe URLs it was given', () => {
    e.editor.setJson({ type: 'doc', content: [{ type: 'paragraph', content: [
      { type: 'image', attrs: { src: 'javascript:x' } },
      { type: 'text', text: 'l', marks: [{ type: 'link', attrs: { href: 'javascript:x' } }] },
    ] }, { type: 'iframe', attrs: { src: 'javascript:x' } }] });
    assert.doesNotMatch(e.html(), /javascript/);
  });
});

describe('state reporting', () => {
  it('reports HTML the application set as fromApplication', () => {
    e.editor.setHtml('<p>a</p>');
    const state = lastState();
    assert.equal(state.html, '<p>a</p>');
    assert.equal(state.fromApplication, true);
    assert.equal(state.didHtmlChange, false);
  });

  it('reports user edits, but not unchanged states again', async () => {
    e.editor.setHtml('<p>a</p>');
    e.caret();
    e.type('b');
    await wait(60);
    const state = lastState();
    assert.equal(state.html, '<p>ab</p>');
    assert.equal(state.fromApplication, false);
    assert.equal(state.didHtmlChange, true);

    const reports = e.sentToFlutter.length;
    e.editor._updateEditorState();
    assert.equal(e.sentToFlutter.length, reports);
  });

  it('batches reports while typing', async () => {
    e.caret();
    const reports = e.sentToFlutter.length;
    for (const letter of 'hello') e.type(letter);
    assert.equal(e.sentToFlutter.length, reports);
    await wait(60);
    assert.equal(e.sentToFlutter.length, reports + 1);
    assert.equal(lastState().html, '<p>hello</p>');
  });

  it('reports commands right away, dropping a pending report', async () => {
    e.caret();
    e.type('a');
    e.editor.setBold();
    assert.equal(lastState().commandStates.bold.active, true);
    const reports = e.sentToFlutter.length;
    await wait(60);
    assert.equal(e.sentToFlutter.length, reports);
  });

  it('announces itself when the Flutter bridge becomes ready', () => {
    e.window.dispatchEvent(new e.window.Event('flutterInAppWebViewPlatformReady'));
    assert.equal(e.sentToFlutter[e.sentToFlutter.length - 2][0], 'editorReady');
    assert.equal(lastState().fromApplication, true);
  });
});

describe('placeholder', () => {
  it('shows only while empty', () => {
    e.editor.setPlaceholder('Type here');
    const paragraph = () => e.editor._textField.querySelector('p');
    assert.equal(paragraph().getAttribute('data-placeholder'), 'Type here');
    assert.equal(paragraph().classList.contains('is-editor-empty'), true);

    e.caret();
    e.type('a');
    assert.equal(paragraph().classList.contains('is-editor-empty'), false);
  });

  it('shows while read-only too', () => {
    e.editor.setInputEnabled(false);
    e.editor.setPlaceholder('Nothing yet');
    assert.equal(e.editor._textField.querySelector('p').getAttribute('data-placeholder'), 'Nothing yet');
  });
});

describe('formatting', () => {
  beforeEach(() => e.editor.setHtml('<p>one two</p>'));

  it('toggles marks on the selection and reports them', () => {
    e.select('two');
    e.editor.setBold();
    e.editor.setItalic();
    e.editor.setUnderline();
    e.editor.setStrikeThrough();
    assert.equal(e.html(), '<p>one <strong><em><s><u>two</u></s></em></strong></p>');
    for (const command of ['bold', 'italic', 'underline', 'strikeThrough']) {
      assert.equal(commandState(command).active, true, command);
    }
    e.editor.setBold();
    assert.equal(commandState('bold').active, false);
  });

  it('keeps subscript and superscript apart', () => {
    e.select('two');
    e.editor.setSuperscript();
    e.editor.setSubscript();
    assert.equal(e.html(), '<p>one <sub>two</sub></p>');
    e.editor.setSuperscript();
    assert.equal(e.html(), '<p>one <sup>two</sup></p>');
  });

  it('colors text with CSS and reports the color', () => {
    e.select('two');
    e.editor.setTextColor('#112233');
    e.editor.setTextBackgroundColor('rgba(255, 0, 0, 0.502)');
    assert.equal(e.html(), '<p>one <span style="background-color: rgba(255, 0, 0, 0.502); color: rgb(17, 34, 51);">two</span></p>');
    assert.equal(commandState('foreColor').value, '#112233');
    assert.equal(commandState('backColor').value, 'rgba(255, 0, 0, 0.502)');

    e.editor.setTextBackgroundColor('rgba(0, 0, 0, 0)'); // fully transparent removes it
    assert.equal(e.html(), '<p>one <span style="color: rgb(17, 34, 51);">two</span></p>');
  });

  it('sets fonts and the sizes of <font size>', () => {
    e.select('two');
    e.editor.setFontName('Courier New');
    e.editor.setFontSize(5);
    assert.equal(e.html(), '<p>one <span style="font-family: Courier New; font-size: x-large;">two</span></p>');
    assert.equal(commandState('fontSize').value, '5');
    assert.equal(commandState('fontName').value, 'Courier New');
  });

  it('removes formatting but keeps links', () => {
    e.editor.setHtml('<p><a href="https://e.com"><b><span style="color: red">x</span></b></a></p>');
    e.select('x');
    e.editor.removeFormat();
    assert.equal(e.html(), '<p><a href="https://e.com">x</a></p>');
  });

  it('formats blocks and reports them like formatBlock', () => {
    e.caret(2);
    e.editor.setHeading(2);
    assert.equal(e.html(), '<h2>one two</h2>');
    assert.equal(commandState('formatBlock').value, 'h2');

    e.editor.setPreformat();
    assert.equal(e.html(), '<pre><code>one two</code></pre>');
    assert.equal(commandState('formatBlock').value, 'pre');

    e.editor.setFormattingToParagraph();
    assert.equal(commandState('formatBlock').value, 'p');
  });

  it('quotes, and the paragraph format takes the quote away again', () => {
    e.caret(2);
    e.editor.setBlockQuote();
    assert.equal(e.html(), '<blockquote><p>one two</p></blockquote>');
    assert.equal(commandState('formatBlock').value, 'blockquote');

    e.editor.setFormattingToParagraph();
    assert.equal(e.html(), '<p>one two</p>');
  });

  it('aligns, defaulting to the side text starts on', () => {
    e.caret(2);
    assert.equal(commandState('justifyLeft').active, true);
    e.editor.setJustifyCenter();
    assert.equal(e.html(), '<p style="text-align: center;">one two</p>');
    assert.equal(commandState('justifyCenter').active, true);
    assert.equal(commandState('justifyLeft').active, false);

    e.editor.setJustifyFull();
    assert.equal(commandState('justifyFull').active, true);

    e.editor.setHtml('<p>x</p>');
    e.editor.setTextDirection('rtl');
    e.caret(1);
    assert.equal(commandState('justifyRight').active, true);
  });

  it('indents paragraphs in steps', () => {
    e.caret(2);
    e.editor.setIndent();
    e.editor.setIndent();
    assert.equal(e.html(), '<p style="margin-inline-start: 80px;">one two</p>');
    assert.equal(commandState('formatBlock').value, 'p'); // not a quote
    e.editor.setOutdent();
    e.editor.setOutdent();
    e.editor.setOutdent();
    assert.equal(e.html(), '<p>one two</p>');
  });

  it('makes lists, nesting list items to indent them', () => {
    e.editor.setHtml('<p>a</p><p>b</p>');
    e.select('a');
    e.editor.insertBulletList();
    assert.equal(commandState('insertUnorderedList').active, true);
    e.select('b');
    e.editor.insertBulletList();
    assert.equal(e.html(), '<ul><li><p>a</p></li><li><p>b</p></li></ul>');

    e.editor.setIndent();
    assert.equal(e.html(), '<ul><li><p>a</p><ul><li><p>b</p></li></ul></li></ul>');
    e.editor.insertNumberedList();
    assert.equal(commandState('insertOrderedList').active, true);
    assert.equal(commandState('insertUnorderedList').active, false); // the innermost list counts
    e.editor.setOutdent();
    assert.equal(e.html(), '<ul><li><p>a</p></li><li><p>b</p></li></ul>');
    e.select('a');
    e.editor.insertBulletList();
    assert.equal(e.html(), '<p>a</p><ul><li><p>b</p></li></ul>');
  });

  it('undoes and redoes, reporting whether it can', () => {
    assert.equal(commandState('undo').enabled, false); // setHtml is not undoable
    e.select('two');
    e.editor.setBold();
    assert.equal(commandState('undo').enabled, true);
    assert.equal(commandState('redo').enabled, false);
    e.editor.undo();
    assert.equal(e.html(), '<p>one two</p>');
    assert.equal(commandState('redo').enabled, true);
    e.editor.redo();
    assert.equal(e.html(), '<p>one <strong>two</strong></p>');
  });
});

describe('inserting', () => {
  beforeEach(() => {
    e.editor.setHtml('<p>x</p>');
    e.caret();
  });

  it('inserts links with their label as text, not linking what is typed next', () => {
    e.editor.insertLink('https://e.com/?a=1&b=2', '<b>label</b>');
    e.type('!');
    assert.equal(e.html(), '<p>x<a href="https://e.com/?a=1&amp;b=2">&lt;b&gt;label&lt;/b&gt;</a>!</p>');
  });

  it('links the selection', () => {
    e.select('x');
    e.editor.insertLink('https://e.com', 'Title');
    assert.equal(e.html(), '<p><a href="https://e.com" title="Title">x</a></p>');
  });

  it('ignores javascript: links', () => {
    e.editor.insertLink('javascript:alert(1)', 'bad');
    assert.equal(e.html(), '<p>x</p>');
  });

  it('inserts checkboxes followed by their label', () => {
    e.editor.insertCheckbox('Milk "2%"');
    assert.equal(e.html(), '<p>x<input type="checkbox" name="Milk &quot;2%&quot;" value="Milk &quot;2%&quot;">&nbsp;Milk "2%"</p>');
  });

  it('inserts images with their size and rotation', () => {
    e.editor.insertImage('data:image/png;base64,AA', 'alt "text"', 300, 200, 270);
    assert.equal(e.html(), '<p>x<img src="data:image/png;base64,AA" alt="alt &quot;text&quot;" width="300" height="200" style="transform: rotate(270deg);"></p>');
    e.editor.insertImage('data:text/html,x', '', 300, 300, 0);
    e.editor.insertImage('javascript:x', '', 300, 300, 0);
    assert.equal(e.html().match(/<img/g).length, 1);
  });

  it('inserts videos and YouTube players, with the caret after them', () => {
    e.editor.insertVideo('https://e.com/v.mp4', 300, 220, true);
    e.editor.insertVideo('https://www.youtube.com/embed/a', 300, 220, false);
    e.editor.insertVideo('javascript:x', 300, 220, true);
    e.editor.insertVideo('javascript:x', 300, 220, false);
    e.editor.insertVideo('data:video/mp4;base64,AA', 300, 220, false);
    const html = e.html();
    assert.match(html, /<video controls="" width="300" height="220"><source src="https:\/\/e.com\/v.mp4" type="video\/mp4"><\/video>/);
    assert.match(html, /<iframe [^>]*src="https:\/\/www.youtube.com\/embed\/a" width="300" height="220" title="YouTube video player"><\/iframe>/);
    assert.equal(html.match(/<(video|iframe)/g).length, 2);

    e.type('typed'); // goes after the player instead of replacing it
    assert.match(e.html(), /<\/iframe><p>typed<\/p>$/);
  });

  it('inserts HTML, dropping scripts', () => {
    e.editor.insertHtml('<b onclick="x()">bold</b><script>x()</script>');
    assert.equal(e.html(), '<p>x<strong>bold</strong></p>');
  });
});

describe('links', () => {
  beforeEach(() => e.editor.setHtml('<p>a <a href="https://old.com">link text</a> b</p>'));

  it('are reported with their URL while the caret is in one', () => {
    e.caret(6);
    assert.deepEqual(commandState('link'), { enabled: true, active: true, value: 'https://old.com' });
    e.caret(2);
    assert.equal(commandState('link').active, false);
  });

  it('can be changed as a whole, leaving the caret after them', () => {
    e.caret(6);
    e.editor.editLink('https://new.com');
    assert.equal(e.html(), '<p>a <a href="https://new.com">link text</a> b</p>');
    assert.equal(e.tiptap.state.selection.empty, true);
    assert.equal(e.tiptap.state.selection.from, 12);
  });

  it('can be removed, keeping their text', () => {
    e.caret(6);
    e.editor.removeLink();
    assert.equal(e.html(), '<p>a link text b</p>');
  });

  it('are not changed to unsafe URLs, or outside a link', () => {
    e.caret(6);
    e.editor.editLink('javascript:alert(1)');
    e.caret(1);
    e.editor.editLink('https://other.com');
    e.editor.removeLink();
    assert.equal(e.html(), '<p>a <a href="https://old.com">link text</a> b</p>');
  });
});

describe('checkboxes', () => {
  beforeEach(() => e.editor.setHtml('<p><input type="checkbox">&nbsp;task</p>'));

  const checkbox = () => e.editor._textField.querySelector('input[type=checkbox]');

  it('store their checked state in the HTML', () => {
    checkbox().click();
    assert.equal(e.html(), '<p><input type="checkbox" checked="checked">&nbsp;task</p>');
    checkbox().click();
    assert.equal(e.html(), '<p><input type="checkbox">&nbsp;task</p>');
  });

  it('cannot be ticked while the editor is read-only', () => {
    e.editor.setInputEnabled(false);
    checkbox().click();
    assert.equal(checkbox().checked, false);
    assert.equal(e.html(), '<p><input type="checkbox">&nbsp;task</p>');
  });
});

describe('paste', () => {
  const paste = (data, files = []) => {
    const event = new e.window.Event('paste', { bubbles: true, cancelable: true });
    event.clipboardData = {
      types: Object.keys(data),
      files,
      getData: (type) => data[type] || '',
    };
    e.editor._textField.dispatchEvent(event);
    return event.defaultPrevented;
  };

  beforeEach(() => {
    e.editor.setHtml('<p>x</p>');
    e.caret();
  });

  it('keeps the formatting the editor has, dropping players and scripts', () => {
    paste({ 'text/html': '<p><b onclick="x()"><span style="color: red">bold</span></b><iframe src="https://e.com"></iframe><script>x()</script></p>' });
    assert.equal(e.html(), '<p>x<span style="color: red;"><strong>bold</strong></span></p>');
  });

  it('pastes text as text, one paragraph per line', () => {
    paste({ 'text/plain': 'a <b>\nb' });
    assert.equal(e.html(), '<p>xa &lt;b&gt;</p><p>b</p>');
  });

  it('leaves pasted non-image files to the browser', () => {
    assert.equal(e.editor._handlePaste({ clipboardData: { getData: () => '', files: [] } }), false);
  });

  it('sends pasted images to Flutter instead of inserting them', async () => {
    // jsdom doesn't decode images
    e.window.Image = class {
      set src(_) {
        Object.assign(this, { naturalWidth: 640, naturalHeight: 480 });
        setTimeout(() => this.onload());
      }
    };
    const file = new e.window.File([Buffer.from('png!')], 'shot.png', { type: 'image/png' });
    assert.equal(paste({}, [file]), true);
    await wait(50);
    const [name, image] = e.sentToFlutter[e.sentToFlutter.length - 1];
    assert.equal(name, 'imagePasted');
    assert.equal(image.name, 'shot.png');
    assert.equal(image.type, 'image/png');
    assert.equal(Buffer.from(image.data, 'base64').toString(), 'png!');
    assert.deepEqual([image.width, image.height], [640, 480]);
    assert.equal(e.html(), '<p>x</p>');
  });
});

describe('images', () => {
  beforeEach(() => e.editor.setHtml('<p>a<img src="a.png" width="200" height="100">b</p>'));

  const image = () => e.editor._textField.querySelector('img');

  it('take resize touches only once selected, and only while editable', () => {
    const field = e.editor._textField;
    assert.equal(image().classList.contains('selected-image'), false);
    e.tiptap.commands.setNodeSelection(2);
    assert.equal(image().classList.contains('selected-image'), true);
    assert.equal(field.classList.contains('images-resizable'), true);

    e.editor.disableImageResizing();
    assert.equal(field.classList.contains('images-resizable'), false);
    e.editor.makeImagesResizeable();
    e.editor.setInputEnabled(false);
    assert.equal(field.classList.contains('images-resizable'), false);
  });

  it('store the size and rotation a gesture ends with, and nothing of the selection', () => {
    e.tiptap.commands.setNodeSelection(2);
    image()._updateAttributes({ width: 150, height: 75 });
    image()._updateAttributes({ rotation: 90 });
    assert.equal(e.html(), '<p>a<img src="a.png" width="150" height="75" style="transform: rotate(90deg);">b</p>');
    e.editor.undo();
    assert.equal(e.html(), '<p>a<img src="a.png" width="200" height="100">b</p>');
  });
});

describe('focus', () => {
  it('opens the keyboard with the VirtualKeyboard API, then hands control back', async () => {
    const field = e.editor._textField;
    let policyWhenShown;
    Object.defineProperty(e.window.navigator, 'virtualKeyboard', {
      value: { show: () => (policyWhenShown = field.getAttribute('virtualkeyboardpolicy')) },
    });

    e.editor.focus();
    await wait(20);
    assert.equal(e.window.document.activeElement, field);
    assert.equal(policyWhenShown, 'manual');
    await wait(350);
    assert.equal(field.hasAttribute('virtualkeyboardpolicy'), false);
  });

  it('puts the caret at the end', async () => {
    e.editor.setHtml('<p>a</p><p>bc</p>');
    e.editor.focus();
    await wait(20);
    assert.equal(e.tiptap.state.selection.from, 6);
  });

  it('can be taken away', async () => {
    e.editor.focus();
    await wait(20);
    e.editor.blurFocus();
    assert.notEqual(e.window.document.activeElement, e.editor._textField);
  });
});

describe('page settings', () => {
  it('set the text direction on the page, not in the content', () => {
    e.editor.setHtml('<p>a</p>');
    e.editor.setTextDirection('rtl');
    assert.equal(e.window.document.documentElement.dir, 'rtl');
    assert.equal(e.html(), '<p>a</p>');
  });

  it('keep colors and padding out of the content', () => {
    e.editor.setHtml('<p>a</p>');
    e.editor.setBackgroundColor('#000000');
    e.editor.setBaseTextColor('#ffffff');
    e.editor.setPadding('1px', '2px', '3px', '4px');
    e.editor.setColorScheme('dark');
    assert.equal(e.window.document.body.style.backgroundColor, 'rgb(0, 0, 0)');
    assert.equal(e.window.document.documentElement.style.colorScheme, 'dark');
    assert.equal(e.editor._textField.style.paddingBottom, '4px');
    assert.equal(e.html(), '<p>a</p>');
  });

  it('read-only stops editing', () => {
    e.editor.setInputEnabled(false);
    assert.equal(e.editor._textField.getAttribute('contenteditable'), 'false');
    e.editor.setInputEnabled(true);
    assert.equal(e.editor._textField.getAttribute('contenteditable'), 'true');
  });
});

describe('text', () => {
  it('puts each paragraph, heading and list item on a line of its own', () => {
    e.editor.setHtml('<h1>Title</h1><p>a<br>b <b>c</b></p><ul><li>one</li><li>two</li></ul><p><input type="checkbox">&nbsp;task</p>');
    assert.equal(e.text(), 'Title\na\nb c\none\ntwo\n task');
  });

  it('is empty for an empty editor', () => {
    assert.equal(e.text(), '');
  });
});
