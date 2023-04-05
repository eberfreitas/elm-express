module Express.Middleware exposing (Middleware, run)

import Express.Request as Request
import Express.Response as Response


type alias Middleware ctx =
    ctx -> Request.Request -> Response.Response -> Response.Response


run : ctx -> Request.Request -> Response.Response -> List (Middleware ctx) -> Response.Response
run context request response middlewares =
    case middlewares of
        running :: toRun ->
            run context request (running context request response) toRun

        [] ->
            response
