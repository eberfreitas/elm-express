import { CookieOptions, Response } from "express";

export interface Cookie extends CookieOptions {
  name: string;
  value: string;
}

export function setCookies(res: Response, cookies: Cookie[]): void {
  cookies.forEach((cookieDef) =>
    res.cookie(cookieDef.name, cookieDef.value, cookieDef),
  );
}

export function unsetCookies(res: Response, cookies: Cookie[]): void {
  cookies.forEach((cookieDef) => res.clearCookie(cookieDef.name, cookieDef));
}
