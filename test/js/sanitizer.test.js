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

describe('setHtml keeps only what the editor understands', () => {
  let e;
  before(async () => (e = await loadEditor()));
  after(() => e.close());

  const load = (html) => {
    e.editor.setHtml(html);
    return e.html();
  };

  it('removes scripts, event handlers and unsafe URLs', () => {
    assert.equal(
      load('<p onclick="x()">a<script>x()</script></p><p><img src="x.png" onerror="x()"><a href="javascript:x()">b</a></p>'),
      '<p>a</p><p><img src="x.png">b</p>',
    );
  });

  it('drops svg, objects, frames and unsafe media but keeps web iframes', () => {
    assert.equal(
      load('<svg><script>x()</script></svg><object data="x"></object><iframe src="javascript:x"></iframe>' +
        '<iframe src="https://www.youtube.com/embed/a"></iframe><p><img src="javascript:x"></p>' +
        '<video><source src="javascript:x"></video>'),
      '<iframe frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" ' +
        'referrerpolicy="strict-origin-when-cross-origin" src="https://www.youtube.com/embed/a"></iframe><p></p>',
    );
  });

  it('keeps data: images but not other data: URLs', () => {
    assert.equal(
      load('<p><img src="data:image/png;base64,AA"><img src="data:text/html,x"></p>'),
      '<p><img src="data:image/png;base64,AA"></p>',
    );
  });

  it('reduces Word HTML to the formatting the editor has', () => {
    const word = '<html><head><style>p{color:red}</style></head><body><!--StartFragment--><p class="MsoNormal" ' +
      'style="mso-line-height:1;color:red;background:url(http://evil)"><o:p>Hello</o:p> <b onclick="x">bold</b>' +
      '<input type="text" value="t"><input type="checkbox" checked></p><!--EndFragment--></body></html>';
    assert.equal(load(word), '<p>Hello <strong>bold</strong><input type="checkbox" checked="checked"></p>');
  });
});
