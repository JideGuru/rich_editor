const { describe, it, before, after } = require('node:test');
const assert = require('node:assert');
const { loadEditor } = require('./editor_harness');

describe('_safeUrl', () => {
  let e;
  before(async () => (e = await loadEditor()));
  after(() => e.close());

  for (const url of ['https://e.com/a?b=1', 'http://e.com', 'mailto:a@b.c', 'tel:+1', '/data/user/0/x.png', 'relative/path', '#top']) {
    it(`allows ${url}`, () => assert.equal(e.editor._safeUrl(url), url));
  }

  for (const url of ['javascript:alert(1)', ' JavaScript:alert(1)', 'java\nscript:alert(1)', 'vbscript:x', 'data:text/html,<b>']) {
    it(`rejects ${JSON.stringify(url)}`, () => assert.equal(e.editor._safeUrl(url), null));
  }

  it('allows only the given data: types', () => {
    assert.equal(e.editor._safeUrl('data:image/png;base64,AA', ['data:image/']), 'data:image/png;base64,AA');
    assert.equal(e.editor._safeUrl('data:video/mp4;base64,AA', ['data:image/']), null);
  });
});

describe('_sanitizeHtml', () => {
  let e;
  before(async () => (e = await loadEditor()));
  after(() => e.close());

  const lenient = (html) => e.editor._sanitizeHtml(html, false);
  const strict = (html) => e.editor._sanitizeHtml(html, true);

  it('removes scripts, event handlers and unsafe URLs', () => {
    assert.equal(
      lenient('<p onclick="x()">a<script>x()</script></p><img src="x" onerror="x()"><a href="javascript:x()">b</a>'),
      '<p>a</p><img src="x"><a>b</a>',
    );
  });

  it('drops svg, objects and frames but keeps https iframes', () => {
    assert.equal(
      lenient('<svg><script>x()</script></svg><object data="x"></object><iframe src="javascript:x"></iframe><iframe src="https://www.youtube.com/embed/a"></iframe>'),
      '<iframe src="https://www.youtube.com/embed/a"></iframe>',
    );
  });

  it('keeps app formatting in lenient mode', () => {
    const html = '<p class="c" style="color: red;"><span style="background-color: yellow;">x</span></p><video controls=""><source src="https://e.com/v.mp4"></video>';
    assert.equal(lenient(html), html);
  });

  it('reduces pasted Word HTML to basic formatting', () => {
    const pasted = '<html><head><style>p{color:red}</style></head><body><!--StartFragment--><p class="MsoNormal" style="mso-line-height:1;color:red;background:url(http://evil)"><o:p>Hello</o:p> <b onclick="x">bold</b><iframe src="https://e.com"></iframe><input type="text" value="t"><input type="checkbox" checked></p><!--EndFragment--></body></html>';
    assert.equal(strict(pasted), '<p style="color: red;">Hello <b>bold</b><input type="checkbox" checked=""></p>');
  });
});
