port module Main exposing (main)

import Express exposing (Conn)
import Express.Cookie as Cookie
import Express.Http as Http exposing (Method(..))
import Express.Request as Request
import Express.Response as Response
import Json.Decode as D
import Json.Encode as E
import Url.Parser as Parser exposing ((</>))


port requestPort : (D.Value -> msg) -> Sub.Sub msg


port poolPort : (String -> msg) -> Sub.Sub msg


port responsePort : E.Value -> Cmd.Cmd msg


port requestReverse : E.Value -> Cmd.Cmd msg


port gotReverse : (E.Value -> msg) -> Sub.Sub msg


type Model
    = NotFound
    | HelloWorld
    | Reverse String
    | PortReverse String
    | Cookies
    | SetCookie String String
    | UnsetCookie String


type Msg
    = GotReverse D.Value


route : Parser.Parser (Model -> a) a
route =
    Parser.oneOf
        [ Parser.map HelloWorld Parser.top
        , Parser.map Reverse (Parser.s "reverse" </> Parser.string)
        , Parser.map PortReverse (Parser.s "port-reverse" </> Parser.string)
        , Parser.map Cookies (Parser.s "cookies")
        , Parser.map SetCookie (Parser.s "cookies" </> Parser.s "set" </> Parser.string </> Parser.string)
        , Parser.map UnsetCookie (Parser.s "cookies" </> Parser.s "unset" </> Parser.string)
        ]


encodeToPortReverse : Request.Id -> String -> E.Value
encodeToPortReverse id text =
    E.object [ ( "requestId", E.string id ), ( "text", E.string text ) ]


init : Request.Request -> Response.Response -> ( Express.Conn Model, Cmd Msg )
init request response =
    let
        requestId =
            Request.id request

        requestMethod =
            Request.method request

        model =
            request |> Request.url |> Parser.parse route |> Maybe.withDefault NotFound

        respond =
            Response.send requestId >> responsePort

        ( nextResponse, cmd ) =
            case ( requestMethod, model ) of
                ( GET, HelloWorld ) ->
                    let
                        res =
                            response |> Response.text "Hello world!"
                    in
                    ( res, respond res )

                ( GET, Reverse text ) ->
                    let
                        res =
                            response |> Response.text (String.reverse text)
                    in
                    ( res, respond res )

                ( GET, PortReverse text ) ->
                    ( response, requestReverse <| encodeToPortReverse requestId text )

                ( GET, Cookies ) ->
                    let
                        cookiesValue =
                            request
                                |> Request.cookies
                                |> E.dict identity E.string

                        res =
                            response |> Response.json cookiesValue
                    in
                    ( res, respond res )

                ( GET, SetCookie name value ) ->
                    let
                        cookie =
                            Cookie.new request name value Cookie.Session

                        res =
                            response |> Response.setCookie cookie |> Response.text ("Cookie - " ++ name ++ ": " ++ value)
                    in
                    ( res, respond res )

                ( GET, UnsetCookie name ) ->
                    let
                        res =
                            request
                                |> Request.cookie name
                                |> Maybe.map (\value -> Cookie.new request name value (Cookie.Session))
                                |> Maybe.map (\cookie ->  response |> Response.unsetCookie cookie |> Response.text ("Cookie - " ++ name))
                                |> Maybe.withDefault (response |> Response.text "No cookie found")
                    in
                    ( res, respond res )

                _ ->
                    let
                        res =
                            response |> Response.status Http.NotFound |> Response.text "Not found"
                    in
                    ( res, respond res )
    in
    ( { request = request, response = nextResponse, model = model }, cmd )


subscriptions : Sub Msg
subscriptions =
    gotReverse GotReverse


update : Msg -> Express.Model Model -> ( Result (Express.AppError err) (Conn Model), Cmd Msg )
update msg pool =
    case msg of
        GotReverse raw ->
            let
                reverse conn data =
                    let
                        nextResponse =
                            conn.response |> Response.text data

                        nextConn =
                            { conn | response = nextResponse } |> Result.Ok
                    in
                    ( nextConn
                    , nextResponse
                        |> Response.send (Request.id conn.request)
                        |> responsePort
                    )
            in
            Express.portHelper pool raw (D.field "reversed" D.string) reverse


main : Program () (Express.Model Model) (Express.Msg Msg)
main =
    Express.application
        { requestPort = requestPort
        , poolPort = poolPort
        , init = init
        , subscriptions = subscriptions
        , update = update
        }

