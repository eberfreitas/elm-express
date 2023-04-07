module Express.Middleware exposing (Middleware, run)

import Express.Request as Request
import Express.Response as Response


type alias Middleware ctx msg =
    ctx -> Request.Request -> Response.Response -> ( Response.Response, Cmd.Cmd msg )


run : ctx -> Request.Request -> Response.Response -> List (Middleware ctx msg) -> ( Response.Response, Cmd.Cmd msg )
run context request response middlewares =
    let
        recurse ctx req res cmds mws =
            case mws of
                running :: toRun ->
                    let
                        ( newRes, newCmds ) =
                            running ctx req res
                    in
                    recurse ctx req newRes (Cmd.batch [ cmds, newCmds ]) toRun

                [] ->
                    ( res, cmds )
    in
    recurse context request response Cmd.none middlewares
