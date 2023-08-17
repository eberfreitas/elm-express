import { Session, SessionData as ESessionData, SessionOptions } from "express-session";
import { Request } from "express";

export type SessionConfig = Omit<SessionOptions, "secret">;

export type SessionData = Record<string, string>;

export function buildSessionData(
  data: Session & Partial<ESessionData>,
): SessionData {
  return Object.keys(data)
    .filter((k) => !["cookie"].includes(k))
    .reduce((acc, k) => {
      return { ...acc, [k]: data[k] };
    }, {});
}

export function setSessionData(req: Request, data: SessionData): void {
  Object.keys(data).forEach((k) => (req.session[k] = data[k]));
}

export function unsetSessionData(req: Request, keys: string[]): void {
  keys.forEach((k) => delete req.session[k]);
}
