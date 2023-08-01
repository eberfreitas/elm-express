"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.unsetCookies = exports.setCookies = void 0;
function setCookies(res, cookies) {
    cookies.forEach((cookieDef) => res.cookie(cookieDef.name, cookieDef.value, cookieDef));
}
exports.setCookies = setCookies;
function unsetCookies(res, cookies) {
    cookies.forEach((cookieDef) => res.clearCookie(cookieDef.name, cookieDef));
}
exports.unsetCookies = unsetCookies;
