port module Main exposing (main)

import Express
import Express.Conn as Conn
import Express.Cookie as Cookie
import Express.Request as Request
import Express.Response as Response
import Html.String as Html
import Html.String.Attributes as Attrs
import Http
import Json.Decode as D
import Json.Encode as E
import Result
import Url.Parser as Parser exposing ((</>))


port requestPort : (D.Value -> msg) -> Sub.Sub msg


port poolPort : (String -> msg) -> Sub.Sub msg


port responsePort : E.Value -> Cmd.Cmd msg


port errorPort : String -> Cmd.Cmd msg


port requestReverse : E.Value -> Cmd.Cmd msg


port gotReverse : (E.Value -> msg) -> Sub.Sub msg


type Model
    = NotFound
    | Home
    | Reverse String
    | PortReverse String
    | Cookies
    | SetCookie String String
    | UnsetCookie String
    | Session String
    | SetSession String String
    | UnsetSession String
    | Redirect
    | Task


type Msg
    = GotReverse D.Value
    | GotTask (Result.Result Http.Error String)


route : Parser.Parser (Model -> a) a
route =
    Parser.oneOf
        [ Parser.map Home Parser.top
        , Parser.map Reverse (Parser.s "reverse" </> Parser.string)
        , Parser.map PortReverse (Parser.s "port-reverse" </> Parser.string)
        , Parser.map Cookies (Parser.s "cookies")
        , Parser.map SetCookie (Parser.s "cookies" </> Parser.s "set" </> Parser.string </> Parser.string)
        , Parser.map UnsetCookie (Parser.s "cookies" </> Parser.s "unset" </> Parser.string)
        , Parser.map Session (Parser.s "session" </> Parser.string)
        , Parser.map SetSession (Parser.s "session" </> Parser.s "set" </> Parser.string </> Parser.string)
        , Parser.map UnsetSession (Parser.s "session" </> Parser.s "unset" </> Parser.string)
        , Parser.map Redirect (Parser.s "redirect")
        , Parser.map Task (Parser.s "task")
        ]


encodeToPortReverse : String -> String -> E.Value
encodeToPortReverse id text =
    E.object [ ( "requestId", E.string id ), ( "text", E.string text ) ]


incoming : () -> Request.Request -> Response.Response -> ( Conn.Conn Model, Cmd Msg )
incoming _ request response =
    let
        requestMethod =
            Request.method request

        model =
            request |> Request.url |> Parser.parse route |> Maybe.withDefault NotFound

        ( nextResponse, cmd ) =
            case ( requestMethod, model ) of
                ( Request.Post, Home ) ->
                    ( response |> Response.map (Response.html (htmlView (Request.body request |> Just))), Nothing )

                ( Request.Get, Home ) ->
                    ( response |> Response.map (Response.html (htmlView Nothing)), Nothing )

                ( Request.Get, Reverse text ) ->
                    ( response |> Response.map (Response.text (String.reverse text)), Nothing )

                ( Request.Get, PortReverse text ) ->
                    ( Just response, Just (requestReverse <| encodeToPortReverse (Request.id request) text) )

                ( Request.Get, Cookies ) ->
                    ( response |> Response.map (Response.json (request |> Request.cookies |> E.dict identity E.string))
                    , Nothing
                    )

                ( Request.Get, SetCookie name value ) ->
                    let
                        res =
                            response
                                |> Response.map
                                    (Response.setCookie (Cookie.new request name value Nothing)
                                        >> Response.text ("Cookie - " ++ name ++ ": " ++ value)
                                    )
                    in
                    ( res, Nothing )

                ( Request.Get, UnsetCookie name ) ->
                    let
                        res =
                            response
                                |> Response.map
                                    (\_ ->
                                        request
                                            |> Request.cookie name
                                            |> Maybe.map (\value -> Cookie.new request name value Nothing)
                                            |> Maybe.map (\cookie -> response |> Response.unsetCookie cookie |> Response.text ("Cookie - " ++ name))
                                            |> Maybe.withDefault (response |> Response.text "No cookie found")
                                    )
                    in
                    ( res, Nothing )

                ( Request.Get, Session key ) ->
                    ( response |> Response.map (Response.text (request |> Request.session key |> Maybe.withDefault "Session key not found."))
                    , Nothing
                    )

                ( Request.Get, SetSession key value ) ->
                    ( response |> Response.map (Response.setSession key value >> Response.text ("Session - " ++ key ++ ": " ++ value))
                    , Nothing
                    )

                ( Request.Get, UnsetSession key ) ->
                    ( response |> Response.map (Response.unsetSession key >> Response.text ("Session - " ++ key))
                    , Nothing
                    )

                ( Request.Get, Redirect ) ->
                    ( response |> Response.map (Response.redirect "/"), Nothing )

                ( Request.Get, Task ) ->
                    let
                        nextCmd =
                            Http.get
                                { url = "https://elm-lang.org/assets/public-opinion.txt"
                                , expect = Http.expectString GotTask
                                }
                    in
                    ( Just response, Just nextCmd )

                _ ->
                    ( response |> Response.map (Response.status Response.NotFound >> Response.text "Not found"), Nothing )

        conn =
            { request = request, response = nextResponse |> Maybe.withDefault response, model = model }
    in
    ( conn, cmd |> Maybe.withDefault (conn |> Conn.send |> responsePort) )


htmlTemplate : String -> String
htmlTemplate body =
    String.replace "{{BODY}}"
        body
        """
<!DOCTYPE html>
<html lang="en">
    <head>
        <title>elm-express</title>
        <link rel="stylesheet" href="https://unpkg.com/sakura.css/css/sakura.css" type="text/css" />
    </head>
    <body>
        {{BODY}}
    </body>
</html>
        """


htmlView : Maybe String -> String
htmlView postData =
    Html.div []
        [ Html.h1 [] [ Html.text "Hello from elm-express!" ]
        , Html.p []
            [ Html.text
                """
                This page is being rendered with server-side Elm, which means that the HTML you're seeing is
                being generated entirely on the server using Elm code. By using Elm on the server, we're able
                to leverage the same powerful language and tooling that we use on the client, making it easier
                to build complex and robust web applications.
                """
            ]
        , Html.form [ Attrs.method "post", Attrs.action "" ]
            [ Html.fieldset []
                [ Html.legend [] [ Html.text "Sample form" ]
                , Html.div []
                    [ Html.label [ Attrs.for "name" ] [ Html.text "Your name" ]
                    , Html.input [ Attrs.id "name", Attrs.name "name", Attrs.style "width" "100%" ] []
                    ]
                , Html.div []
                    [ Html.label [ Attrs.for "email" ] [ Html.text "Your e-mail" ]
                    , Html.input [ Attrs.id "email", Attrs.name "email", Attrs.style "width" "100%" ] []
                    ]
                , Html.div [] [ Html.button [ Attrs.type_ "submit" ] [ Html.text "Submit" ] ]
                ]
            ]
        , case postData of
            Just data ->
                Html.div []
                    [ Html.hr [] []
                    , Html.pre [] [ Html.text data ]
                    ]

            Nothing ->
                Html.text ""
        ]
        |> Html.toString 0
        |> htmlTemplate


subscriptions : Sub Msg
subscriptions =
    gotReverse GotReverse


update : () -> Msg -> Conn.Conn Model -> ( Conn.Conn Model, Cmd Msg )
update _ msg conn =
    case msg of
        GotReverse raw ->
            raw
                |> D.decodeValue (D.field "reversed" D.string)
                |> Result.map
                    (\reversed ->
                        let
                            nextConn =
                                { conn | response = conn.response |> Response.map (Response.text reversed) |> Maybe.withDefault conn.response }
                        in
                        ( nextConn, nextConn |> Conn.send |> responsePort )
                    )
                |> Result.withDefault ( conn, Cmd.none )

        GotTask result ->
            result
                |> Result.map
                    (\txt ->
                        let
                            nextConn =
                                { conn | response = conn.response |> Response.map (Response.text txt) |> Maybe.withDefault conn.response }
                        in
                        ( nextConn, nextConn |> Conn.send |> responsePort )
                    )
                |> Result.withDefault ( conn, Cmd.none )


dummyHeaderMiddleware : () -> Request.Request -> Response.Response -> ( Response.Response, Cmd.Cmd Msg )
dummyHeaderMiddleware _ _ response =
    ( response |> Response.setHeader "X-Dummy" "Never argue with the data.", Cmd.none )


decodeRequestId : Msg -> Result D.Error String
decodeRequestId msg =
    case msg of
        GotReverse raw ->
            Request.decodeRequestId raw

        _ ->
            Err <| D.Failure "Decoder not implemented" E.null


main : Program () (Express.Model Model ()) (Express.Msg Msg)
main =
    Express.application
        { init = \_ -> ()
        , requestPort = requestPort
        , responsePort = responsePort
        , errorPort = errorPort
        , poolPort = poolPort
        , incoming = incoming
        , subscriptions = subscriptions
        , update = update
        , middlewares = [ dummyHeaderMiddleware ]
        , decodeRequestId = decodeRequestId
        }
