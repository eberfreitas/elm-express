import { CookieOptions, Request, Response } from "express";
import { SessionOptions } from "express-session";
import { IncomingHttpHeaders } from "http";

export type SessionConfig = Omit<SessionOptions, "secret">;

interface ElmExpressCookie extends CookieOptions {
  name: string;
  value: string;
}

type ElmExpressResponse = {
  requestId: string;
  response: {
    status: number;
    body: {
      mime: string;
      body: string;
    };
    headers: Record<string, string>;
    cookieSet: ElmExpressCookie[];
    cookieUnset: ElmExpressCookie[];
    sessionSet: Record<string, string>;
    sessionUnset: string[];
    redirect: {
      code: number;
      path: string;
    }
  };
};

export type ElmExpressRequest = {
  id: string;
  now: number;
  body: string;
  method: string;
  url: string;
  headers: IncomingHttpHeaders;
  cookies: Record<string, string>;
  session: Record<string, string>;
}

interface Ports extends Object {
  requestPort: { send: (request: ElmExpressRequest) => void };
  poolPort: { send: (id: string) => void };
  errorPort: { subscribe: (callback: (error: string) => void) => void };
  responsePort: { subscribe: (callback: (response: ElmExpressResponse) => void) => void };
};

export type ElmExpressApp = {
  ports: Ports;
};

export type ElmExpressParams = {
  app: ElmExpressApp;
  secret: string;
  sessionConfig: SessionConfig;
  timeout: number;
  port: number;
  mountingRoute: string;
  requestCallback?: (req: Request, res: Response) => void;
  errorCallback?: (error: string) => void;
};
