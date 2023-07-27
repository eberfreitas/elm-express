import { Session, SessionData } from "express-session";
import { Request } from "express";
export type ElmSessionData = Record<string, string>;
export declare function buildSessionData(data: Session & Partial<SessionData>): ElmSessionData;
export declare function setSessionData(req: Request, data: ElmSessionData): void;
export declare function unsetSessionData(req: Request, keys: string[]): void;
