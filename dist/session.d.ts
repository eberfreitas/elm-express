import { Session, SessionData as ESessionData, SessionOptions } from "express-session";
import { Request } from "express";
export type SessionConfig = Omit<SessionOptions, "secret">;
export type SessionData = Record<string, string>;
export declare function buildSessionData(data: Session & Partial<ESessionData>): SessionData;
export declare function setSessionData(req: Request, data: SessionData): void;
export declare function unsetSessionData(req: Request, keys: string[]): void;
