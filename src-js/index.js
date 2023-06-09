const XMLHttpRequest = require('xhr2');
const express = require("express");
const bodyParser = require("body-parser");
const cookieParser = require("cookie-parser");
const session = require("express-session");
const { v4: uuidv4 } = require('uuid');

global.XMLHttpRequest = XMLHttpRequest;

const POOL = {};
const REQUIRED_PORTS = ["requestPort", "responsePort", "poolPort", "errorPort"];

function buildSessionData(data) {
  return Object.keys(data)
    .filter((k) => !["cookie"].includes(k))
    .reduce((acc, k) => {
      return { ...acc, [k]: data[k] }
    }, {});
}

module.exports = function elmExpress({
  app,
  secret,
  sessionConfig,
  requestCallback,
  errorCallback,
  timeout = 5000,
  port = 3000,
  mountingRoute = "/",
}) {
  REQUIRED_PORTS.forEach((port) => {
    if (!app.ports?.[port]) {
      throw new Error(`Your Elm application needs to implement a port named "${port}".\n\nCheck the docs here: https://bit.ly/3M23uin`);
    }
  });

  setInterval(() => {
    const now = Date.now();

    Object.keys(POOL)
      .forEach((id) => {
        if (!POOL[id]) return;

        const [time, _, res] = POOL[id];

        if ((time + timeout) > now) return;

        res.status(500).type("text/plain").send("Timeout");
        app.ports.poolPort.send(id);

        delete POOL[id];
      });
  }, timeout);

  const server = express();

  server.use(cookieParser(secret));
  server.use(session({ ...sessionConfig, secret }));

  app.ports.errorPort.subscribe((error) => {
    if (errorCallback) {
      errorCallback(error);
    } else {
      console.error(error);
    }
  });

  app.ports.responsePort.subscribe(({ requestId, response }) => {
    if (!POOL[requestId]) return;

    const [_, req, res] = POOL[requestId];

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

    delete POOL[requestId];

    app.ports.poolPort.send(requestId);

    if (response.redirect) {
      res.redirect(response.redirect.code, response.redirect.path);
    } else {
      res.status(response.status).type(response.body.mime).send(response.body.body);
    }
  });

  return Object.assign(server, {
    start: (callback) => {
      server.all(`${mountingRoute}*`, bodyParser.text({type: "*/*"}), (req, res) => {
        const id = uuidv4();
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
          cookies: { ...req.cookies, ...req.signedCookies },
          session: buildSessionData(req.session),
        };

        POOL[id] = [now, req, res];

        if (requestCallback) {
          requestCallback(req, res);
        }

        app.ports.requestPort.send(request);
      });

      return server.listen(port, callback);
    }
  });
}
