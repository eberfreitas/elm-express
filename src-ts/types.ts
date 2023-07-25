import { CookieOptions, Request, Response } from "express";
import { SessionOptions } from "express-session";

export type ConnectionsPool = Record<string, [number, Request, Response]>;

export type SessionConfig = Omit<SessionOptions, "secret">;

interface ElmExpressCookie extends CookieOptions {
  name: string;
  value: string;
}

type ElmExpressResponse = {
  requestId: number;
  response: {
    status: number;
    body: {
      mime: string;
      body: string;
    };
    headers: Record<string, string>;
    cookieSet: ElmExpressCookie[];
    cookieUnset: ElmExpressCookie[];
    sessionSet: Record<string, any>;
    redirect: {
      code: number;
      path: string;
    }
  };
};

interface Ports extends Object {
  requestPort: { send: any };
  poolPort: { send: any };
  errorPort: { subscribe: (callback: (error: string) => void ) => void };
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
