import { CookieOptions, Response } from "express";
export interface Cookie extends CookieOptions {
    name: string;
    value: string;
}
export declare function setCookies(res: Response, cookies: Cookie[]): void;
export declare function unsetCookies(res: Response, cookies: Cookie[]): void;
