const express = require("express");
const { v4: uuidv4 } = require('uuid');

const POOL = {};
const REQUIRED_PORTS = ["requestPort", "responsePort", "poolPort"];

function buildCookieOptions(cookieDef) {
  let expiresBase = {};

  switch (cookieDef.expires.type) {
    case "at":
      expiresBase = { expires: new Date(cookieDef.expires.posix) };
      break;

    case "session":
    default:
      expiresBase = {};
  }

  return {
    ...expiresBase,
    domain: cookieDef.domain,
    httpOnly: cookieDef.httpOnly,
    path: cookieDef.path,
    secure: cookieDef.secure,
    signed: cookieDef.signed,
    sameSite: cookieDef.sameSite,
  };
}

module.exports = function elmExpress({ app, port = 3000, mountingRoute = "/" }) {
  const server = express();

  REQUIRED_PORTS.forEach((port) => {
    if (!app.ports?.[port]) {
      // TODO: docs here?
      throw new Error(`Your Elm application needs to implement a port named "${port}".`);
    }
  });

  app.ports.responsePort.subscribe(({ id, response }) => {
    const res = POOL[id] || null;

    if (!res) return;

    if (response.cookieSet.length > 0) {
      for (let i = 0; i < response.cookieSet.length; i++) {
        const cookieDef = response.cookieSet[i];

        res?.cookie(cookieDef.name, cookieDef.value, buildCookieOptions(cookieDef));
      }
    }

    if (response.cookieUnset.length > 0) {
      for (let i = 0; i < response.cookieUnset.length; i++) {
        const cookieDef = response.cookieUnset[i];

        res?.clearCookie(cookieDef.name, buildCookieOptions(cookieDef));
      }
    }

    res.status(response.status).type(response.body.mime).send(response.body.body);

    delete POOL[id];

    app.ports.poolPort.send(id);
  });

  const elmExtension = {
    start: (callback) => {
      server.all(`${mountingRoute}*`, (req, res) => {
        const id = uuidv4();
        const now = Date.now();

        let body = req.body || "";

        if (Object.keys(body).length === 0) {
          body = "";
        } else if (typeof body !== "string") {
          body = JSON.stringify(body);
        }

        const request = {
          id,
          now,
          method: req.method,
          url: `${req.protocol}://${req.get("host")}${req.originalUrl}`,
          headers: req.headers,
          body,
          cookies: { ...req.cookies, ...req.signedCookies },
        };

        POOL[id] = res;

        app.ports.requestPort.send(request);
      });

      return server.listen(port, callback);
    }
  }

  return Object.assign(server, elmExtension);
}
