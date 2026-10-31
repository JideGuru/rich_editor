
// also edit class name in style.css when changing this.
const resizableImageClass = "resizable";

const EditorDefaultHtml = "<p>​</p>";

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

    _useWindowLocationForEditorStateChangedCallback: false,

    _imageMinWidth: 100,
    _imageMinHeight: 50,

    _isImageResizingEnabled: true,


    init: function() {
        document.addEventListener("selectionchange", function() {
            editor._backupRange();
            editor._handleTextEntered(); // in newly selected area different commands may be activated / deactivated
        });

        this._textField.addEventListener("keydown", function(e) {
            var BACKSPACE = 8;
            var M = 77;

            if(e.which == BACKSPACE) {
                if(editor._textField.innerText.length == 1) { // prevent that first paragraph gets deleted
                    e.preventDefault();

                    return false;
                }
            }
            else if(e.which == M && e.ctrlKey) { // TODO: what is Ctrl + M actually good for?
                e.preventDefault(); // but be aware in this way also (JavaFX) application won't be able to use Ctrl + M

                return false;
            }
        });

        this._textField.addEventListener("keyup", function(e) {
            if(e.altKey || e.ctrlKey) { // some key combinations activate commands like CTRL + B setBold() -> update editor state so that UI is aware of this
                editor._updateEditorState();
            }
        });

        this._textField.addEventListener("paste", function(e) { editor._handlePaste(e); });

        // Checkboxes are handled here rather than with inline onclick attributes, so saved HTML carries no script.
        this._textField.addEventListener("click", function(e) {
            var target = e.target;
            if (target && target.nodeName === 'INPUT' && target.type === 'checkbox') {
                editor._checkboxClicked(target);
            }
        });

        this._ensureEditorInsertsParagraphWhenPressingEnter();
        this._initDragImageToResize();
        this._updateEditorState();
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
        var angle = 0;

        interact.addDocument(window.document, {
          events: { passive: false },
        });

        interact('img.' + resizableImageClass)
        .draggable({
            onmove: window.dragMoveListener,
            restrict: {
                restriction: 'parent',
                elementRect: { top: 0, left: 0, bottom: 1, right: 1 }
            },
        })
        .resizable({
            // resize from right or bottom
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

                angle += event.da;

                if(Math.abs(90 - (angle % 360)) < 10){ angle = 90;}
                if(Math.abs(180 - (angle % 360)) < 10){ angle = 180;}
                if(Math.abs(270 - (angle % 360)) < 10){ angle = 270;}
                if(Math.abs(angle % 360) < 10){ angle = 0;}

                target.style.webkitTransform =
                target.style.transform =
                'rotate(' + angle + 'deg)';

            }
        })
        .on('resizemove', function (event) {

            var target = event.target,
                x = (parseFloat(target.getAttribute('data-x')) || 0),
                y = (parseFloat(target.getAttribute('data-y')) || 0);

            // update the element's style
            target.style.width  = event.rect.width + 'px';
            target.style.height = event.rect.height + 'px';

            target.width  = event.rect.width + 'px';
            target.height = event.rect.height + 'px';

            target.setAttribute('data-x', x);
            target.setAttribute('data-y', y);

        });
    },


    _handleTextEntered: function() {
        if(this._getHtml() == "<p><br></p>") { // SwiftKey, when deleting all entered text, inserts a pure "<br>" therefore check for <p>​&#8203</p> doesn't work anymore
            this._ensureEditorInsertsParagraphWhenPressingEnter();
        }

        this._updateEditorState();
    },

    _handlePaste: function(event) {
        var clipboardData = event.clipboardData || window.clipboardData;
        if(!clipboardData) {
            return;
        }

        var pastedHtml = clipboardData.getData('text/html');
        var pastedText = clipboardData.getData('text/plain') || clipboardData.getData('text');
        if(!pastedHtml && !pastedText) { // e.g. a pasted image file; the browser inserts that itself
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

    _getHtmlWithoutInternalModifications: function() {
        var clonedHtml = this._textField.cloneNode(true);

        this._removeResizeImageClasses(clonedHtml);

        return clonedHtml.innerHTML;
    },

    getEncodedHtml: function() {
        return encodeURIComponent(this._getHtmlWithoutInternalModifications());
    },

    setHtml: function(html, baseUrl) {
        if(baseUrl) {
            this._setBaseUrl(baseUrl);
        }

        if(html.length != 0) {
            var safeHtml = this._sanitizeHtml(html, false);
            this._textField.innerHTML = safeHtml;

            this._htmlSetByApplication = safeHtml;

            if(this._isImageResizingEnabled) {
                this.makeImagesResizeable();
            }
        }
        else {
            this._ensureEditorInsertsParagraphWhenPressingEnter();

            this._htmlSetByApplication = null;
        }

        this.didHtmlChange = false;
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

    useWindowLocationForEditorStateChangedCallback: function() {
        this._useWindowLocationForEditorStateChangedCallback = true;
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
        if(color == 'rgba(0, 0, 0, 0)') { // resetting backColor does not work with any color value (whether #00000000 nor rgba(0, 0, 0, 0)), we have to pass 'inherit'. Thanks to https://stackoverflow.com/a/7071465 for pointing this out to me
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

    // TODO: is this one ever user?
    setBackgroundColor: function(color) {
        document.body.style.backgroundColor = color;
    },
    
    setBackgroundImage: function(image) {
        this._textField.style.backgroundImage = image;
    },
    
    setWidth: function(size) {
        this._textField.style.minWidth = size; // TODO: why did i use minWidth here but height (not minHeight) below?
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
    },
    
    setInputEnabled: function(inputEnabled) {
        this._textField.contentEditable = String(inputEnabled);

        if(inputEnabled) { // TODO: may interferes with _isImageResizingEnabled
            this.makeImagesResizeable();
        }
        else {
            this.disableImageResizing();
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
        this._executeCommand("styleWithCSS", null, true);
        this._executeCommand(command, parameter);
        this._executeCommand("styleWithCSS", null, false);
    },

    _executeCommand: function(command, parameter) {
        document.execCommand(command, false, parameter);

        this._updateEditorState();
    },


    _updateEditorState: function() {
        var html = this._getHtmlWithoutInternalModifications();
        var didHtmlChange = (this._htmlSetByApplication != null && this._htmlSetByApplication != html) || // html set by application changed
                            (this._htmlSetByApplication == null && html != EditorDefaultHtml); // or if html not set by application: default html changed

        if (typeof editorCallback !== 'undefined') { // in most applications like in the JavaFX app changing window.location.href doesn't work -> tell them via callback that editor state changed
            editorCallback.updateEditorState(didHtmlChange) // these applications determine editor state manually
        }
        else if (this._useWindowLocationForEditorStateChangedCallback) { // Android can handle changes to windows.location -> communicate editor changes via a self defined protocol name
            var commandStates = this._determineCommandStates();

            var editorState = {
                'didHtmlChange': didHtmlChange,
                'html': html, // TODO: remove in upcoming versions
                'commandStates': commandStates
            };

            window.location.href = "editor-state-changed-callback://" + encodeURIComponent(JSON.stringify(editorState));
        }
    },

    _determineCommandStates: function() {
        var commandStates = {};

        this._determineStateForCommand('undo', commandStates);
        this._determineStateForCommand('redo', commandStates);

        this._determineStateForCommand('bold', commandStates);
        this._determineStateForCommand('italic', commandStates);
        this._determineStateForCommand('underline', commandStates);
        this._determineStateForCommand('subscript', commandStates);
        this._determineStateForCommand('superscript', commandStates);
        this._determineStateForCommand('strikeThrough', commandStates);

        this._determineStateForCommand('foreColor', commandStates);
        this._determineStateForCommand('backColor', commandStates);

        this._determineStateForCommand('fontName', commandStates);
        this._determineStateForCommand('fontSize', commandStates);

        this._determineStateForCommand('formatBlock', commandStates);
        this._determineStateForCommand('removeFormat', commandStates);

        this._determineStateForCommand('justifyLeft', commandStates);
        this._determineStateForCommand('justifyCenter', commandStates);
        this._determineStateForCommand('justifyRight', commandStates);
        this._determineStateForCommand('justifyFull', commandStates);

        this._determineStateForCommand('indent', commandStates);
        this._determineStateForCommand('outdent', commandStates);

        this._determineStateForCommand('insertUnorderedList', commandStates);
        this._determineStateForCommand('insertOrderedList', commandStates);
        this._determineStateForCommand('insertHorizontalRule', commandStates);
        this._determineStateForCommand('insertHTML', commandStates);

        return commandStates;
    },

    _determineStateForCommand: function(command, commandStates) {
        commandStates[command.toUpperCase()] = {
            'executable': document.queryCommandEnabled(command),
            'value': document.queryCommandValue(command)
        }
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
