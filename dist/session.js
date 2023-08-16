"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.unsetSessionData = exports.setSessionData = exports.buildSessionData = void 0;
function buildSessionData(data) {
    return Object.keys(data)
        .filter((k) => !["cookie"].includes(k))
        .reduce((acc, k) => {
        return Object.assign(Object.assign({}, acc), { [k]: data[k] });
    }, {});
}
exports.buildSessionData = buildSessionData;
function setSessionData(req, data) {
    Object.keys(data).forEach((k) => (req.session[k] = data[k]));
}
exports.setSessionData = setSessionData;
function unsetSessionData(req, keys) {
    keys.forEach((k) => delete req.session[k]);
}
exports.unsetSessionData = unsetSessionData;
