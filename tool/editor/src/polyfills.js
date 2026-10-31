// Built-ins Tiptap uses that WebViews older than iOS 15.4 and Chrome 97 lack.

if(!Object.hasOwn) {
    Object.hasOwn = function(object, key) {
        return Object.prototype.hasOwnProperty.call(object, key);
    };
}

function define(prototype, name, method) {
    if(!prototype[name]) {
        Object.defineProperty(prototype, name, { value: method, writable: true, configurable: true });
    }
}

define(Array.prototype, 'at', function(index) {
    index = Math.trunc(index) || 0;
    return this[index < 0 ? this.length + index : index];
});

define(Array.prototype, 'findLast', function(predicate, thisArg) {
    for(var i = this.length - 1; i >= 0; i--) {
        if(predicate.call(thisArg, this[i], i, this)) {
            return this[i];
        }
    }
    return undefined;
});

define(Array.prototype, 'findLastIndex', function(predicate, thisArg) {
    for(var i = this.length - 1; i >= 0; i--) {
        if(predicate.call(thisArg, this[i], i, this)) {
            return i;
        }
    }
    return -1;
});
