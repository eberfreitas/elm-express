import { Cookie, SessionData } from "express-session";

declare module "express-session" {
    export interface SessionData {
        cookie: Cookie;
        [key: string]: string;
    }
}