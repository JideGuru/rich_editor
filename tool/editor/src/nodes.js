// The content the starter kit has no nodes for: inline checkboxes, images keeping their size and
// rotation, videos, embedded players, and paragraph indent.

import { Extension, Node } from '@tiptap/core';
import { safeUrl } from './html.js';

// the tapped image, which alone takes touches for resizing, so dragging over other images scrolls
export const selectedImageClass = 'selected-image';

function numberAttribute(element, name) {
    const value = parseInt(element.getAttribute(name), 10);
    return value > 0 ? value : null;
}

function pixels(cssValue) {
    const match = /^([\d.]+)px$/.exec(cssValue || '');
    return match ? Math.round(parseFloat(match[1])) : null;
}

// 0, 90, 180 or 270 classes of the previous editor, or any rotate() transform.
function rotationOf(element) {
    const classMatch = /(?:^|\s)rotate(90|180|270)deg(?:\s|$)/.exec(element.getAttribute('class') || '');
    if(classMatch) {
        return parseInt(classMatch[1], 10);
    }
    const transformMatch = /rotate\(\s*(-?[\d.]+)deg\s*\)/.exec(element.style.transform || '');
    return transformMatch ? normalizeRotation(parseFloat(transformMatch[1])) : 0;
}

export function normalizeRotation(angle) {
    return Math.round(((angle % 360) + 360) % 360);
}

const imageDataPrefixes = ['data:image/'];
const videoDataPrefixes = ['data:video/'];

export const Image = Node.create({
    name: 'image',
    inline: true,
    group: 'inline',
    atom: true,
    draggable: false,

    addAttributes() {
        return {
            src: {
                default: null,
                renderHTML: (attributes) => {
                    const src = safeUrl(attributes.src, imageDataPrefixes);
                    return src ? { src } : {};
                },
            },
            alt: { default: null },
            title: { default: null },
            width: {
                default: null,
                parseHTML: (element) => numberAttribute(element, 'width') || pixels(element.style.width),
            },
            height: {
                default: null,
                parseHTML: (element) => numberAttribute(element, 'height') || pixels(element.style.height),
            },
            rotation: {
                default: 0,
                parseHTML: rotationOf,
                renderHTML: (attributes) => attributes.rotation ? { style: `transform: rotate(${attributes.rotation}deg)` } : {},
            },
        };
    },

    parseHTML() {
        return [{
            tag: 'img[src]',
            getAttrs: (element) => safeUrl(element.getAttribute('src'), imageDataPrefixes) ? null : false,
        }];
    },

    renderHTML({ HTMLAttributes }) {
        return ['img', HTMLAttributes];
    },

    addNodeView() {
        return ({ node, getPos, editor }) => {
            const image = document.createElement('img');

            const show = (current) => {
                ['alt', 'title', 'width', 'height'].forEach((name) => {
                    if(current.attrs[name] != null) {
                        image.setAttribute(name, current.attrs[name]);
                    }
                    else {
                        image.removeAttribute(name);
                    }
                });
                const src = safeUrl(current.attrs.src, imageDataPrefixes);
                if(src) {
                    image.setAttribute('src', src);
                }
                // resizing and rotating draw on the style until the gesture ends
                image.style.width = '';
                image.style.height = '';
                image.style.transform = current.attrs.rotation ? `rotate(${current.attrs.rotation}deg)` : '';
                image._rotation = current.attrs.rotation;
            };
            show(node);

            // called by the resize and rotate gestures once they end
            image._updateAttributes = (attributes) => {
                const position = getPos();
                if(typeof position === 'number') {
                    editor.view.dispatch(editor.state.tr.setNodeMarkup(position, undefined,
                        Object.assign({}, node.attrs, attributes)));
                }
            };

            return {
                dom: image,
                update: (updated) => {
                    if(updated.type !== node.type) {
                        return false;
                    }
                    node = updated;
                    show(node);
                    return true;
                },
                selectNode: () => image.classList.add(selectedImageClass),
                deselectNode: () => image.classList.remove(selectedImageClass),
                // the gestures change the element; the attributes follow when they end
                ignoreMutation: () => true,
            };
        };
    },
});

// An inline <input type="checkbox">, followed by its label as ordinary text.
export const Checkbox = Node.create({
    name: 'checkbox',
    inline: true,
    group: 'inline',
    atom: true,
    selectable: false,

    addAttributes() {
        return {
            checked: {
                default: false,
                parseHTML: (element) => element.hasAttribute('checked'),
                renderHTML: (attributes) => attributes.checked ? { checked: 'checked' } : {},
            },
            name: { default: null },
            value: { default: null },
        };
    },

    parseHTML() {
        return [{
            tag: 'input',
            getAttrs: (element) => (element.getAttribute('type') || '').toLowerCase() === 'checkbox' ? null : false,
        }];
    },

    renderHTML({ HTMLAttributes }) {
        return ['input', Object.assign({ type: 'checkbox' }, HTMLAttributes)];
    },

    addNodeView() {
        return ({ node, getPos, editor }) => {
            const checkbox = document.createElement('input');
            checkbox.type = 'checkbox';
            checkbox.checked = node.attrs.checked;

            checkbox.addEventListener('click', (event) => {
                if(!editor.isEditable) {
                    event.preventDefault(); // read-only: checkboxes stay as they are, like the rest of the content
                    return;
                }
                const position = getPos();
                if(typeof position === 'number') {
                    editor.view.dispatch(editor.state.tr.setNodeMarkup(position, undefined,
                        Object.assign({}, node.attrs, { checked: checkbox.checked })));
                }
            });

            return {
                dom: checkbox,
                update: (updated) => {
                    if(updated.type !== node.type) {
                        return false;
                    }
                    node = updated;
                    checkbox.checked = node.attrs.checked;
                    return true;
                },
                // the checkbox handles its own clicks instead of ProseMirror placing the caret
                stopEvent: (event) => /^(mousedown|mouseup|click|touchstart|touchend)$/.test(event.type),
                ignoreMutation: () => true,
            };
        };
    },
});

// A video file, played with the browser's own controls.
export const Video = Node.create({
    name: 'video',
    group: 'block',
    atom: true,

    addAttributes() {
        return {
            src: {
                default: null,
                parseHTML: (element) => {
                    const source = element.querySelector('source[src]');
                    return element.getAttribute('src') || (source && source.getAttribute('src'));
                },
                renderHTML: () => ({}), // on the <source>
            },
            width: { default: null, parseHTML: (element) => numberAttribute(element, 'width') },
            height: { default: null, parseHTML: (element) => numberAttribute(element, 'height') },
        };
    },

    parseHTML() {
        return [{
            tag: 'video',
            getAttrs: (element) => {
                const source = element.querySelector('source[src]');
                const src = element.getAttribute('src') || (source && source.getAttribute('src'));
                return safeUrl(src, videoDataPrefixes) ? null : false;
            },
        }];
    },

    renderHTML({ node, HTMLAttributes }) {
        const src = safeUrl(node.attrs.src, videoDataPrefixes);
        return ['video', Object.assign({ controls: '' }, HTMLAttributes),
            ['source', src ? { src, type: 'video/mp4' } : { type: 'video/mp4' }]];
    },
});

function isWebUrl(url) {
    return /^https?:\/\//i.test(url || '');
}

// An embedded player, e.g. YouTube's.
export const Iframe = Node.create({
    name: 'iframe',
    group: 'block',
    atom: true,

    addAttributes() {
        return {
            src: {
                default: null,
                renderHTML: (attributes) => isWebUrl(attributes.src) ? { src: attributes.src } : {},
            },
            width: { default: null, parseHTML: (element) => numberAttribute(element, 'width') },
            height: { default: null, parseHTML: (element) => numberAttribute(element, 'height') },
            title: { default: null },
        };
    },

    parseHTML() {
        return [{ tag: 'iframe', getAttrs: (element) => isWebUrl(element.getAttribute('src')) ? null : false }];
    },

    renderHTML({ HTMLAttributes }) {
        return ['iframe', Object.assign({
            frameborder: '0',
            allow: 'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture',
            referrerpolicy: 'strict-origin-when-cross-origin', // the YouTube player refuses to play without one
        }, HTMLAttributes)];
    },
});

export const maxIndent = 8;
const indentStep = 40; // px, what browsers indented by

// Indents paragraphs and headings in steps; list items indent by nesting instead.
export const Indent = Extension.create({
    name: 'indent',

    addGlobalAttributes() {
        return [{
            types: ['paragraph', 'heading'],
            attributes: {
                indent: {
                    default: 0,
                    parseHTML: (element) => {
                        const steps = parseInt(element.getAttribute('data-indent'), 10) ||
                            Math.round((pixels(element.style.marginInlineStart) || pixels(element.style.marginLeft) || 0) / indentStep);
                        return Math.min(Math.max(steps, 0), maxIndent);
                    },
                    renderHTML: (attributes) => attributes.indent ?
                        { style: `margin-inline-start: ${attributes.indent * indentStep}px` } : {},
                },
            },
        }];
    },
});
