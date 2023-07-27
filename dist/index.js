"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.elmExpress = void 0;
const xhr2_1 = __importDefault(require("xhr2"));
const express_1 = __importDefault(require("express"));
const body_parser_1 = __importDefault(require("body-parser"));
const cookie_parser_1 = __importDefault(require("cookie-parser"));
const express_session_1 = __importDefault(require("express-session"));
const uuid_1 = require("uuid");
const pool = __importStar(require("./pool"));
const session = __importStar(require("./session"));
const cookie = __importStar(require("./cookie"));
global.XMLHttpRequest = xhr2_1.default;
const REQUIRED_PORTS = [
    "requestPort",
    "responsePort",
    "poolPort",
    "errorPort"
];
function elmExpress({ app, secret, sessionConfig, requestCallback, errorCallback, timeout = 5000, port = 3000, mountingRoute = "/", }) {
    REQUIRED_PORTS.forEach((port) => {
        var _a;
        if (!((_a = app.ports) === null || _a === void 0 ? void 0 : _a[port])) {
            throw new Error(`Your Elm application needs to implement a port named "${port}".\
        \n\nCheck the docs here: https://bit.ly/3M23uin`);
        }
    });
    setInterval(() => {
        const now = Date.now();
        pool.tap((id, connection) => {
            if (connection.now + timeout > now)
                return;
            connection.res.status(500).type("text/plain").send("Timeout");
            app.ports.poolPort.send(id);
            pool.del(id);
        });
    }, timeout);
    const server = (0, express_1.default)();
    server.use((0, cookie_parser_1.default)(secret));
    server.use((0, express_session_1.default)(Object.assign(Object.assign({}, sessionConfig), { secret })));
    app.ports.errorPort.subscribe((error) => {
        if (errorCallback) {
            errorCallback(error);
        }
        else {
            console.error(error);
        }
    });
    app.ports.responsePort.subscribe(({ requestId, response }) => {
        pool.withConnection(requestId, (_id, { req, res }) => {
            if (Object.keys(response.headers).length > 0) {
                res.set(response.headers);
            }
            cookie.setCookies(res, response.cookieSet);
            cookie.unsetCookies(res, response.cookieUnset);
            session.setSessionData(req, response.sessionSet);
            session.unsetSessionData(req, response.sessionUnset);
            pool.del(requestId);
            app.ports.poolPort.send(requestId);
            if (response.redirect) {
                res.redirect(response.redirect.code, response.redirect.path);
            }
            else {
                res.status(response.status).type(response.body.mime).send(response.body.body);
            }
        });
    });
    return Object.assign(server, {
        start: (callback) => {
            server.all(`${mountingRoute}*`, body_parser_1.default.text({ type: "*/*" }), (req, res) => {
                const id = (0, uuid_1.v4)();
                const now = Date.now();
                let body = req.body || "";
                if (Object.keys(body).length === 0) {
                    body = "";
                }
                const request = {
                    id,
                    now,
                    body,
                    method: req.method,
                    url: `${req.protocol}://${req.get("host")}${req.originalUrl}`,
                    headers: req.headers,
                    cookies: Object.assign(Object.assign({}, req.cookies), req.signedCookies),
                    session: session.buildSessionData(req.session),
                };
                requestCallback && requestCallback(req, res);
                pool.put(id, req, res);
                app.ports.requestPort.send(request);
            });
            return server.listen(port, callback);
        }
    });
}
exports.elmExpress = elmExpress;
