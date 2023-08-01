/// <reference types="node" />
import { ElmExpressParams } from "./types";
export declare function elmExpress({ app, secret, sessionConfig, requestCallback, errorCallback, timeout, port, mountingRoute, }: ElmExpressParams): import("express-serve-static-core").Express & {
    start: (callback: () => void) => import("http").Server<typeof import("http").IncomingMessage, typeof import("http").ServerResponse>;
};
