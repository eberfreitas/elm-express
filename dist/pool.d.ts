import { Request, Response } from "express";
export type Connection = {
    now: number;
    req: Request;
    res: Response;
};
export type ConnectionsPool = Record<string, Connection>;
export declare function put(id: string, req: Request, res: Response): Connection;
export declare function get(id: string): Connection | null;
export declare function withConnection(id: string, callback: (id: string, connection: Connection) => void): void;
export declare function del(id: string): void;
export declare function tap(callback: (id: string, connection: Connection) => void): void;
