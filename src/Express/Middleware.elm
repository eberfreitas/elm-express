module Express.Middleware exposing
    ( Middleware
    , run
    )

{-| This module exposes a very simple middleware system.


# Types

@docs Middleware


# Running middlewares

@docs run

-}

import Express.Request as Request
import Express.Response as Response


{-| Middlewares are simple functions that will receive your application's context, a request and a response as
parameters, and return a response and command. Remember that you can lock a response inside your middlewares. To better
understand what is a locked response, please refer to the `Express.Response` module documentation.

    authMiddleware context request response =
        case Express.Request.cookie "user" request of
            Just _ ->
                ( response, Cmd.none )

            Nothing ->
                let
                    newResponse =
                        response |> Express.Response.redirect "/login"
                in
                ( newResponse, newResponse |> Response.send request |> responsePort )

-}
type alias Middleware ctx msg =
    ctx -> Request.Request -> Response.Response -> ( Response.Response, Cmd.Cmd msg )


{-| Given a list of middleware functions, you can run them all in sequence by using the `run` function. Think of this
function as a reducer or folding function that will aggregate the transformations from all middlewares into a single
`( response, command )` tuple.

    let
        middlewares =
            [ flashMsgMiddleware, authMiddleware ]
    in
    ( newResponse, newCmd ) =
        run context request response middlewares

-}
run : ctx -> Request.Request -> Response.Response -> List (Middleware ctx msg) -> ( Response.Response, Cmd.Cmd msg )
run context request response middlewares =
    let
        recurse :
            ctx
            -> Request.Request
            -> Response.Response
            -> Cmd.Cmd msg
            -> List (Middleware ctx msg)
            -> ( Response.Response, Cmd.Cmd msg )
        recurse ctx req res cmds mws =
            case mws of
                running :: toRun ->
                    let
                        ( newRes, newCmds ) =
                            res
                                |> Response.withUnlocked (\_ -> running ctx req res)
                                |> Maybe.withDefault ( res, Cmd.none )
                    in
                    recurse ctx req newRes (Cmd.batch [ cmds, newCmds ]) toRun

                [] ->
                    ( res, cmds )
    in
    recurse context request response Cmd.none middlewares
