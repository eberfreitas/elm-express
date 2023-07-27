import XMLHttpRequest from "xhr2";
import express from "express";
import bodyParser from "body-parser";
import cookieParser from "cookie-parser";
import session, { Session, SessionData } from "express-session";
import { v4 as uuidv4 } from "uuid";

import * as pool from "./pool";
import { ElmExpressParams } from "./types";

global.XMLHttpRequest = XMLHttpRequest;

const REQUIRED_PORTS = [
  "requestPort" as const,
  "responsePort" as const,
  "poolPort" as const,
  "errorPort" as const
];

function buildSessionData(data: Session & Partial<SessionData>): Record<string, string> {
  return Object.keys(data)
    .filter((k) => !["cookie"].includes(k))
    .reduce((acc, k) => {
      return { ...acc, [k]: data[k] }
    }, {});
}

export function elmExpress({
  app,
  secret,
  sessionConfig,
  requestCallback,
  errorCallback,
  timeout = 5000,
  port = 3000,
  mountingRoute = "/",
}: ElmExpressParams) {
  REQUIRED_PORTS.forEach((port) => {
    if (!app.ports?.[port]) {
      throw new Error(
        `Your Elm application needs to implement a port named "${port}".\
        \n\nCheck the docs here: https://bit.ly/3M23uin`
      );
    }
  });

  setInterval(() => {
    const now = Date.now();

    pool.tap((id, connection) => {
      if (connection.now + timeout > now) return;
      connection.res.status(500).type("text/plain").send("Timeout");
      app.ports.poolPort.send(id);
      pool.del(id);
    });
  }, timeout);

  const server = express();

  server.use(cookieParser(secret));
  server.use(session({ ...sessionConfig, secret }));

  app.ports.errorPort.subscribe((error: string) => {
    if (errorCallback) {
      errorCallback(error);
    } else {
      console.error(error);
    }
  });

  app.ports.responsePort.subscribe(({ requestId, response }) => {
    pool.withConnection(requestId, (_id, { req, res }) => {
      if (Object.keys(response.headers).length > 0) {
        res.set(response.headers);
      }

      if (response.cookieSet.length > 0) {
        response.cookieSet.forEach((cookieDef) => {
          res.cookie(cookieDef.name, cookieDef.value, cookieDef);
        });
      }

      if (response.cookieUnset.length > 0) {
        response.cookieUnset.forEach((cookieDef) => {
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

      pool.del(requestId);
      app.ports.poolPort.send(requestId);

      if (response.redirect) {
        res.redirect(response.redirect.code, response.redirect.path);
      } else {
        res.status(response.status).type(response.body.mime).send(response.body.body);
      }
    });
  });

  return Object.assign(server, {
    start: (callback: () => void) => {
      server.all(`${mountingRoute}*`, bodyParser.text({ type: "*/*" }), (req, res) => {
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

        pool.put(id, req, res);

        if (requestCallback) {
          requestCallback(req, res);
        }

        app.ports.requestPort.send(request);
      });

      return server.listen(port, callback);
    }
  });
}
