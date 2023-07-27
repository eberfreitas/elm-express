import { Response } from "express";
import { ElmExpressCookie } from "./types";
export declare function setCookies(res: Response, cookies: ElmExpressCookie[]): void;
export declare function unsetCookies(res: Response, cookies: ElmExpressCookie[]): void;
