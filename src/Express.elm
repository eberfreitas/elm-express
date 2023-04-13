module Express exposing
    ( AppDecodeRequestId
    , AppIncoming
    , AppInit
    , AppUpdate
    , ApplicationParams
    , Model
    , Msg
    , application
    )

import Dict
import Express.Conn as Conn
import Express.Internal.Request as InternalRequest
import Express.Middleware as Middleware
import Express.Request as Request
import Express.Response as Response
import Json.Decode as D
import Json.Encode as E
import Platform.Sub as Sub


type alias Pool model =
    Dict.Dict String (Conn.Conn model)


type alias Model model ctx =
    { pool : Pool model
    , context : ctx
    }


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


type alias AppIncoming ctx msg model =
    ctx -> Request.Request -> Response.Response -> ( Conn.Conn model, Cmd msg )


type alias AppInit flags ctx =
    flags -> ctx


type alias AppUpdate msg model ctx =
    ctx -> msg -> Conn.Conn model -> ( Conn.Conn model, Cmd msg )


type alias AppDecodeRequestId msg =
    msg -> Result D.Error String


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
