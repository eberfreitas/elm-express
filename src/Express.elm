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
    -> AppUpdate msg model ctx
    -> AppIncoming ctx msg model
    -> Msg msg
    -> Model model ctx
    -> ( Model model ctx, Cmd (Msg msg) )
update middlewares appUpdate appIncoming msg model =
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
                                appIncoming model.context request (response |> Response.setHeader "X-Powered-By" "elm-express")

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

        AppMsg _ _ ->
            ( model, Cmd.none )

        FromPort appMsg ->
            let
                ( nextConn, appCmds ) =
                    appUpdate appMsg model
            in
            nextConn
                |> Maybe.map
                    (\conn ->
                        let
                            requestId =
                                Request.id conn.request

                            nextModel =
                                { model | pool = model.pool |> Dict.insert requestId conn }
                        in
                        ( nextModel, appCmds |> Cmd.map (AppMsg requestId) )
                    )
                |> Maybe.withDefault ( model, Cmd.none )


type alias AppIncoming ctx msg model =
    ctx -> Request.Request -> Response.Response -> ( Conn.Conn model, Cmd msg )


type alias AppInit flags ctx =
    flags -> ctx


type alias AppUpdate msg model ctx =
    msg -> Model model ctx -> ( Maybe (Conn.Conn model), Cmd msg )


type alias ApplicationParams flags ctx msg model =
    { requestPort : (D.Value -> Msg msg) -> Sub.Sub (Msg msg)
    , responsePort : E.Value -> Cmd.Cmd (Msg msg)
    , poolPort : (String -> Msg msg) -> Sub.Sub (Msg msg)
    , incoming : AppIncoming ctx msg model
    , init : AppInit flags ctx
    , subscriptions : Sub.Sub msg
    , update : AppUpdate msg model ctx
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
        , update = update params.middlewares params.update params.incoming
        , subscriptions = subs
        }
