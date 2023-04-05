module Express exposing (Model, Msg, application)

import Dict
import Express.Conn as Conn
import Express.Request as Request
import Express.Response as Response
import Json.Decode as D
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
    AppUpdate msg model ctx
    -> AppIncoming ctx msg model
    -> Msg msg
    -> Model model ctx
    -> ( Model model ctx, Cmd (Msg msg) )
update appUpdate appIncoming msg model =
    case msg of
        GotRequest raw ->
            raw
                |> D.decodeValue Request.decode
                |> Result.map
                    (\request ->
                        let
                            ( conn, appCmds ) =
                                appIncoming model.context request (Response.new |> Response.setHeader "X-Powered-By" "elm-express")

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
    , poolPort : (String -> Msg msg) -> Sub.Sub (Msg msg)
    , incoming : AppIncoming ctx msg model
    , init : AppInit flags ctx
    , subscriptions : Sub.Sub msg
    , update : AppUpdate msg model ctx
    }


application : ApplicationParams flags ctx msg model -> Program flags (Model model ctx) (Msg msg)
application ({ requestPort, poolPort, init, incoming, subscriptions } as params) =
    let
        subs : Model model ctx -> Sub (Msg msg)
        subs _ =
            Sub.batch
                [ requestPort GotRequest
                , poolPort GotPoolDrop
                , Sub.map FromPort subscriptions
                ]
    in
    Platform.worker
        { init = (\flags -> (Model Dict.empty (init flags), Cmd.none))
        , update = update params.update incoming
        , subscriptions = subs
        }
