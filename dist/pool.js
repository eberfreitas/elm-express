"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.tap = exports.del = exports.withConnection = exports.get = exports.put = void 0;
const POOL = {};
function put(id, req, res) {
    const now = Date.now();
    const connection = { now, req, res };
    POOL[id] = connection;
    return connection;
}
exports.put = put;
function get(id) {
    var _a;
    return (_a = POOL[id]) !== null && _a !== void 0 ? _a : null;
}
exports.get = get;
function withConnection(id, callback) {
    const connection = get(id);
    connection && callback(id, connection);
}
exports.withConnection = withConnection;
function del(id) {
    delete POOL[id];
}
exports.del = del;
function tap(callback) {
    Object.keys(POOL).forEach((id) => withConnection(id, callback));
}
exports.tap = tap;
