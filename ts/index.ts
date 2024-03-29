import XMLHttpRequest from "xhr2";
import express, { Request as ERequest, Response as EResponse } from "express";
import bodyParser from "body-parser";
import cookieParser from "cookie-parser";
import expressSession from "express-session";
import { v4 as uuidv4 } from "uuid";
import { IncomingHttpHeaders } from "http";

import * as pool from "./pool";
import * as session from "./session";
import * as cookie from "./cookie";

export type Request = {
  id: string;
  now: number;
  body: string;
  method: string;
  url: string;
  headers: IncomingHttpHeaders;
  cookies: Record<string, string>;
  session: Record<string, string>;
};

export type Response = {
  requestId: string;
  response: {
    status: number;
    body: {
      mime: string;
      body: string;
    };
    headers: Record<string, string>;
    cookieSet: cookie.Cookie[];
    cookieUnset: cookie.Cookie[];
    sessionSet: session.SessionData;
    sessionUnset: string[];
    redirect: {
      code: number;
      path: string;
    };
  };
};

export interface Ports extends NonNullable<unknown> {
  requestPort: { send: (request: Request) => void };
  poolPort: { send: (id: string) => void };
  errorPort: { subscribe: (callback: (error: string) => void) => void };
  responsePort: {
    subscribe: (callback: (response: Response) => void) => void;
  };
}

export type App = {
  ports: Ports;
};

export type InitParams = {
  app: App;
  secret: string;
  sessionConfig: session.SessionConfig;
  timeout: number;
  port: number;
  mountingRoute: string;
  requestCallback?: (req: ERequest, res: EResponse) => void;
  errorCallback?: (error: string) => void;
};

global.XMLHttpRequest = XMLHttpRequest;

const REQUIRED_PORTS = [
  "requestPort" as const,
  "responsePort" as const,
  "poolPort" as const,
  "errorPort" as const,
];

export function elmExpress({
  app,
  secret,
  sessionConfig,
  requestCallback,
  errorCallback,
  timeout = 5000,
  port = 3000,
  mountingRoute = "/",
}: InitParams) {
  REQUIRED_PORTS.forEach((port) => {
    if (!app.ports?.[port]) {
      throw new Error(
        `Your Elm application needs to implement a port named "${port}".\
        \n\nCheck the docs here: https://bit.ly/3M23uin`,
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
  server.use(expressSession({ ...sessionConfig, secret }));

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

      cookie.setCookies(res, response.cookieSet);
      cookie.unsetCookies(res, response.cookieUnset);
      session.setSessionData(req, response.sessionSet);
      session.unsetSessionData(req, response.sessionUnset);

      pool.del(requestId);
      app.ports.poolPort.send(requestId);

      if (response.redirect) {
        res.redirect(response.redirect.code, response.redirect.path);
      } else {
        res
          .status(response.status)
          .type(response.body.mime)
          .send(response.body.body);
      }
    });
  });

  return Object.assign(server, {
    start: (callback: () => void) => {
      server.all(
        `${mountingRoute}*`,
        bodyParser.text({ type: "*/*" }),
        (req, res) => {
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
            session: session.buildSessionData(req.session),
          };

          requestCallback && requestCallback(req, res);

          pool.put(id, req, res);
          app.ports.requestPort.send(request);
        },
      );

      return server.listen(port, callback);
    },
  });
}
