
// also edit class name in style.css when changing this.
const resizableImageClass = "resizable";

// Removed together with their content, whatever the source.
const sanitizerDroppedTags = ['script', 'noscript', 'object', 'embed', 'applet', 'base', 'meta', 'link',
    'frame', 'frameset', 'template', 'svg', 'math'];

// Pasted content is reduced to these tags; other elements are unwrapped so their text survives.
const sanitizerPasteTags = ['p', 'br', 'div', 'span', 'b', 'strong', 'i', 'em', 'u', 's', 'strike', 'del', 'ins',
    'sub', 'sup', 'mark', 'small', 'big', 'font', 'code', 'pre', 'blockquote', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6',
    'ul', 'ol', 'li', 'a', 'img', 'table', 'thead', 'tbody', 'tfoot', 'tr', 'td', 'th', 'caption', 'hr', 'input'];

// Pasted content also drops every content-irrelevant tag, which pasting from Word or web pages brings along.
const sanitizerPasteDroppedTags = ['style', 'title', 'head', 'iframe', 'video', 'audio', 'form', 'button',
    'textarea', 'select', 'option'];

const sanitizerPasteAttributes = {
    '*': ['style', 'dir'],
    'a': ['href', 'title'],
    'img': ['src', 'alt', 'width', 'height'],
    'input': ['type', 'checked'],
    'font': ['color', 'face', 'size'],
    'td': ['colspan', 'rowspan'],
    'th': ['colspan', 'rowspan'],
    'ol': ['start'],
};

const sanitizerPasteStyles = ['color', 'background-color', 'font-weight', 'font-style', 'font-family', 'font-size',
    'text-decoration', 'text-decoration-line', 'text-align', 'vertical-align', 'width', 'height'];

const sanitizerUrlAttributes = ['href', 'src', 'action', 'formaction', 'xlink:href', 'poster', 'background',
    'cite', 'data'];

const safeUrlSchemes = ['http', 'https', 'mailto', 'tel', 'sms', 'file', 'blob', 'content'];


var editor = {

    _textField: document.getElementById('editor'),

    _htmlSetByApplication: null,

    _currentSelection: {
        "startContainer": 0,
        "startOffset": 0,
        "endContainer": 0,
        "endOffset": 0
    },

    // last state sent to Flutter, so unchanged states aren't sent again
    _lastReportedHtml: null,
    _lastReportedCommandStates: null,

    // pending _updateEditorState() for typing and selecting, see _scheduleEditorStateUpdate()
    _editorStateUpdateTimer: null,

    _imageMinWidth: 100,
    _imageMinHeight: 50,

    _isImageResizingEnabled: true,


    init: function() {
        document.addEventListener("selectionchange", function() {
            editor._backupRange();
            editor._handleTextEntered(); // in newly selected area different commands may be activated / deactivated
        });

        this._textField.addEventListener("input", function() {
            editor._handleTextEntered();
        });

        this._textField.addEventListener("keydown", function(e) {
            var BACKSPACE = 8;

            // keep the paragraph new text goes into, once everything else is deleted
            if(e.which == BACKSPACE && editor._isEmpty(editor._textField) && editor._textField.children.length <= 1) {
                e.preventDefault();

                return false;
            }
        });

        this._textField.addEventListener("keyup", function(e) {
            if(e.altKey || e.ctrlKey || e.metaKey) { // some key combinations activate commands like CTRL + B setBold() -> update editor state so that UI is aware of this
                editor._updateEditorState();
            }
        });

        this._textField.addEventListener("paste", function(e) { editor._handlePaste(e); });
        this._textField.addEventListener("drop", function(e) { editor._handleDrop(e); });

        // Checkboxes are handled here rather than with inline onclick attributes, so saved HTML carries no script.
        this._textField.addEventListener("click", function(e) {
            var target = e.target;
            if (target && target.nodeName === 'INPUT' && target.type === 'checkbox') {
                editor._checkboxClicked(target);
            }
        });

        window.addEventListener("flutterInAppWebViewPlatformReady", function() {
            editor._onPlatformReady();
        });

        this._ensureEditorInsertsParagraphWhenPressingEnter();
        this._initDragImageToResize();
        this._updateEditorState();
    },

    _onPlatformReady: function() {
        this._sendToFlutter('editorReady');

        // anything reported before the bridge was ready got lost
        this._lastReportedHtml = null;
        this._lastReportedCommandStates = null;
        this._updateEditorState(true);
    },

    _sendToFlutter: function(handlerName, data) {
        var bridge = window.flutter_inappwebview;
        if(bridge && bridge.callHandler) {
            bridge.callHandler(handlerName, data);
        }
    },

    _ensureEditorInsertsParagraphWhenPressingEnter: function() {
        // see https://stackoverflow.com/a/36373967
        this._executeCommand("DefaultParagraphSeparator", "p");

        this._textField.innerHTML = ""; // clear previous content

        var newElement = document.createElement("p");
        newElement.innerHTML = "&#8203";
        this._textField.appendChild(newElement);

        var selection=document.getSelection();
        var range=document.createRange();
        range.setStart(newElement.firstChild, 1);
        selection.removeAllRanges();
        selection.addRange(range);
    },

    _initDragImageToResize: function() {
        interact.addDocument(window.document, {
          events: { passive: false },
        });

        interact('img.' + resizableImageClass)
        .resizable({
            edges: { top: true, left: true, right: true, bottom: true},

           // keep the edges inside the parent
            restrictEdges: {
                outer: 'parent',
                endOnly: true,
            },

            // minimum size
            restrictSize: {
                min: { width: this._imageMinWidth, height: this._imageMinHeight },
            },

            inertia: true,
            preserveAspectRatio: true,
        })
        .gesturable({
            onmove: function (event) {
                var target = event.target;

                // kept on the element, not in an attribute, so it stays out of the saved HTML
                var angle = (target._rotation || 0) + event.da;
                var normalized = ((angle % 360) + 360) % 360;

                [0, 90, 180, 270, 360].forEach(function(snap) {
                    if(Math.abs(snap - normalized) < 10) {
                        normalized = snap % 360;
                    }
                });
                target._rotation = normalized;

                target.style.transform = 'rotate(' + normalized + 'deg)';
            },
            onend: function () {
                editor._updateEditorState();
            }
        })
        .on('resizemove', function (event) {
            var target = event.target;
            var width = Math.round(event.rect.width);
            var height = Math.round(event.rect.height);

            target.style.width  = width + 'px';
            target.style.height = height + 'px';

            target.setAttribute('width', width);
            target.setAttribute('height', height);
        })
        .on('resizeend', function () {
            editor._updateEditorState();
        });
    },


    _handleTextEntered: function() {
        var html = this._getHtml();
        // SwiftKey, when deleting all entered text, inserts a pure "<br>" therefore check for <p>​&#8203</p> doesn't work anymore;
        // selecting everything and deleting it leaves no paragraph at all
        if(html == "<p><br></p>" || html == "<br>" || html == "") {
            this._ensureEditorInsertsParagraphWhenPressingEnter();
        }

        this._scheduleEditorStateUpdate();
    },

    // Whether element holds no text (ignoring the zero width space placeholder) and no media.
    _isEmpty: function(element) {
        var text = element.textContent.replace(/​/g, '').trim();

        return text.length == 0 && !element.querySelector('img, video, iframe, input, hr, table');
    },

    isEmpty: function() {
        return this._isEmpty(this._textField);
    },

    _handlePaste: function(event) {
        var clipboardData = event.clipboardData || window.clipboardData;
        if(!clipboardData) {
            return;
        }

        var pastedHtml = clipboardData.getData('text/html');
        var pastedText = clipboardData.getData('text/plain') || clipboardData.getData('text');
        if(!pastedHtml && !pastedText) { // e.g. a pasted screenshot
            var images = this._imageFiles(clipboardData.files);
            if(images.length > 0) {
                event.preventDefault();
                this._sendImagesToFlutter(images);
            }
            return;
        }

        event.preventDefault();

        if(pastedHtml) {
            this._insertHtml(this._sanitizeHtml(pastedHtml, true));
        }
        else {
            this._insertHtml(this._escapeHtml(pastedText).replace(/\r\n|\r|\n/g, '<br>'));
        }
    },

    _handleDrop: function(event) {
        var images = this._imageFiles(event.dataTransfer && event.dataTransfer.files);
        if(images.length == 0) {
            return;
        }

        event.preventDefault();
        if(document.caretRangeFromPoint) { // insert the images where they were dropped
            var range = document.caretRangeFromPoint(event.clientX, event.clientY);
            if(range) {
                var selection = window.getSelection();
                selection.removeAllRanges();
                selection.addRange(range);
                this._backupRange();
            }
        }
        this._sendImagesToFlutter(images);
    },

    _imageFiles: function(files) {
        return Array.prototype.filter.call(files || [], function(file) {
            return /^image\//.test(file.type);
        });
    },

    // Flutter uploads the images with getImageUrl, if given, and inserts them at the caret.
    _sendImagesToFlutter: function(images) {
        images.forEach(function(file) {
            var reader = new FileReader();
            reader.onload = function() {
                var dataUrl = reader.result;
                var image = new Image();
                image.onload = image.onerror = function() {
                    editor._sendToFlutter('imagePasted', {
                        'name': file.name,
                        'type': file.type,
                        'data': dataUrl.substring(dataUrl.indexOf(',') + 1),
                        'width': image.naturalWidth,
                        'height': image.naturalHeight
                    });
                };
                image.src = dataUrl;
            };
            reader.readAsDataURL(file);
        });
    },


    /*      Sanitizing      */

    // Returns the url if it is safe to put into an href/src attribute, null otherwise.
    // allowedDataPrefixes lists the data: URL types allowed, e.g. ['data:image/'].
    _safeUrl: function(url, allowedDataPrefixes) {
        if(url == null) {
            return null;
        }

        url = String(url).trim();
        // browsers ignore whitespace and control characters inside the scheme ("java\nscript:")
        var normalized = url.replace(/[\u0000- \u007F-\u009F]/g, '').toLowerCase();
        var match = normalized.match(/^([a-z][a-z0-9+.\-]*):/);

        if(!match) { // relative URL or file path
            return url;
        }

        if(match[1] === 'data') {
            var prefixes = allowedDataPrefixes || [];
            for(var i = 0; i < prefixes.length; i++) {
                if(normalized.indexOf(prefixes[i]) === 0) {
                    return url;
                }
            }
            return null;
        }

        return safeUrlSchemes.indexOf(match[1]) !== -1 ? url : null;
    },

    _escapeHtml: function(text) {
        var element = document.createElement('div');
        element.textContent = text;
        return element.innerHTML;
    },

    // Removes scripts, event handler attributes and unsafe URLs from html.
    // strict (used for pasted content) additionally reduces it to basic formatting tags, attributes and styles.
    _sanitizeHtml: function(html, strict) {
        // parsing into a separate document keeps the content inert: no scripts run and no images load
        var body = new DOMParser().parseFromString(html, 'text/html').body;
        if(!body) {
            return '';
        }

        this._sanitizeChildren(body, strict);

        return body.innerHTML;
    },

    _sanitizeChildren: function(parent, strict) {
        var children = Array.prototype.slice.call(parent.childNodes);

        for(var i = 0; i < children.length; i++) {
            var child = children[i];

            if(child.nodeType === Node.COMMENT_NODE) {
                parent.removeChild(child);
                continue;
            }
            if(child.nodeType !== Node.ELEMENT_NODE) {
                continue;
            }

            var tag = child.nodeName.toLowerCase();

            if(sanitizerDroppedTags.indexOf(tag) !== -1 || (strict && sanitizerPasteDroppedTags.indexOf(tag) !== -1)) {
                parent.removeChild(child);
                continue;
            }

            if(strict && sanitizerPasteTags.indexOf(tag) === -1) { // unwrap, keeping the content
                this._sanitizeChildren(child, strict);
                while(child.firstChild) {
                    parent.insertBefore(child.firstChild, child);
                }
                parent.removeChild(child);
                continue;
            }

            if(!this._sanitizeAttributes(child, tag, strict)) {
                parent.removeChild(child);
                continue;
            }

            this._sanitizeChildren(child, strict);
        }
    },

    // Returns false if the element has to be removed altogether.
    _sanitizeAttributes: function(element, tag, strict) {
        if(tag === 'input' && strict && (element.getAttribute('type') || '').toLowerCase() !== 'checkbox') {
            return false;
        }

        var allowedDataPrefixes = tag === 'img' ? ['data:image/'] :
                                  (tag === 'video' || tag === 'source') ? ['data:video/'] : [];
        var attributes = Array.prototype.slice.call(element.attributes);

        for(var i = 0; i < attributes.length; i++) {
            var name = attributes[i].name.toLowerCase();
            var value = attributes[i].value;

            var allowed = name.indexOf('on') !== 0 && name !== 'srcdoc';

            if(allowed && strict) {
                allowed = sanitizerPasteAttributes['*'].indexOf(name) !== -1 ||
                          (sanitizerPasteAttributes[tag] || []).indexOf(name) !== -1;
            }

            if(allowed && sanitizerUrlAttributes.indexOf(name) !== -1) {
                allowed = this._safeUrl(value, allowedDataPrefixes) !== null;
            }

            if(!allowed) {
                element.removeAttribute(attributes[i].name);
            }
        }

        if(tag === 'iframe' && !/^https?:\/\//i.test(element.getAttribute('src') || '')) {
            return false;
        }

        if(strict && element.hasAttribute('style')) {
            this._sanitizeStyle(element);
        }

        return true;
    },

    _sanitizeStyle: function(element) {
        var style = element.style;
        var kept = [];

        for(var i = 0; i < style.length; i++) {
            var property = style[i];
            var value = style.getPropertyValue(property);

            if(sanitizerPasteStyles.indexOf(property) !== -1 && value.toLowerCase().indexOf('url(') === -1) {
                kept.push(property + ': ' + value);
            }
        }

        if(kept.length > 0) {
            element.setAttribute('style', kept.join('; ') + ';');
        }
        else {
            element.removeAttribute('style');
        }
    },


    _getHtml: function() {
        return this._textField.innerHTML;
    },

    // The editor content as the application gets it: without resize classes and zero width spaces,
    // and empty when there is no content.
    _getHtmlWithoutInternalModifications: function() {
        var clonedHtml = this._textField.cloneNode(true);

        this._removeResizeImageClasses(clonedHtml);

        if(this._isEmpty(clonedHtml)) {
            return '';
        }

        var walker = document.createTreeWalker(clonedHtml, NodeFilter.SHOW_TEXT);
        while(walker.nextNode()) {
            if(walker.currentNode.nodeValue.indexOf('\u200B') !== -1) {
                walker.currentNode.nodeValue = walker.currentNode.nodeValue.replace(/\u200B/g, '');
            }
        }

        return clonedHtml.innerHTML;
    },

    getEncodedHtml: function() {
        return encodeURIComponent(this._getHtmlWithoutInternalModifications());
    },

    setHtml: function(html, baseUrl) {
        if(baseUrl) {
            this._setBaseUrl(baseUrl);
        }

        var safeHtml = html.length != 0 ? this._sanitizeHtml(html, false) : '';

        if(safeHtml.length != 0) {
            this._textField.innerHTML = safeHtml;

            if(this._isImageResizingEnabled) {
                this.makeImagesResizeable();
            }
        }
        else {
            this._ensureEditorInsertsParagraphWhenPressingEnter();
        }

        this._htmlSetByApplication = this._getHtmlWithoutInternalModifications();
        this._updatePlaceholder();
        this._updateEditorState(true);
    },

    _setBaseUrl: function(baseUrl) {
        var baseElements = document.head.getElementsByTagName('base');
        var baseElement = null;
        if(baseElements.length > 0) {
            baseElement = baseElements[0];
        }
        else {
            var baseElement = document.createElement('base');
            document.head.appendChild(baseElement); // don't know why but append() is not available
        }

        baseElement.setAttribute('href', baseUrl);
        baseElement.setAttribute('target', '_blank');
    },

    makeImagesResizeable: function() {
        this._isImageResizingEnabled = true;

        var images = document.getElementsByTagName("img");

        for(var i = 0; i < images.length; i++) {
            this._addClass(images[i], resizableImageClass);
        }
    },

    disableImageResizing: function() {
        this._isImageResizingEnabled = false;

        this._removeResizeImageClasses(document);
    },

    _removeResizeImageClasses: function(document) {
        var images = document.getElementsByTagName("img");

        for(var i = 0; i < images.length; i++) {
            this._removeClass(images[i], resizableImageClass);
        }
    },

    _hasClass: function(element, className) {
      return !!element.className.match(new RegExp('(\\s|^)' + className +'(\\s|$)'));
    },

    _addClass: function(element, className) {
      if (this._hasClass(element, className) == false) {
        element.className += " " + className;
      }
    },

    _removeClass: function(element, className) {
      if (this._hasClass(element, className)) {
        element.classList.remove(className);

        var classAttributeValue = element.getAttribute('class');
        if (!!! classAttributeValue) { // remove class attribute if no class is left to restore original html
            element.removeAttribute('class');
        }
      }
    },
    
    
    /*      Text Commands        */

    undo: function() {
        this._executeCommand('undo', null);
    },
    
    redo: function() {
        this._executeCommand('redo', null);
    },
    
    setBold: function() {
        this._executeCommand('bold', null);
    },
    
    setItalic: function() {
        this._executeCommand('italic', null);
    },

    setUnderline: function() {
        this._executeCommand('underline', null);
    },
    
    setSubscript: function() {
        this._executeCommand('subscript', null);
    },
    
    setSuperscript: function() {
        this._executeCommand('superscript', null);
    },
    
    setStrikeThrough: function() {
        this._executeCommand('strikeThrough', null);
    },

    setTextColor: function(color) {
        this._executeStyleCommand('foreColor', color);
    },

    setTextBackgroundColor: function(color) {
        if(/^rgba\(.*,\s*0(\.0*)?\)$/.test(color)) { // fully transparent; resetting backColor does not work with any color value (whether #00000000 nor rgba(0, 0, 0, 0)), we have to pass 'inherit'. Thanks to https://stackoverflow.com/a/7071465 for pointing this out to me
            this._executeStyleCommand('backColor', 'inherit');
        }
        else {
            this._executeStyleCommand('backColor', color);
        }
    },

    setFontName: function(fontName) {
        this._executeCommand("fontName", fontName);
    },

    setFontSize: function(fontSize) {
        this._executeCommand("fontSize", fontSize);
    },

    setHeading: function(heading) {
        this._executeCommand('formatBlock', '<h'+heading+'>');
    },

    setFormattingToParagraph: function() {
        this._executeCommand('formatBlock', '<p>');
    },

    setPreformat: function() {
        this._executeCommand('formatBlock', '<pre>');
    },

    setBlockQuote: function() {
        this._executeCommand('formatBlock', '<blockquote>');
    },

    removeFormat: function() {
        this._executeCommand('removeFormat', null);
    },
    
    setJustifyLeft: function() {
        this._executeCommand('justifyLeft', null);
    },
    
    setJustifyCenter: function() {
        this._executeCommand('justifyCenter', null);
    },
    
    setJustifyRight: function() {
        this._executeCommand('justifyRight', null);
    },

    setJustifyFull: function() {
        this._executeCommand('justifyFull', null);
    },

    setIndent: function() {
        this._executeCommand('indent', null);
    },

    setOutdent: function() {
        this._executeCommand('outdent', null);
    },

    insertBulletList: function() {
        this._executeCommand('insertUnorderedList', null);
    },

    insertNumberedList: function() {
        this._executeCommand('insertOrderedList', null);
    },


    /*      Insert elements             */

    insertLink: function(url, title) {
        var safeUrl = this._safeUrl(url);
        if(!safeUrl) {
            return;
        }

        this._restoreRange();
        var sel = document.getSelection();

        if (sel.toString().length == 0) {
            var link = document.createElement("a");
            link.setAttribute("href", safeUrl);
            link.textContent = title || url;
            this._insertHtml(link.outerHTML);
        }
        else if (sel.rangeCount) {
           var el = document.createElement("a");
           el.setAttribute("href", safeUrl);
           if (title) {
               el.setAttribute("title", title);
           }

           var range = sel.getRangeAt(0).cloneRange();
           try {
               range.surroundContents(el);
           }
           catch (e) { // selection only partially covers an element
               this._executeCommand('createLink', safeUrl);
               return;
           }
           sel.removeAllRanges();
           sel.addRange(range);

           this._updateEditorState();
       }
    },

    insertImage: function(url, alt, width, height, rotation) {
        var safeUrl = this._safeUrl(url, ['data:image/']);
        if(!safeUrl) {
            return;
        }

        var imageElement = document.createElement('img');

        imageElement.setAttribute('src', safeUrl);

        if(alt) {
            imageElement.setAttribute('alt', alt);
        }

        if(width)  {
            imageElement.setAttribute('width', width);
        }

        if(height)  {
            imageElement.setAttribute('height', height);
        }

        if(this._isImageResizingEnabled) {
            imageElement.setAttribute('class', resizableImageClass);
        }

        if(rotation)  {
            this._setImageRotation(imageElement, rotation);
        }

        this._insertHtml(imageElement.outerHTML);
    },

    _setImageRotation: function(imageElement, rotation) {
            if(rotation == 90) {
                this._addClass(imageElement, 'rotate90deg');
            }
            else if(rotation == 180) {
                this._addClass(imageElement, 'rotate180deg');
            }
            else if(rotation == 270) {
                this._addClass(imageElement, 'rotate270deg');
            }
    },

    insertVideo: function(url, width, height, fromDevice) {
        if (fromDevice) {
            this._insertVideo(url, width, height);
        } else {
            this._insertYoutubeVideo(url, width, height);
        }
    },
    
    _insertYoutubeVideo: function(url, width, height) {
        if(!/^https?:\/\//i.test(url)) {
            return;
        }

        var iframe = document.createElement('iframe');
        iframe.setAttribute('width', width);
        iframe.setAttribute('height', height);
        iframe.setAttribute('src', url);
        iframe.setAttribute('title', 'YouTube video player');
        iframe.setAttribute('frameborder', '0');
        iframe.setAttribute('allow', 'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture');
        iframe.setAttribute('referrerpolicy', 'strict-origin-when-cross-origin'); // the YouTube player refuses to play without one
        this._insertHtml(iframe.outerHTML);
    },

    _insertVideo: function(url, width, height) {
        var safeUrl = this._safeUrl(url, ['data:video/']);
        if(!safeUrl) {
            return;
        }

        var video = document.createElement('video');
        video.setAttribute('width', width);
        video.setAttribute('height', height);
        video.setAttribute('controls', '');

        var source = document.createElement('source');
        source.setAttribute('type', 'video/mp4');
        source.setAttribute('src', safeUrl);
        video.appendChild(source);

        this._insertHtml(video.outerHTML);
    },

    insertCheckbox: function(text) {
        var checkbox = document.createElement('input');
        checkbox.setAttribute('type', 'checkbox');
        checkbox.setAttribute('name', text);
        checkbox.setAttribute('value', text);

        this._insertHtml(checkbox.outerHTML + '&nbsp;' + this._escapeHtml(text));
    },

    _checkboxClicked: function(clickedCheckbox) {
        // incredible, checked attribute doesn't get set in html, see issue https://github.com/dankito/RichTextEditor/issues/24
        if (clickedCheckbox.checked) {
            clickedCheckbox.setAttribute('checked', 'checked');
        }
        else {
            clickedCheckbox.removeAttribute('checked');
        }

        this._updateEditorState();
    },

    insertHtml: function(html) {
        this._insertHtml(this._sanitizeHtml(html, false));
    },

    _insertHtml: function(html) {
        this._backupRange();
        this._restoreRange();

        document.execCommand('insertHTML', false, html);

        if(this._isImageResizingEnabled) {
            this.makeImagesResizeable();
        }

        this._updateEditorState();
    },
    
    
    /*      Editor default settings     */
    
    setBaseTextColor: function(color) {
        this._textField.style.color  = color;
    },

    setBaseFontFamily: function(fontFamily) {
        this._textField.style.fontFamily = fontFamily;
    },
    
    setBaseFontSize: function(size) {
        this._textField.style.fontSize = size;
    },
    
    setPadding: function(left, top, right, bottom) {
      this._textField.style.paddingLeft = left;
      this._textField.style.paddingTop = top;
      this._textField.style.paddingRight = right;
      this._textField.style.paddingBottom = bottom;
    },

    setBackgroundColor: function(color) {
        document.body.style.backgroundColor = color;
    },
    
    setBackgroundImage: function(image) {
        if(/^url\(/i.test(image)) { // already a CSS value
            this._textField.style.backgroundImage = image;
            return;
        }

        var safeUrl = this._safeUrl(image, ['data:image/']);
        this._textField.style.backgroundImage = safeUrl ? 'url(' + JSON.stringify(safeUrl) + ')' : '';
    },
    
    setWidth: function(size) {
        this._textField.style.minWidth = size;
    },
    
    setHeight: function(size) {
        this._textField.style.height = size;
    },
    
    setTextAlign: function(align) {
        this._textField.style.textAlign = align;
    },
    
    setVerticalAlign: function(align) {
        this._textField.style.verticalAlign = align;
    },
    
    setPlaceholder: function(placeholder) {
        this._textField.setAttribute("placeholder", placeholder);
        this._updatePlaceholder();
    },

    loadCSS: function(url) {
        var link = document.createElement("link");
        link.rel = "stylesheet";
        link.type = "text/css";
        link.href = url;
        link.media = "all";
        document.head.appendChild(link);
    },
    
    setInputEnabled: function(inputEnabled) {
        this._textField.contentEditable = String(inputEnabled);

        if(inputEnabled) {
            this.makeImagesResizeable();
        }
        else {
            this.disableImageResizing();
            this.blurFocus(); // hides the keyboard
        }
    },

    focus: function() {
        var range = document.createRange();
        range.selectNodeContents(this._textField);
        range.collapse(false);
        var selection = window.getSelection();
        selection.removeAllRanges();
        selection.addRange(range);
        this._textField.focus();
    },

    blurFocus: function() {
        this._textField.blur();
    },


    _executeStyleCommand: function(command, parameter) {
        document.execCommand("styleWithCSS", false, true);
        this._executeCommand(command, parameter);
        document.execCommand("styleWithCSS", false, false);
    },

    _executeCommand: function(command, parameter) {
        document.execCommand(command, false, parameter);

        this._updateEditorState();
    },


    // Typing and selecting fire many events in a row, and each report serializes the whole document,
    // so these are reported at most every 50 ms, less often for large documents.
    _scheduleEditorStateUpdate: function() {
        this._updatePlaceholder();
        if(this._editorStateUpdateTimer != null) {
            return;
        }

        var htmlLength = this._lastReportedHtml ? this._lastReportedHtml.length : 0;
        var delay = Math.min(50 + htmlLength / 1000, 1000); // e.g. 150 ms for 100 kB of HTML

        this._editorStateUpdateTimer = setTimeout(function() { editor._updateEditorState(); }, delay);
    },

    // Reports content and command states to Flutter when they changed.
    // fromApplication marks changes the application made itself, e.g. with setHtml().
    _updateEditorState: function(fromApplication) {
        clearTimeout(this._editorStateUpdateTimer);
        this._editorStateUpdateTimer = null;
        this._updatePlaceholder();

        var html = this._getHtmlWithoutInternalModifications();
        var commandStates = this._determineCommandStates();
        var commandStatesJson = JSON.stringify(commandStates);
        var htmlChanged = html !== this._lastReportedHtml;

        if(!htmlChanged && commandStatesJson === this._lastReportedCommandStates) {
            return;
        }

        this._lastReportedHtml = html;
        this._lastReportedCommandStates = commandStatesJson;

        var editorState = {
            'didHtmlChange': this._htmlSetByApplication != null ? html != this._htmlSetByApplication : html != '',
            'commandStates': commandStates,
            'fromApplication': fromApplication === true
        };
        if(htmlChanged) { // only send the possibly large html when needed
            editorState.html = html;
        }

        this._sendToFlutter('editorStateChanged', editorState);
    },

    _updatePlaceholder: function() {
        var showPlaceholder = !!this._textField.getAttribute('placeholder') && this._isEmpty(this._textField);

        this._textField.classList.toggle('placeholder-visible', showPlaceholder);
    },

    _determineCommandStates: function() {
        var commands = ['undo', 'redo', 'bold', 'italic', 'underline', 'subscript', 'superscript', 'strikeThrough',
            'foreColor', 'backColor', 'fontName', 'fontSize', 'formatBlock',
            'justifyLeft', 'justifyCenter', 'justifyRight', 'justifyFull',
            'insertUnorderedList', 'insertOrderedList'];
        var commandStates = {};

        for(var i = 0; i < commands.length; i++) {
            try {
                commandStates[commands[i]] = {
                    'enabled': document.queryCommandEnabled(commands[i]),
                    'active': document.queryCommandState(commands[i]),
                    'value': String(document.queryCommandValue(commands[i]))
                };
            }
            catch(e) { // unsupported command
            }
        }

        return commandStates;
    },


    _backupRange: function(){
        var selection = window.getSelection();
        if(selection.rangeCount > 0) {
          var range = selection.getRangeAt(0);

          this._currentSelection = {
              "startContainer": range.startContainer,
              "startOffset": range.startOffset,
              "endContainer": range.endContainer,
              "endOffset": range.endOffset
          };
        }
    },

    _restoreRange: function(){
        var selection = window.getSelection();
        selection.removeAllRanges();

        var range = document.createRange();
        range.setStart(this._currentSelection.startContainer, this._currentSelection.startOffset);
        range.setEnd(this._currentSelection.endContainer, this._currentSelection.endOffset);

        selection.addRange(range);
    },

}


editor.init();
