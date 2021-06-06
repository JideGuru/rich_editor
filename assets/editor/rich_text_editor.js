
// also edit class name in style.css when changing this.
const resizableImageClass = "resizable";

const EditorDefaultHtml = "<p>​</p>";


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
        var pastedData = clipboardData.getData('text/html') || clipboardData.getData('text').replace(/(?:\r\n|\r|\n)/g, '<br />'); // replace new lines // TODO: may use 'text/plain' instead of 'text'

        this._waitTillPastedDataInserted(event, pastedData);
    },

    _waitTillPastedDataInserted: function(event, pastedData) {
        var previousHtml = this._getHtml();

        setTimeout(function () { // on paste event inserted text is not inserted yet -> wait for till text has been inserted
            editor._waitTillPastedTextInserted(previousHtml, 10, pastedData); // max 10 tries, after that we give up to prevent endless loops
        }, 100);
    },

    _waitTillPastedTextInserted: function(previousHtml, iteration, pastedData) {
        var hasBeenInserted = this._getHtml() != previousHtml;

        if(hasBeenInserted || ! iteration) {
            // there seems to be a bug (on Linux only?) when pasting data e.g. from Firefox: then only '' gets inserted
            if((this._getHtml().indexOf('​ÿþ&lt;') !== -1 || this._getHtml().indexOf('ÿþ&lt;<br>') !== -1) && previousHtml.indexOf('​​ÿþ&lt;') === -1) {
                this._textField.innerHTML = this._getHtml().replace('​ÿþ&lt;', pastedData).replace('ÿþ&lt;<br>', pastedData);
                // TODO: set caret to end of pasted data
            }

            this._updateEditorState();
        }
        else {
            setTimeout(function () { // wait for till pasted data has been inserted
                editor._waitTillPastedTextInserted(pastedText, iteration - 1);
            }, 100);
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
            var decodedHtml = this._decodeHtml(html);
            this._textField.innerHTML = decodedHtml;

            this._htmlSetByApplication = decodedHtml;

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

    _decodeHtml: function(html) {
        return decodeURIComponent(html.replace(/\+/g, '%20'));
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
        this._restoreRange();
        var sel = document.getSelection();

        if (sel.toString().length == 0) {
            this._insertHtml("<a href='"+url+"'>"+title+"</a>");
        }
        else if (sel.rangeCount) {
           var el = document.createElement("a");
           el.setAttribute("href", url);
           el.setAttribute("title", title);

           var range = sel.getRangeAt(0).cloneRange();
           range.surroundContents(el);
           sel.removeAllRanges();
           sel.addRange(range);

           this._updateEditorState();
       }
    },

    insertImage: function(url, alt, width, height, rotation) {
        var imageElement = document.createElement('img');

        imageElement.setAttribute('src', url);

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
    console.log(url);
        if (fromDevice) {
            this._insertVideo(url, width, height);
        } else {
            this._insertYoutubeVideo(url, width, height);
        }
    },
    
    _insertYoutubeVideo: function(url, width, height) {
        var html = '<iframe width="'+ width +'" height="'+ height +'" src="' + url + '" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"></iframe>';
        this._insertHtml(html);
    },

    _insertVideo: function(url, width, height) {
        var html = '<video width="'+ width +'" height="'+ height +'" controls><source type="video/mp4" src="'+ url +'"></video>'
        this._insertHtml(html);
    },

    insertCheckbox: function(text) {
        var editor = this;

        var html = '<input type="checkbox" name="'+ text +'" value="'+ text +'" onclick="editor._checkboxClicked(this)"/> &nbsp;';
        this._insertHtml(html);
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

    insertHtml: function(encodedHtml) {
        var html = this._decodeHtml(encodedHtml);
        this._insertHtml(html);
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
