module Express exposing
    ( application
    , AppInit, AppIncoming, AppUpdate, AppDecodeRequestId, ApplicationParams
    , Pool, Model, Msg
    )

{-| `elm-express` is a very simple and almost naïve Elm layer on top of Express.js to enable the development of backend
applications with Elm. This is the main module that will allow you to create your `elm-express` application.


# How it works?

The `elm-express` library works as a layer that receives request data from Express.js and allows your Elm app to define
responses. The Elm application is initialized alongside the Express.js server. Whenever a new request comes in,
Express.js will send the request through a port (`requestPort`) and once you are ready to respond, you just need to
route the response through another port (`responsePort`).

Because Elm uses the [actor model](https://en.wikipedia.org/wiki/Actor_model) for message passing, we need to do some
adjustments in order to couple the request and subsequent response into a single operation pair. To do that we tag all
requests with an id (UUID v4) and keep a pool of connections tied to that id. Whenever we need to fetch the data from
a specific request, we can do so by keeping a reference to the request's id.

For the most part, we try to abstract this process by providing helpers and exposing functions to be implemented that
needs to deal only with a single request. But because we might eventually use `ports` for JS interop, sometimes we need
to leak those implementation details. We tried to reduce those cases as much as possible in an attempt to provide a very
ergonomic and delightful API for backend development with Elm.


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


{-| Describes the `incoming` function that gets called whenever a new request happens. Think of this as the `init` of
your request process.
-}
type alias AppIncoming ctx msg model =
    ctx -> Request.Request -> Response.Response -> ( Conn.Conn model, Cmd msg )


{-| Describes the `init` function that runs on start time of your application. Works just like the `init` function of
[`Platform.worker`](https://package.elm-lang.org/packages/elm/core/latest/Platform#worker) and is the best opportunity
to send in some "context" data to be used throughout your application. If there is any data that can be used by your app
and that should never change (like env vars), you can pass them here as context.
-}
type alias AppInit flags ctx =
    flags -> ctx


{-| Describes the `update` function of you application for processing messages. In general these messages will be tied
to port or tasks interactions.
-}
type alias AppUpdate msg model ctx =
    ctx -> msg -> Conn.Conn model -> ( Conn.Conn model, Cmd msg )


{-| Describes the `decodeRequestId` function that gets run whenever we receive a subscription message. With this
function we extract the request id from the value being passed in, in order to properly select the connection being
handled by this particular request.
-}
type alias AppDecodeRequestId msg =
    msg -> Result D.Error String


{-| Describes all the parameters you need to setup for your application to work. Besides some well known functions like
`init` and `update` you also need to pass in four different ports that will be used for the wiring of `elm-express`:

  - `requestPort`
  - `responsePort`
  - `poolPort`
  - `errorPort`

You can also inform a list of middlewares to run at every request. Please, refer to the `Express.Middleware`
documentation to better understand how to use it.

For a full example on how to instantiate a new application, check the `/example` folder in the repository/source.

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
