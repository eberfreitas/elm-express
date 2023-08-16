import { Response } from "express";

import { ElmExpressCookie } from "./types";

export function setCookies(res: Response, cookies: ElmExpressCookie[]): void {
  cookies.forEach((cookieDef) =>
    res.cookie(cookieDef.name, cookieDef.value, cookieDef),
  );
}

export function unsetCookies(res: Response, cookies: ElmExpressCookie[]): void {
  cookies.forEach((cookieDef) => res.clearCookie(cookieDef.name, cookieDef));
}
