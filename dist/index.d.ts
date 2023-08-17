/// <reference types="node" />
import { Request as ERequest, Response as EResponse } from "express";
import { IncomingHttpHeaders } from "http";
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
    requestPort: {
        send: (request: Request) => void;
    };
    poolPort: {
        send: (id: string) => void;
    };
    errorPort: {
        subscribe: (callback: (error: string) => void) => void;
    };
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
export declare function elmExpress({ app, secret, sessionConfig, requestCallback, errorCallback, timeout, port, mountingRoute, }: InitParams): import("express-serve-static-core").Express & {
    start: (callback: () => void) => import("http").Server<typeof import("http").IncomingMessage, typeof import("http").ServerResponse>;
};
