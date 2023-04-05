module Express exposing (Model, Msg, application)

import Dict
import Express.Conn as Conn
import Express.Request as Request
import Express.Response as Response
import Json.Decode as D
import Platform.Sub as Sub


type alias Model model =
    Conn.Pool model


type Msg msg
    = GotRequest D.Value
    | GotPoolDrop String
    | AppMsg String msg
    | FromPort msg


update :
    AppUpdate msg model
    -> AppInit msg model
    -> Msg msg
    -> Model model
    -> ( Model model, Cmd (Msg msg) )
update appUpdate appInit msg model =
    case msg of
        GotRequest raw ->
            raw
                |> D.decodeValue Request.decode
                |> Result.map
                    (\request ->
                        let
                            ( conn, appCmds ) =
                                appInit request Response.empty

                            requestId =
                                Request.id request

                            nextModel =
                                model |> Dict.insert (Request.id request) conn
                        in
                        ( nextModel, Cmd.map (AppMsg requestId) appCmds )
                    )
                |> Result.withDefault ( model, Cmd.none )

        GotPoolDrop uuid ->
            ( model |> Dict.remove uuid, Cmd.none )

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
                                Dict.insert requestId conn model
                        in
                        ( nextModel, appCmds |> Cmd.map (AppMsg requestId) )
                    )
                |> Maybe.withDefault ( model, Cmd.none )


type alias AppInit msg model =
    Request.Request -> Response.Response -> ( Conn.Conn model, Cmd msg )


type alias AppUpdate msg model =
    msg -> Model model -> ( Maybe (Conn.Conn model), Cmd msg )


type alias ApplicationParams msg model =
    { requestPort : (D.Value -> Msg msg) -> Sub.Sub (Msg msg)
    , poolPort : (String -> Msg msg) -> Sub.Sub (Msg msg)
    , init : AppInit msg model
    , subscriptions : Sub.Sub msg
    , update : AppUpdate msg model
    }


application : ApplicationParams msg a -> Program () (Model a) (Msg msg)
application ({ requestPort, poolPort, init, subscriptions } as params) =
    let
        subs : Model a -> Sub (Msg msg)
        subs _ =
            Sub.batch
                [ requestPort GotRequest
                , poolPort GotPoolDrop
                , Sub.map FromPort subscriptions
                ]
    in
    Platform.worker
        { init = \_ -> ( Dict.empty, Cmd.none )
        , update = update params.update init
        , subscriptions = subs
        }
