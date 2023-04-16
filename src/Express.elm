module Express exposing
    ( application
    , AppInit, AppIncoming, AppUpdate, AppDecodeRequestId, ApplicationParams
    , Pool, Model, Msg
    )

{-| `elm-express` is an Elm library that provides a lightweight and expressive API for building server-side applications
on top of the popular Node.js web framework, Express. With `elm-express`, developers can leverage the safety and
expressiveness of Elm for building web backends in a familiar and powerful environment.


# How it works?

When an incoming request arrives, Express.js sends the request data through a port called `requestPort` to the Elm
application, which can then define a response and route it through another port called `responsePort`.

To simplify the integration between the Express.js server and the Elm application, `elm-express` comes with a JavaScript
library that takes care of most of the wiring. The README contains documentation on how to use the library, and the
`/example` folder in the repository provides a practical demonstration of how to wire everything up.


# Creating an `elm-express` application

@docs application


# Types

@docs AppInit, AppIncoming, AppUpdate, AppDecodeRequestId, ApplicationParams


# Internal types

@docs Pool, Model, Msg

-}

import Dict
import Express.Conn as Conn
import Express.Internal.Request as InternalRequest
import Express.Middleware as Middleware
import Express.Request as Request
import Express.Response as Response
import Json.Decode as D
import Json.Encode as E
import Platform.Sub as Sub


{-| Internal connections pool.
-}
type alias Pool model =
    Dict.Dict String (Conn.Conn model)


{-| Internal model.
-}
type alias Model model ctx =
    { pool : Pool model
    , context : ctx
    }


{-| Internal messages.
-}
type Msg msg
    = GotRequest D.Value
    | GotPoolDrop String
    | AppMsg String msg
    | PortMsg msg


update :
    (String -> Cmd (Msg msg))
    -> List (Middleware.Middleware ctx msg)
    -> AppDecodeRequestId msg
    -> AppUpdate msg model ctx
    -> AppIncoming ctx msg model
    -> Msg msg
    -> Model model ctx
    -> ( Model model ctx, Cmd (Msg msg) )
update errorPort middlewares decodeRequestId appUpdate incoming msg model =
    case msg of
        GotRequest raw ->
            case D.decodeValue InternalRequest.decode raw of
                Ok request ->
                    let
                        ( response, mwCmds ) =
                            middlewares |> Middleware.run model.context request Response.new

                        ( conn, appCmds ) =
                            incoming model.context request (response |> Response.setHeader "X-Powered-By" "elm-express")

                        requestId : String
                        requestId =
                            Request.id request

                        nextModel : Model model ctx
                        nextModel =
                            { model | pool = model.pool |> Dict.insert requestId conn }
                    in
                    ( nextModel, Cmd.map (AppMsg requestId) (Cmd.batch [ mwCmds, appCmds ]) )

                Err err ->
                    ( model, errorPort <| "Error when decoding incoming request: " ++ D.errorToString err )

        GotPoolDrop uuid ->
            ( { model | pool = model.pool |> Dict.remove uuid }, Cmd.none )

        AppMsg requestId appMsg ->
            model.pool
                |> Dict.get requestId
                |> Maybe.map (\conn -> appUpdate model.context appMsg conn)
                |> Maybe.map
                    (\( conn, cmds ) ->
                        ( { model | pool = model.pool |> Dict.insert (Request.id conn.request) conn }
                        , cmds |> Cmd.map (AppMsg (Request.id conn.request))
                        )
                    )
                |> Maybe.withDefault ( model, errorPort ("Request with id \"" ++ requestId ++ "\" not found in request pool") )

        PortMsg appMsg ->
            case decodeRequestId appMsg of
                Ok requestId ->
                    model.pool
                        |> Dict.get requestId
                        |> Maybe.map (\conn -> appUpdate model.context appMsg conn)
                        |> Maybe.map
                            (\( conn, cmds ) ->
                                ( { model | pool = model.pool |> Dict.insert (Request.id conn.request) conn }
                                , cmds |> Cmd.map (AppMsg (Request.id conn.request))
                                )
                            )
                        |> Maybe.withDefault ( model, errorPort ("Request with id \"" ++ requestId ++ "\" not found in request pool") )

                Err err ->
                    ( model
                    , errorPort <| "Error when decoding the request id. Verify your `decodeRequestId` function: " ++ D.errorToString err
                    )


{-| Describes the `incoming` function that gets called whenever a new request happens.
-}
type alias AppIncoming ctx msg model =
    ctx -> Request.Request -> Response.Response -> ( Conn.Conn model, Cmd msg )


{-| The `AppInit` type alias represents the `init` function that runs when the application is started. It is similar to
the `init` function of [`Platform.worker`](https://package.elm-lang.org/packages/elm/core/latest/Platform#worker), and
provides an opportunity to pass in "context" data that can be used throughout the application.

This is an ideal place to provide any data that will not change during the application's lifecycle, such as environment
variables. By passing such data as context, you can ensure that it is available to all parts of the application that
need it.

-}
type alias AppInit flags ctx =
    flags -> ctx


{-| The `AppUpdate` type alias represents the `update` function of your Elm application. This function is responsible
for processing messages that are typically tied to port or task interactions.

The update function takes three arguments: a context (`ctx`), a message (`msg`), and a connection (`Conn.Conn model`)
that represents the current state of the application. Based on these inputs, the function returns a tuple containing a
new connection (`Conn.Conn model`) and any commands (`Cmd msg`) that should be executed as a result of the message
processing.

-}
type alias AppUpdate msg model ctx =
    ctx -> msg -> Conn.Conn model -> ( Conn.Conn model, Cmd msg )


{-| The `AppDecodeRequestId` type alias represents the `decodeRequestId` function, which is called whenever a
subscription message is received. This function extracts the request ID from the message value in order to select the
connection associated with the request.
-}
type alias AppDecodeRequestId msg =
    msg -> Result D.Error String


{-| The `ApplicationParams` type alias represents all the parameters that need to be set up for your Elm application to
work with `elm-express`. In addition to well-known functions like `init` and `update`, you need to provide four
different ports that will be used for wiring:

  - `requestPort`
  - `responsePort`
  - `poolPort`
  - `errorPort`

You can also provide a list of middlewares to run at every request. Please refer to the `Express.Middleware`
documentation to learn how to use middleware.

For a full example of how to instantiate a new `ApplicationParams` value, see the `/example` folder in the
repository/source.

-}
type alias ApplicationParams flags ctx msg model =
    { requestPort : (D.Value -> Msg msg) -> Sub.Sub (Msg msg)
    , responsePort : E.Value -> Cmd (Msg msg)
    , errorPort : String -> Cmd (Msg msg)
    , poolPort : (String -> Msg msg) -> Sub.Sub (Msg msg)
    , init : AppInit flags ctx
    , incoming : AppIncoming ctx msg model
    , decodeRequestId : AppDecodeRequestId msg
    , update : AppUpdate msg model ctx
    , subscriptions : Sub.Sub msg
    , middlewares : List (Middleware.Middleware ctx msg)
    }


{-| This function wraps the [`Platform.worker`](https://package.elm-lang.org/packages/elm/core/latest/Platform#worker)
function to create a "headless" Elm application that should be instantiated by a Node.js script.

For a more in-depth understanding of how to use this library and create your own application, take a look at the app in
the `/example` folder in the repository/source.

-}
application : ApplicationParams flags ctx msg model -> Program flags (Model model ctx) (Msg msg)
application params =
    let
        subs : Model model ctx -> Sub (Msg msg)
        subs _ =
            Sub.batch
                [ params.requestPort GotRequest
                , params.poolPort GotPoolDrop
                , Sub.map PortMsg params.subscriptions
                ]
    in
    Platform.worker
        { init = \flags -> ( Model Dict.empty (params.init flags), Cmd.none )
        , update =
            update params.errorPort
                params.middlewares
                params.decodeRequestId
                params.update
                params.incoming
        , subscriptions = subs
        }
