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

describe('content', () => {
  it('round-trips HTML with characters the old encoding broke', () => {
    const html = "<p>C++ 100% it's &lt;b&gt; &amp; a&nbsp;b \"q\"</p>";
    e.editor.setHtml(html);
    assert.equal(e.html(), html);
  });

  it('reports an empty editor as empty HTML without zero width spaces', () => {
    e.editor.setHtml('');
    assert.match(e.window.editor._textField.innerHTML, /​/);
    assert.equal(e.html(), '');
    assert.equal(e.editor.isEmpty(), true);

    e.editor.setHtml('<p>​abc</p>');
    assert.equal(e.html(), '<p>abc</p>');
    assert.equal(e.editor.isEmpty(), false);
  });

  it('counts media as content', () => {
    e.editor.setHtml('<p><img src="https://e.com/a.png"></p>');
    assert.equal(e.editor.isEmpty(), false);
  });

  it('keeps resize classes out of the HTML', () => {
    e.editor.setHtml('<p><img src="https://e.com/a.png"></p>');
    assert.match(e.window.editor._textField.innerHTML, /resizable/);
    assert.equal(e.html(), '<p><img src="https://e.com/a.png"></p>');
  });
});

describe('state reporting', () => {
  it('reports HTML the application set as fromApplication', () => {
    e.editor.setHtml('<p>x</p>');
    const state = lastState();
    assert.equal(state.html, '<p>x</p>');
    assert.equal(state.fromApplication, true);
    assert.equal(state.didHtmlChange, false);
  });

  it('reports user edits, but not unchanged states again', async () => {
    e.editor.setHtml('<p>x</p>');
    const count = e.sentToFlutter.length;
    e.editor._updateEditorState();
    assert.equal(e.sentToFlutter.length, count);

    e.window.editor._textField.querySelector('p').textContent = 'xy';
    e.window.editor._textField.dispatchEvent(new e.window.Event('input'));
    await wait(60);
    const state = lastState();
    assert.equal(state.html, '<p>xy</p>');
    assert.equal(state.fromApplication, false);
    assert.equal(state.didHtmlChange, true);
  });

  it('batches reports while typing', async () => {
    e.editor.setHtml('<p>x</p>');
    const count = e.sentToFlutter.length;
    const p = e.window.editor._textField.querySelector('p');
    for (const text of ['xa', 'xab', 'xabc']) {
      p.textContent = text;
      e.window.editor._textField.dispatchEvent(new e.window.Event('input'));
    }
    assert.equal(e.sentToFlutter.length, count);
    await wait(60);
    assert.equal(e.sentToFlutter.length, count + 1);
    assert.equal(lastState().html, '<p>xabc</p>');
  });

  it('reports commands right away, dropping a pending report', async () => {
    e.editor.setHtml('<p>x</p>');
    e.window.editor._textField.querySelector('p').textContent = 'xy';
    e.window.editor._textField.dispatchEvent(new e.window.Event('input'));
    e.editor.setBold();
    const count = e.sentToFlutter.length;
    assert.equal(lastState().html, '<p>xy</p>');
    await wait(60);
    assert.equal(e.sentToFlutter.length, count);
  });

  it('waits longer for large documents', async () => {
    e.editor.setHtml(`<p>${'x'.repeat(200000)}</p>`);
    const count = e.sentToFlutter.length;
    e.window.editor._textField.dispatchEvent(new e.window.Event('input'));
    e.window.editor._textField.querySelector('p').textContent = 'y';
    await wait(100);
    assert.equal(e.sentToFlutter.length, count);
    await wait(200);
    assert.equal(lastState().html, '<p>y</p>');
  });

  it('announces itself when the Flutter bridge becomes ready', () => {
    e.window.dispatchEvent(new e.window.Event('flutterInAppWebViewPlatformReady'));
    assert.deepEqual(e.sentToFlutter.slice(-2).map(([name]) => name), ['editorReady', 'editorStateChanged']);
  });
});

describe('placeholder', () => {
  it('shows only while empty', () => {
    const field = e.window.editor._textField;
    e.editor.setPlaceholder('Type here');
    assert.equal(field.classList.contains('placeholder-visible'), true);
    e.editor.setHtml('<p>x</p>');
    assert.equal(field.classList.contains('placeholder-visible'), false);
    e.editor.setHtml('');
    assert.equal(field.classList.contains('placeholder-visible'), true);
  });
});

describe('backspace', () => {
  const backspace = () => {
    const event = new e.window.KeyboardEvent('keydown', { keyCode: 8, which: 8, bubbles: true, cancelable: true });
    e.window.editor._textField.dispatchEvent(event);
    return event.defaultPrevented;
  };

  it('keeps the last empty paragraph', () => {
    e.editor.setHtml('');
    assert.equal(backspace(), true);
  });

  it('deletes a single remaining character', () => {
    e.editor.setHtml('<p>a</p>');
    assert.equal(backspace(), false);
  });
});

describe('inserting', () => {
  const inserted = () => e.executed.filter(([command]) => command === 'insertHTML').map(([, html]) => html);

  it('builds links with the DOM and escapes the label', () => {
    e.placeCaretAtEnd();
    e.editor.insertLink("https://e.com/?a=1&b='2'", '<img src=x onerror="x()">');
    assert.deepEqual(inserted(), ['<a href="https://e.com/?a=1&amp;b=\'2\'">&lt;img src=x onerror="x()"&gt;</a>']);
  });

  it('ignores javascript: links', () => {
    e.placeCaretAtEnd();
    e.editor.insertLink('javascript:x()', 'x');
    assert.deepEqual(inserted(), []);
  });

  it('builds checkboxes without inline handlers and shows the label', () => {
    e.placeCaretAtEnd();
    e.editor.insertCheckbox('<b>milk</b>');
    assert.deepEqual(inserted(), ['<input type="checkbox" name="<b>milk</b>" value="<b>milk</b>">&nbsp;&lt;b&gt;milk&lt;/b&gt;']);
  });

  it('builds videos and YouTube iframes, rejecting unsafe URLs', () => {
    e.placeCaretAtEnd();
    e.editor.insertVideo('https://e.com/v.mp4" onerror="x', 300, 220, true);
    e.editor.insertVideo('javascript:x()', 300, 220, false);
    e.editor.insertVideo('https://www.youtube.com/embed/abc', 300, 220, false);
    const [video, iframe] = inserted();
    assert.equal(inserted().length, 2);
    assert.equal(video, '<video width="300" height="220" controls=""><source type="video/mp4" src="https://e.com/v.mp4&quot; onerror=&quot;x"></video>');
    assert.match(iframe, /^<iframe width="300" height="220" src="https:\/\/www.youtube.com\/embed\/abc"/);
    assert.match(iframe, /referrerpolicy="strict-origin-when-cross-origin"/);
  });

  it('allows data: images but not other data: URLs', () => {
    e.placeCaretAtEnd();
    e.editor.insertImage('data:image/png;base64,AA', 'a"lt', 300, 300, 0);
    e.editor.insertImage('data:text/html,<b>', '', 300, 300, 0);
    assert.equal(inserted().length, 1);
    assert.match(inserted()[0], /^<img src="data:image\/png;base64,AA" alt="a&quot;lt" width="300" height="300"/);
  });

  it('sanitizes insertHtml', () => {
    e.placeCaretAtEnd();
    e.editor.insertHtml("<p>it's</p><img src=x onerror='x()'>");
    assert.deepEqual(inserted(), ['<p>it\'s</p><img src="x">']);
  });
});

describe('paste', () => {
  const paste = (data) => {
    let prevented = false;
    e.editor._handlePaste({
      clipboardData: { getData: (type) => data[type] || '' },
      preventDefault: () => (prevented = true),
    });
    return prevented;
  };
  const inserted = () => e.executed.filter(([command]) => command === 'insertHTML').map(([, html]) => html);

  it('sanitizes pasted HTML', () => {
    e.placeCaretAtEnd();
    assert.equal(paste({ 'text/html': '<b onclick="x()">a</b><script>x()</script>' }), true);
    assert.deepEqual(inserted(), ['<b>a</b>']);
  });

  it('escapes pasted text and keeps line breaks', () => {
    e.placeCaretAtEnd();
    paste({ 'text/plain': 'a <b>\nb' });
    assert.deepEqual(inserted(), ['a &lt;b&gt;<br>b']);
  });

  it('leaves pasted non-image files to the browser', () => {
    assert.equal(paste({}), false);
  });

  it('sends pasted images to Flutter', async () => {
    // jsdom doesn't decode images
    e.window.Image = class {
      set src(_) {
        Object.assign(this, { naturalWidth: 640, naturalHeight: 480 });
        setTimeout(() => this.onload());
      }
    };
    const file = new e.window.File([Buffer.from('png!')], 'shot.png', { type: 'image/png' });
    e.editor._handlePaste({
      clipboardData: { getData: () => '', files: [file] },
      preventDefault: () => {},
    });
    await wait(50);
    const [name, image] = e.sentToFlutter[e.sentToFlutter.length - 1];
    assert.equal(name, 'imagePasted');
    assert.equal(image.name, 'shot.png');
    assert.equal(image.type, 'image/png');
    assert.equal(Buffer.from(image.data, 'base64').toString(), 'png!');
    assert.deepEqual([image.width, image.height], [640, 480]);
    assert.deepEqual(inserted(), []);
  });
});

describe('checkboxes', () => {
  it('store their checked state in the HTML', () => {
    e.editor.setHtml('<p><input type="checkbox"></p>');
    const checkbox = e.window.editor._textField.querySelector('input');
    checkbox.click();
    assert.equal(e.html(), '<p><input type="checkbox" checked="checked"></p>');
  });
});

describe('style commands', () => {
  it('use CSS and reset fully transparent backgrounds', () => {
    e.editor.setTextBackgroundColor('rgba(255, 0, 0, 0.5)');
    e.editor.setTextBackgroundColor('rgba(0, 0, 0, 0)');
    const commands = e.executed.filter(([command]) => command === 'styleWithCSS' || command === 'backColor');
    assert.deepEqual(commands, [
      ['styleWithCSS', true], ['backColor', 'rgba(255, 0, 0, 0.5)'], ['styleWithCSS', false],
      ['styleWithCSS', true], ['backColor', 'inherit'], ['styleWithCSS', false],
    ]);
  });
});

describe('images', () => {
  const click = (element) => element.dispatchEvent(new e.window.MouseEvent('click', { bubbles: true }));

  it('take resize touches only once tapped', () => {
    e.editor.setHtml('<p><img src="https://e.com/a.png"><img src="https://e.com/b.png">text</p>');
    const [a, b] = e.window.editor._textField.querySelectorAll('img');
    const selected = () => [a, b].map((image) => image.classList.contains('selected-image'));

    assert.deepEqual(selected(), [false, false]);
    click(a);
    assert.deepEqual(selected(), [true, false]);
    click(b);
    assert.deepEqual(selected(), [false, true]);
    click(e.window.editor._textField.querySelector('p'));
    assert.deepEqual(selected(), [false, false]);
  });

  it('keep the selection out of the HTML', () => {
    e.editor.setHtml('<p><img src="https://e.com/a.png"></p>');
    e.window.editor._textField.querySelector('img').dispatchEvent(new e.window.MouseEvent('click', { bubbles: true }));
    assert.equal(e.html(), '<p><img src="https://e.com/a.png"></p>');
  });
});

describe('composition', () => {
  it('leaves the DOM alone while the keyboard composes a word', () => {
    const field = e.window.editor._textField;
    const paragraphFixes = () => e.executed.filter(([command]) => command === 'DefaultParagraphSeparator').length;
    const before = paragraphFixes();
    field.innerHTML = '';
    field.dispatchEvent(new e.window.CompositionEvent('compositionstart'));
    field.dispatchEvent(new e.window.Event('input'));
    assert.equal(paragraphFixes(), before);

    field.dispatchEvent(new e.window.CompositionEvent('compositionend'));
    assert.equal(paragraphFixes(), before + 1);
  });
});

describe('focus', () => {
  it('opens the keyboard with the VirtualKeyboard API, then hands control back', async () => {
    const field = e.window.editor._textField;
    let policyWhenShown;
    Object.defineProperty(e.window.navigator, 'virtualKeyboard', {
      value: { show: () => (policyWhenShown = field.getAttribute('virtualkeyboardpolicy')) },
    });

    e.editor.focus();
    assert.equal(e.window.document.activeElement, field);
    assert.equal(policyWhenShown, 'manual');
    await wait(350);
    assert.equal(field.hasAttribute('virtualkeyboardpolicy'), false);
  });

  it('only focuses without the VirtualKeyboard API', () => {
    e.editor.focus();
    assert.equal(e.window.document.activeElement, e.window.editor._textField);
  });
});
