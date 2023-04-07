module Express exposing (Model, Msg, application)

import Dict
import Express.Conn as Conn
import Express.Middleware as Middleware
import Express.Request as Request
import Express.Response as Response
import Json.Decode as D
import Json.Encode as E
import Platform.Sub as Sub


type alias Model model ctx =
    { pool : Conn.Pool model
    , context : ctx
    }


type Msg msg
    = GotRequest D.Value
    | GotPoolDrop String
    | AppMsg String msg
    | FromPort msg


update :
    List (Middleware.Middleware ctx)
    -> AppDecodeRequestId msg
    -> AppUpdate msg model ctx
    -> AppIncoming ctx msg model
    -> Msg msg
    -> Model model ctx
    -> ( Model model ctx, Cmd (Msg msg) )
update middlewares decodeRequestId appUpdate incoming msg model =
    case msg of
        GotRequest raw ->
            raw
                |> D.decodeValue Request.decode
                |> Result.map
                    (\request ->
                        let
                            response =
                                middlewares |> Middleware.run model.context request Response.new

                            ( conn, appCmds ) =
                                incoming model.context request (response |> Response.setHeader "X-Powered-By" "elm-express")

                            requestId =
                                Request.id request

                            nextModel =
                                { model | pool = model.pool |> Dict.insert (Request.id request) conn }
                        in
                        ( nextModel, Cmd.map (AppMsg requestId) appCmds )
                    )
                |> Result.withDefault ( model, Cmd.none )

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
                |> Maybe.withDefault ( model, Cmd.none )

        FromPort appMsg ->
            appMsg
                |> decodeRequestId
                |> Maybe.andThen (\requestId -> Dict.get requestId model.pool)
                |> Maybe.map (\conn -> appUpdate model.context appMsg conn)
                |> Maybe.map
                    (\( conn, cmds ) ->
                        ( { model | pool = model.pool |> Dict.insert (Request.id conn.request) conn }
                        , cmds |> Cmd.map (AppMsg (Request.id conn.request))
                        )
                    )
                |> Maybe.withDefault ( model, Cmd.none )


type alias AppIncoming ctx msg model =
    ctx -> Request.Request -> Response.Response -> ( Conn.Conn model, Cmd.Cmd msg )


type alias AppInit flags ctx =
    flags -> ctx


type alias AppUpdate msg model ctx =
    ctx -> msg -> Conn.Conn model -> ( Conn.Conn model, Cmd msg )


type alias AppDecodeRequestId msg =
    msg -> Maybe String


type alias ApplicationParams flags ctx msg model =
    { requestPort : (D.Value -> Msg msg) -> Sub.Sub (Msg msg)
    , responsePort : E.Value -> Cmd.Cmd (Msg msg)
    , poolPort : (String -> Msg msg) -> Sub.Sub (Msg msg)
    , init : AppInit flags ctx
    , incoming : AppIncoming ctx msg model
    , decodeRequestId : AppDecodeRequestId msg
    , update : AppUpdate msg model ctx
    , subscriptions : Sub.Sub msg
    , middlewares : List (Middleware.Middleware ctx)
    }


application : ApplicationParams flags ctx msg model -> Program flags (Model model ctx) (Msg msg)
application params =
    let
        subs : Model model ctx -> Sub (Msg msg)
        subs _ =
            Sub.batch
                [ params.requestPort GotRequest
                , params.poolPort GotPoolDrop
                , Sub.map FromPort params.subscriptions
                ]
    in
    Platform.worker
        { init = \flags -> ( Model Dict.empty (params.init flags), Cmd.none )
        , update = update params.middlewares params.decodeRequestId params.update params.incoming
        , subscriptions = subs
        }
