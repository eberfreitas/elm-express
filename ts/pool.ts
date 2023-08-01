import { Request, Response } from "express";

export type Connection = {
    now: number;
    req: Request;
    res: Response;
}

export type ConnectionsPool = Record<string, Connection>;

const POOL: ConnectionsPool = {};

export function put(id: string, req: Request, res: Response): Connection {
    const now = Date.now();
    const connection = { now, req, res };

    POOL[id] = connection;

    return connection;
}

export function get(id: string): Connection | null {
    return POOL[id] ?? null;
}

export function withConnection(id: string, callback: (id: string, connection: Connection) => void): void {
    const connection = get(id);

    connection && callback(id, connection);
}

export function del(id: string): void {
    delete POOL[id];
}

export function tap(callback: (id: string, connection: Connection) => void): void {
    Object.keys(POOL).forEach((id) => withConnection(id, callback));
}