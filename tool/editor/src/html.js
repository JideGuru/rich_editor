// URL checks and the clean-up HTML gets before ProseMirror parses it into the schema.

const safeUrlSchemes = ['http', 'https', 'mailto', 'tel', 'sms', 'file', 'blob', 'content'];

// What <font size="1"> to <font size="7"> stand for, as CSS.
export const legacyFontSizes = ['x-small', 'small', 'medium', 'large', 'x-large', 'xx-large', 'xxx-large'];

// Returns the url if it is safe to put into an href/src attribute, null otherwise.
// allowedDataPrefixes lists the data: URL types allowed, e.g. ['data:image/'].
export function safeUrl(url, allowedDataPrefixes) {
    if(url == null) {
        return null;
    }

    url = String(url).trim();
    // browsers ignore whitespace and control characters inside the scheme ("java\nscript:")
    const normalized = url.replace(/[\u0000- \u007F-\u009F]/g, '').toLowerCase();
    const match = normalized.match(/^([a-z][a-z0-9+.\-]*):/);

    if(!match) { // relative URL or file path
        return url;
    }

    if(match[1] === 'data') {
        return (allowedDataPrefixes || []).some((prefix) => normalized.indexOf(prefix) === 0) ? url : null;
    }

    return safeUrlSchemes.indexOf(match[1]) !== -1 ? url : null;
}

// Brings HTML from the previous editor, other editors and the clipboard closer to the schema, so
// ProseMirror keeps what it means: <font> becomes styled spans, indenting blockquotes become
// indented paragraphs. Pasted HTML also loses embedded players.
export function normalizeHtml(html, pasted) {
    // parsing into a separate document keeps the content inert: no scripts run and no images load
    const body = new DOMParser().parseFromString(html || '', 'text/html').body;
    if(!body) {
        return '';
    }

    if(pasted) {
        body.querySelectorAll('iframe, video, audio').forEach((element) => element.remove());
    }

    body.querySelectorAll('font').forEach(fontToSpan);
    // innermost first, so each level adds one step of indent
    Array.from(body.querySelectorAll('blockquote')).reverse().forEach(unwrapIndentQuote);

    const walker = body.ownerDocument.createTreeWalker(body, NodeFilter.SHOW_TEXT);
    while(walker.nextNode()) {
        if(walker.currentNode.nodeValue.indexOf('\u200B') !== -1) {
            walker.currentNode.nodeValue = walker.currentNode.nodeValue.replace(/\u200B/g, '');
        }
    }

    return body.innerHTML;
}

function fontToSpan(font) {
    const span = font.ownerDocument.createElement('span');
    span.setAttribute('style', font.getAttribute('style') || '');

    if(font.hasAttribute('color')) {
        span.style.color = font.getAttribute('color');
    }
    if(font.hasAttribute('face')) {
        span.style.fontFamily = font.getAttribute('face');
    }
    const size = parseInt(font.getAttribute('size'), 10);
    if(size) {
        span.style.fontSize = legacyFontSizes[Math.min(Math.max(size, 1), 7) - 1];
    }

    while(font.firstChild) {
        span.appendChild(font.firstChild);
    }
    font.parentNode.replaceChild(span, font);
}

// The previous editor's indent was a blockquote styled not to look like one.
function unwrapIndentQuote(quote) {
    const style = (quote.getAttribute('style') || '').replace(/\s/g, '').toLowerCase();
    if(style.indexOf('border:none') === -1) {
        return;
    }

    const document = quote.ownerDocument;
    let paragraph = null;
    Array.from(quote.childNodes).forEach((child) => {
        const isBlock = child.nodeType === 1 && /^(P|DIV|H[1-6]|PRE|UL|OL|BLOCKQUOTE|TABLE|HR)$/.test(child.nodeName);
        if(!isBlock) { // loose text and inline elements go into a paragraph of their own
            if(!paragraph) {
                paragraph = document.createElement('p');
                quote.insertBefore(paragraph, child);
            }
            paragraph.appendChild(child);
            return;
        }
        paragraph = null;
    });

    Array.from(quote.children).forEach((block) => {
        if(/^(P|DIV|H[1-6])$/.test(block.nodeName)) {
            block.setAttribute('data-indent', String((parseInt(block.getAttribute('data-indent'), 10) || 0) + 1));
        }
    });

    while(quote.firstChild) {
        quote.parentNode.insertBefore(quote.firstChild, quote);
    }
    quote.remove();
}
