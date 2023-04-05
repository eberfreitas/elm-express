const express = require("express");
const cookieParser = require("cookie-parser");
const session = require("express-session");
const { v4: uuidv4 } = require('uuid');

const POOL = {};
const REQUIRED_PORTS = ["requestPort", "responsePort", "poolPort"];

function buildSessionData(data) {
  return Object.keys(data)
    .filter((k) => !["cookie"].includes(k))
    .reduce((acc, k) => {
      return { ...acc, [k]: data[k] }
    }, {});
}

module.exports = function elmExpress({ app, secret, sessionConfig, reqCallback, port = 3000, mountingRoute = "/" }) {
  REQUIRED_PORTS.forEach((port) => {
    if (!app.ports?.[port]) {
      // TODO: docs here?
      throw new Error(`Your Elm application needs to implement a port named "${port}".`);
    }
  });

  const server = express();

  server.use(cookieParser(secret));
  server.use(session({ ...sessionConfig, secret }));

  app.ports.responsePort.subscribe(({ id, response }) => {
    const [req, res] = POOL[id] || [null, null];

    if (!req || !res) return;

    if (Object.keys(response.headers).length > 0) {
      res.set(response.headers);
    }

    if (response.cookieSet.length > 0) {
      response.cookieSet.forEach((cookieDef) => {
        res.cookie(cookieDef.name, cookieDef.value, cookieDef);
      });
    }

    if (response.cookieUnset.length > 0) {
      response.cookieUnset.forEach(cookieDef => {
        res.clearCookie(cookieDef.name, cookieDef);
      });
    }

    if (Object.keys(response.sessionSet).length > 0) {
      Object.keys(response.sessionSet).forEach((k) => {
        req.session[k] = response.sessionSet[k];
      });
    }

    if (response.sessionUnset.length > 0) {
      response.sessionUnset.forEach((k) => delete req.session[k]);
    }

    delete POOL[id];

    app.ports.poolPort.send(id);

    if (response.redirect) {
      res.redirect(response.redirect.code, response.redirect.path);
    } else {
      res.status(response.status).type(response.body.mime).send(response.body.body);
    }
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
          session: buildSessionData(req.session),
        };

        POOL[id] = [req, res];

        if (reqCallback) {
          reqCallback(req, res);
        }

        app.ports.requestPort.send(request);
      });

      return server.listen(port, callback);
    }
  }

  return Object.assign(server, elmExtension);
}
