const express = require("express");
const cookieParser = require("cookie-parser");
const { v4: uuidv4 } = require('uuid');

const POOL = {};
const REQUIRED_PORTS = ["requestPort", "responsePort", "poolPort"];

module.exports = function elmExpress({ app, secret, port = 3000, mountingRoute = "/" }) {
  REQUIRED_PORTS.forEach((port) => {
    if (!app.ports?.[port]) {
      // TODO: docs here?
      throw new Error(`Your Elm application needs to implement a port named "${port}".`);
    }
  });

  const server = express();

  server.use(cookieParser(secret));

  app.ports.responsePort.subscribe(({ id, response }) => {
    const res = POOL[id] || null;

    if (!res) return;

    if (Object.keys(response.headers).length > 0) {
      res.set(response.headers);
    }

    if (response.cookieSet.length > 0) {
      for (let i = 0; i < response.cookieSet.length; i++) {
        const cookieDef = response.cookieSet[i];

        res?.cookie(cookieDef.name, cookieDef.value, cookieDef);
      }
    }

    if (response.cookieUnset.length > 0) {
      for (let i = 0; i < response.cookieUnset.length; i++) {
        const cookieDef = response.cookieUnset[i];

        res?.clearCookie(cookieDef.name, cookieDef);
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
