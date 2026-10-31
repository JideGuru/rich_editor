// The editor page's script: a Tiptap editor behind the `editor` object the Flutter side calls
// (see lib/src/utils/javascript_executor_base.dart), which reports back through the
// editorReady, editorStateChanged and imagePasted handlers.

import './polyfills.js';
import { Editor } from '@tiptap/core';
import { NodeSelection, TextSelection } from '@tiptap/pm/state';
import StarterKit from '@tiptap/starter-kit';
import Link from '@tiptap/extension-link';
import { TextStyleKit } from '@tiptap/extension-text-style';
import TextAlign from '@tiptap/extension-text-align';
import Subscript from '@tiptap/extension-subscript';
import Superscript from '@tiptap/extension-superscript';
import { Placeholder } from '@tiptap/extensions';
import { legacyFontSizes, normalizeHtml, safeUrl } from './html.js';
import { Checkbox, Iframe, Image, Indent, Video, maxIndent, normalizeRotation, selectedImageClass } from './nodes.js';

// set on the editable element while images can be resized
const resizableImagesClass = 'images-resizable';

// Nodes that are content even without text.
const mediaNodes = ['image', 'checkbox', 'video', 'iframe', 'horizontalRule'];

const editor = {

    _tiptap: null,

    // the editable element
    _textField: null,

    _htmlSetByApplication: null,

    // last state sent to Flutter, so unchanged states aren't sent again
    _lastReportedHtml: null,
    _lastReportedCommandStates: null,

    // pending _updateEditorState() for typing and selecting, see _scheduleEditorStateUpdate()
    _editorStateUpdateTimer: null,

    _placeholder: '',

    _imageMinWidth: 100,
    _imageMinHeight: 50,

    _isImageResizingEnabled: true,

    _safeUrl: safeUrl,


    init: function() {
        this._tiptap = new Editor({
            element: document.getElementById('editor'),
            extensions: [
                StarterKit.configure({
                    link: false,
                    heading: { levels: [1, 2, 3, 4, 5, 6] },
                    // an empty paragraph to type into after media at the end, not after text blocks
                    trailingNode: { notAfter: ['paragraph', 'heading', 'bulletList', 'orderedList', 'blockquote', 'codeBlock'] },
                }),
                Link.extend({
                    // text typed right after a link is not part of it
                    inclusive: () => false,
                }).configure({
                    openOnClick: false,
                    enableClickSelection: false,
                    defaultProtocol: 'https',
                    HTMLAttributes: { target: null, rel: null, class: null },
                    isAllowedUri: (url) => safeUrl(url) !== null,
                }),
                TextStyleKit.configure({ lineHeight: false }),
                TextAlign.configure({ types: ['heading', 'paragraph'] }),
                Subscript,
                Superscript,
                Placeholder.configure({
                    placeholder: () => editor._placeholder,
                    showOnlyWhenEditable: false,
                }),
                Image,
                Checkbox,
                Video,
                Iframe,
                Indent,
            ],
            content: '',
            editorProps: {
                handlePaste: (view, event) => editor._handlePaste(event),
                handleDrop: (view, event, slice, moved) => !moved && editor._handleDrop(view, event),
                transformPastedHTML: (html) => normalizeHtml(html, true),
            },
            onTransaction: () => editor._scheduleEditorStateUpdate(),
        });
        this._textField = this._tiptap.view.dom;
        this._textField.classList.add(resizableImagesClass);

        window.addEventListener('flutterInAppWebViewPlatformReady', function() {
            editor._onPlatformReady();
        });

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

    _initDragImageToResize: function() {
        var interact = window.interact;
        if(!interact) {
            return;
        }

        interact.addDocument(window.document, {
            events: { passive: false },
        });

        interact('.' + resizableImagesClass + ' img.' + selectedImageClass)
        .resizable({
            edges: { top: true, left: true, right: true, bottom: true },

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
            onmove: function(event) {
                var target = event.target;
                var normalized = normalizeRotation((target._rotation || 0) + event.da);

                [0, 90, 180, 270, 360].forEach(function(snap) {
                    if(Math.abs(snap - normalized) < 10) {
                        normalized = snap % 360;
                    }
                });
                target._rotation = normalized;

                target.style.transform = 'rotate(' + normalized + 'deg)';
            },
            onend: function(event) {
                event.target._updateAttributes({ rotation: event.target._rotation });
            }
        })
        .on('resizemove', function(event) {
            var target = event.target;
            target._resizedTo = { width: Math.round(event.rect.width), height: Math.round(event.rect.height) };

            target.style.width = target._resizedTo.width + 'px';
            target.style.height = target._resizedTo.height + 'px';
        })
        .on('resizeend', function(event) {
            if(event.target._resizedTo) {
                event.target._updateAttributes(event.target._resizedTo);
                event.target._resizedTo = null;
            }
        });
    },

    _handlePaste: function(event) {
        var clipboardData = event.clipboardData;
        // text and HTML are parsed into the editor's content by ProseMirror
        if(!clipboardData || clipboardData.getData('text/html') || clipboardData.getData('text/plain')) {
            return false;
        }

        var images = this._imageFiles(clipboardData.files); // e.g. a pasted screenshot
        if(images.length == 0) {
            return false;
        }
        this._sendImagesToFlutter(images);
        return true;
    },

    _handleDrop: function(view, event) {
        var images = this._imageFiles(event.dataTransfer && event.dataTransfer.files);
        if(images.length == 0) {
            return false;
        }

        // insert the images where they were dropped
        var dropped = view.posAtCoords({ left: event.clientX, top: event.clientY });
        if(dropped) {
            view.dispatch(view.state.tr.setSelection(TextSelection.create(view.state.doc, dropped.pos)));
        }
        this._sendImagesToFlutter(images);
        return true;
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
                var image = new window.Image();
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


    /*      Content      */

    // Whether the editor holds no text (whitespace aside) and no media.
    isEmpty: function() {
        var hasMedia = false;
        this._tiptap.state.doc.descendants(function(node) {
            hasMedia = hasMedia || mediaNodes.indexOf(node.type.name) !== -1;
            return !hasMedia;
        });
        return !hasMedia && this._tiptap.state.doc.textContent.replace(/[\s\u00A0\u200B]/g, '') === '';
    },

    // The editor content as the application gets it: empty when there is no content.
    _getHtml: function() {
        return this.isEmpty() ? '' : this._tiptap.getHTML();
    },

    getEncodedHtml: function() {
        return encodeURIComponent(this._getHtml());
    },

    // The text without markup: each paragraph, heading and list item on a line of its own, and
    // line breaks as new lines.
    getEncodedText: function() {
        var lines = [];
        if(!this.isEmpty()) {
            this._tiptap.state.doc.descendants(function(node) {
                if(!node.isTextblock) {
                    return true;
                }
                lines.push(node.textBetween(0, node.content.size, undefined, function(leaf) {
                    return leaf.type.name === 'hardBreak' ? '\n' : '';
                }));
                return false;
            });
        }
        return encodeURIComponent(lines.join('\n').replace(/\u200B/g, '').replace(/\n+$/, ''));
    },

    // The content as Tiptap / ProseMirror JSON.
    getEncodedJson: function() {
        return encodeURIComponent(JSON.stringify(this._tiptap.getJSON()));
    },

    setHtml: function(html) {
        this._setContent(normalizeHtml(html));
    },

    // Returns false, leaving the content as it was, when json does not fit the editor's schema.
    setJson: function(json) {
        try {
            this._tiptap.schema.nodeFromJSON(json).check();
        }
        catch(e) {
            console.error('setJson: ' + e.message);
            return false;
        }
        this._setContent(json);
        return true;
    },

    _setContent: function(content) {
        this._tiptap.chain()
            .setMeta('addToHistory', false) // undo doesn't bring back what was there before
            .setContent(content, { emitUpdate: false })
            .run();

        this._htmlSetByApplication = this._getHtml();
        this._updateEditorState(true);
    },

    makeImagesResizeable: function() {
        this._isImageResizingEnabled = true;
        this._updateImageResizing();
    },

    disableImageResizing: function() {
        this._isImageResizingEnabled = false;
        this._updateImageResizing();
    },

    _updateImageResizing: function() {
        this._textField.classList.toggle(resizableImagesClass, this._isImageResizingEnabled && this._tiptap.isEditable);
    },


    /*      Text Commands        */

    // Runs commands on a chain that focuses the editor first, e.g. c => c.toggleBold().
    _run: function(commands) {
        commands(this._tiptap.chain().focus()).run();
        this._updateEditorState();
    },

    undo: function() {
        this._run(function(c) { return c.undo(); });
    },

    redo: function() {
        this._run(function(c) { return c.redo(); });
    },

    setBold: function() {
        this._run(function(c) { return c.toggleBold(); });
    },

    setItalic: function() {
        this._run(function(c) { return c.toggleItalic(); });
    },

    setUnderline: function() {
        this._run(function(c) { return c.toggleUnderline(); });
    },

    setSubscript: function() {
        this._run(function(c) { return c.unsetSuperscript().toggleSubscript(); });
    },

    setSuperscript: function() {
        this._run(function(c) { return c.unsetSubscript().toggleSuperscript(); });
    },

    setStrikeThrough: function() {
        this._run(function(c) { return c.toggleStrike(); });
    },

    setTextColor: function(color) {
        this._run(function(c) { return c.setColor(color); });
    },

    setTextBackgroundColor: function(color) {
        if(/^rgba\(.*,\s*0(\.0*)?\)$/.test(color)) { // fully transparent
            this._run(function(c) { return c.unsetBackgroundColor(); });
        }
        else {
            this._run(function(c) { return c.setBackgroundColor(color); });
        }
    },

    setFontName: function(fontName) {
        this._run(function(c) { return c.setFontFamily(fontName); });
    },

    // 1 to 7, the sizes of <font size>.
    setFontSize: function(fontSize) {
        var size = legacyFontSizes[Math.min(Math.max(fontSize, 1), 7) - 1];
        this._run(function(c) { return c.setFontSize(size); });
    },

    setHeading: function(heading) {
        this._run(function(c) { return c.setHeading({ level: heading }); });
    },

    // Also takes the paragraph out of a quote, which is how the toolbar removes quotes.
    setFormattingToParagraph: function() {
        this._run(function(c) { return c.setParagraph().lift('blockquote'); });
    },

    setPreformat: function() {
        this._run(function(c) { return c.setCodeBlock(); });
    },

    setBlockQuote: function() {
        this._run(function(c) { return c.setBlockquote(); });
    },

    // Removes the text formatting, keeping links.
    removeFormat: function() {
        this._run(function(c) {
            return c.command(function(props) {
                var tr = props.tr;
                var selection = tr.selection;
                Object.keys(props.state.schema.marks).forEach(function(name) {
                    var type = props.state.schema.marks[name];
                    if(name === 'link') {
                        return;
                    }
                    if(selection.empty) {
                        tr.removeStoredMark(type);
                    }
                    else {
                        selection.ranges.forEach(function(range) {
                            tr.removeMark(range.$from.pos, range.$to.pos, type);
                        });
                    }
                });
                return true;
            });
        });
    },

    setJustifyLeft: function() {
        this._run(function(c) { return c.setTextAlign('left'); });
    },

    setJustifyCenter: function() {
        this._run(function(c) { return c.setTextAlign('center'); });
    },

    setJustifyRight: function() {
        this._run(function(c) { return c.setTextAlign('right'); });
    },

    setJustifyFull: function() {
        this._run(function(c) { return c.setTextAlign('justify'); });
    },

    // List items nest one level deeper; other paragraphs and headings move inwards.
    setIndent: function() {
        if(this._tiptap.isActive('listItem')) {
            this._run(function(c) { return c.sinkListItem('listItem'); });
        }
        else {
            this._run(function(c) { return c.command(editor._changeIndent(1)); });
        }
    },

    setOutdent: function() {
        if(this._tiptap.isActive('listItem')) {
            this._run(function(c) { return c.liftListItem('listItem'); });
        }
        else {
            this._run(function(c) { return c.command(editor._changeIndent(-1)); });
        }
    },

    _changeIndent: function(steps) {
        return function(props) {
            var tr = props.tr;
            var changed = false;
            tr.doc.nodesBetween(tr.selection.from, tr.selection.to, function(node, position) {
                if(node.type.name !== 'paragraph' && node.type.name !== 'heading') {
                    return true;
                }
                var indent = Math.min(Math.max((node.attrs.indent || 0) + steps, 0), maxIndent);
                if(indent !== node.attrs.indent) {
                    tr.setNodeMarkup(position, undefined, Object.assign({}, node.attrs, { indent: indent }));
                    changed = true;
                }
                return false;
            });
            return changed;
        };
    },

    insertBulletList: function() {
        this._run(function(c) { return c.toggleBulletList(); });
    },

    insertNumberedList: function() {
        this._run(function(c) { return c.toggleOrderedList(); });
    },


    /*      Insert elements             */

    insertLink: function(url, title) {
        var href = safeUrl(url);
        if(!href) {
            return;
        }

        if(this._tiptap.state.selection.empty) {
            this._run(function(c) {
                return c.insertContent({ type: 'text', text: title || url, marks: [{ type: 'link', attrs: { href: href } }] });
            });
        }
        else {
            this._run(function(c) { return c.setLink({ href: href, title: title || null }); });
        }
    },

    // Changes the URL of the link the caret is in, leaving the caret after the link.
    editLink: function(url) {
        var href = safeUrl(url);
        if(!href || !this._tiptap.isActive('link')) {
            return;
        }

        this._run(function(c) {
            return c.extendMarkRange('link').setLink({ href: href }).command(function(props) {
                props.tr.setSelection(TextSelection.create(props.tr.doc, props.tr.selection.to));
                return true;
            });
        });
    },

    // Removes the link the caret is in, keeping its text.
    removeLink: function() {
        if(this._tiptap.isActive('link')) {
            this._run(function(c) { return c.extendMarkRange('link').unsetLink(); });
        }
    },

    insertImage: function(url, alt, width, height, rotation) {
        var src = safeUrl(url, ['data:image/']);
        if(!src) {
            return;
        }

        this._run(function(c) {
            return c.insertContent({ type: 'image', attrs: {
                src: src,
                alt: alt || null,
                width: width || null,
                height: height || null,
                rotation: normalizeRotation(rotation || 0),
            } });
        });
    },

    insertVideo: function(url, width, height, fromDevice) {
        var node;
        if(fromDevice) {
            node = safeUrl(url, ['data:video/']) && { type: 'video', attrs: { src: url, width: width, height: height } };
        }
        else {
            node = /^https?:\/\//i.test(url) && { type: 'iframe', attrs: { src: url, width: width, height: height, title: 'YouTube video player' } };
        }
        if(node) {
            this._run(function(c) { return c.insertContent(node).command(editor._caretAfterInsertedBlock); });
        }
    },

    // Inserting a video leaves it selected, so whatever is typed next would replace it. Puts the caret
    // into the paragraph after it instead, adding one if there is none.
    _caretAfterInsertedBlock: function(props) {
        var tr = props.tr;
        if(!(tr.selection instanceof NodeSelection)) {
            return true;
        }
        var after = tr.selection.to;
        var next = tr.doc.resolve(after).nodeAfter;
        if(!next || !next.isTextblock) {
            tr.insert(after, props.state.schema.nodes.paragraph.create());
        }
        tr.setSelection(TextSelection.create(tr.doc, after + 1));
        return true;
    },

    insertCheckbox: function(text) {
        this._run(function(c) {
            return c.insertContent([
                { type: 'checkbox', attrs: { name: text || null, value: text || null } },
                { type: 'text', text: '\u00A0' + (text || '') },
            ]);
        });
    },

    // Inserts HTML at the caret; what the editor has no nodes or marks for is dropped.
    insertHtml: function(html) {
        var normalized = normalizeHtml(html);
        if(normalized) {
            this._run(function(c) { return c.insertContent(normalized); });
        }
    },


    /*      Editor default settings     */

    setBaseTextColor: function(color) {
        this._textField.style.color = color;
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

    // 'light' or 'dark': the colors of links, checkboxes, the caret and selections.
    setColorScheme: function(scheme) {
        document.documentElement.style.colorScheme = scheme;
    },

    // 'ltr' or 'rtl': which side text starts on, and where the caret goes.
    setTextDirection: function(direction) {
        document.documentElement.dir = direction;
        this._updateEditorState(); // the default alignment follows
    },

    setBackgroundImage: function(image) {
        if(/^url\(/i.test(image)) { // already a CSS value
            this._textField.style.backgroundImage = image;
            return;
        }

        var src = safeUrl(image, ['data:image/']);
        this._textField.style.backgroundImage = src ? 'url(' + JSON.stringify(src) + ')' : '';
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
        this._placeholder = placeholder;
        // the placeholder is drawn with the next update
        this._tiptap.view.dispatch(this._tiptap.state.tr.setMeta('addToHistory', false));
    },

    loadCSS: function(url) {
        var link = document.createElement('link');
        link.rel = 'stylesheet';
        link.type = 'text/css';
        link.href = url;
        link.media = 'all';
        document.head.appendChild(link);
    },

    setInputEnabled: function(inputEnabled) {
        this._tiptap.setEditable(!!inputEnabled, false);
        this._updateImageResizing();

        if(!inputEnabled) {
            this.blurFocus(); // hides the keyboard
        }
    },

    focus: function() {
        this._tiptap.commands.focus('end');
        this._showKeyboard();
    },

    // Focusing from script doesn't open the keyboard on Android. The VirtualKeyboard API can, once the
    // user has interacted with the page, but only while the editor asks for manual keyboard control,
    // which is reset after the request was handled so tapping the editor opens the keyboard again.
    _showKeyboard: function() {
        var keyboard = navigator.virtualKeyboard;
        if(!keyboard || !keyboard.show) {
            return;
        }

        var textField = this._textField;
        textField.setAttribute('virtualkeyboardpolicy', 'manual');
        keyboard.show();
        setTimeout(function() { textField.removeAttribute('virtualkeyboardpolicy'); }, 300);
    },

    blurFocus: function() {
        this._tiptap.commands.blur();
        this._textField.blur();
    },


    // Typing and selecting fire many transactions in a row, and each report serializes the whole
    // document, so these are reported at most every 50 ms, less often for large documents.
    _scheduleEditorStateUpdate: function() {
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

        var html = this._getHtml();
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

    // The states under the names of the document.execCommand commands the previous editor used.
    _determineCommandStates: function() {
        var tiptap = this._tiptap;
        var state = function(active, value) {
            return { 'enabled': true, 'active': !!active, 'value': value == null ? '' : String(value) };
        };
        var textStyle = tiptap.getAttributes('textStyle');
        var alignment = this._alignment();
        var list = this._innermost(['bulletList', 'orderedList']);
        var fontSizeIndex = legacyFontSizes.indexOf(textStyle.fontSize);
        var isLink = tiptap.isActive('link');

        return {
            'undo': { 'enabled': tiptap.can().undo(), 'active': false, 'value': '' },
            'redo': { 'enabled': tiptap.can().redo(), 'active': false, 'value': '' },
            'bold': state(tiptap.isActive('bold')),
            'italic': state(tiptap.isActive('italic')),
            'underline': state(tiptap.isActive('underline')),
            'subscript': state(tiptap.isActive('subscript')),
            'superscript': state(tiptap.isActive('superscript')),
            'strikeThrough': state(tiptap.isActive('strike')),
            'foreColor': state(false, textStyle.color),
            'backColor': state(false, textStyle.backgroundColor),
            'fontName': state(false, textStyle.fontFamily),
            'fontSize': state(false, fontSizeIndex !== -1 ? fontSizeIndex + 1 : textStyle.fontSize),
            'formatBlock': state(false, this._blockFormat()),
            'justifyLeft': state(alignment === 'left'),
            'justifyCenter': state(alignment === 'center'),
            'justifyRight': state(alignment === 'right'),
            'justifyFull': state(alignment === 'justify'),
            'insertUnorderedList': state(list === 'bulletList'),
            'insertOrderedList': state(list === 'orderedList'),
            'link': state(isLink, isLink ? tiptap.getAttributes('link').href : ''),
        };
    },

    // The name of the innermost node around the caret out of names, or null.
    _innermost: function(names) {
        var $from = this._tiptap.state.selection.$from;
        for(var depth = $from.depth; depth > 0; depth--) {
            var name = $from.node(depth).type.name;
            if(names.indexOf(name) !== -1) {
                return name;
            }
        }
        return null;
    },

    // h1 - h6, pre, blockquote for a paragraph in a quote, or p.
    _blockFormat: function() {
        var block = this._tiptap.state.selection.$from.parent;
        if(block.type.name === 'heading') {
            return 'h' + block.attrs.level;
        }
        if(block.type.name === 'codeBlock') {
            return 'pre';
        }
        return this._innermost(['blockquote']) ? 'blockquote' : 'p';
    },

    _alignment: function() {
        var block = this._tiptap.state.selection.$from.parent;
        return block.attrs.textAlign || (document.documentElement.dir === 'rtl' ? 'right' : 'left');
    },

};

window.editor = editor;
editor.init();
