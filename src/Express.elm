module Express exposing (Conn, Model, Msg, AppError(..), application, portHelper)

import Dict
import Express.Request as Request
import Express.Response as Response
import Json.Decode as D
import Platform.Sub as Sub


type alias Conn model =
    { request : Request.Request
    , response : Response.Response
    , model : model
    }


type alias Model model =
    Dict.Dict String (Conn model)


type Msg msg
    = GotRequest D.Value
    | GotPoolDrop String
    | AppMsg Request.Id msg
    | FromPort msg


type AppError a
    = DecodingError D.Error
    | RequestNotInPoolError
    | UnknownError
    | CustomError a


portHelper :
    Model model
    -> D.Value
    -> D.Decoder a
    -> (Conn model -> a -> (Result.Result (AppError b) (Conn model), Cmd.Cmd msg) )
    -> ( Result.Result (AppError b) (Conn model), Cmd.Cmd msg )
portHelper pool raw decoder callback =
    let
        portDecoder : D.Decoder { id : Request.Id, data : a }
        portDecoder =
            D.map2 (\id data -> { id = id, data = data })
                (D.field "id" D.string)
                decoder

        decode result =
            case result of
                Ok { id, data } ->
                    resolveConn id data

                Err err ->
                    ( Result.Err (DecodingError err), Cmd.none )

        resolveConn id data =
            case Dict.get id pool of
                Just conn ->
                    callback conn data

                Nothing ->
                    ( Result.Err RequestNotInPoolError, Cmd.none )
    in
    raw |> D.decodeValue portDecoder |> decode


update :
    AppUpdate err msg model
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
                |> Result.map
                    (\conn ->
                        let
                            requestId =
                                Request.id conn.request

                            nextModel =
                                Dict.insert requestId conn model
                        in
                        ( nextModel, appCmds |> Cmd.map (AppMsg requestId) )
                    )
                |> Result.withDefault ( model, Cmd.none )


type alias AppInit msg model =
    Request.Request -> Response.Response -> ( Conn model, Cmd msg )


type alias AppUpdate err msg model =
    msg -> Model model -> ( Result (AppError err) (Conn model), Cmd msg )


type alias ApplicationParams err msg model =
    { requestPort : (D.Value -> Msg msg) -> Sub.Sub (Msg msg)
    , poolPort : (String -> Msg msg) -> Sub.Sub (Msg msg)
    , init : AppInit msg model
    , subscriptions : Sub.Sub msg
    , update : AppUpdate err msg model
    }


application : ApplicationParams err msg a -> Program () (Model a) (Msg msg)
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
