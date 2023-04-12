module Express.Request exposing
    ( Method(..)
    , Request
    , body
    , cookie
    , cookies
    , decode
    , decodeRequestId
    , header
    , headers
    , id
    , method
    , now
    , session
    , stringToMethod
    , url
    )

import Dict
import Json.Decode as D
import Time
import Url


type Method
    = GET
    | HEAD
    | POST
    | PUT
    | DELETE
    | PATCH


type Request
    = Request
        { id : String
        , now : Time.Posix
        , method : Method
        , url : Url.Url
        , body : String
        , headers : Dict.Dict String String
        , cookies : Dict.Dict String String
        , session : Dict.Dict String String
        }


methodMap : Dict.Dict String Method
methodMap =
    let
        helper : List ( String, Method ) -> List ( String, Method )
        helper list =
            case List.head list of
                Nothing ->
                    ( "GET", GET ) :: list |> helper

                Just ( _, GET ) ->
                    ( "HEAD", HEAD ) :: list |> helper

                Just ( _, HEAD ) ->
                    ( "POST", POST ) :: list |> helper

                Just ( _, POST ) ->
                    ( "PUT", PUT ) :: list |> helper

                Just ( _, PUT ) ->
                    ( "DELETE", DELETE ) :: list |> helper

                Just ( _, DELETE ) ->
                    ( "PATCH", PATCH ) :: list |> helper

                Just ( _, PATCH ) ->
                    list
    in
    [] |> helper |> Dict.fromList


stringToMethod : String -> Maybe Method
stringToMethod method_ =
    Dict.get method_ methodMap


decode : D.Decoder Request
decode =
    D.map8
        (\id_ now_ method_ url_ headers_ body_ cookies_ session_ ->
            Request
                { id = id_
                , now = now_
                , method = method_
                , url = url_
                , headers = headers_
                , body = body_
                , cookies = cookies_
                , session = session_
                }
        )
        (D.field "id" D.string)
        (D.field "now" D.int |> D.map Time.millisToPosix)
        (D.field "method" D.string
            |> D.andThen
                (\m -> m |> stringToMethod |> Maybe.map D.succeed |> Maybe.withDefault (D.fail <| "Unsupported HTTP method: " ++ m))
        )
        (D.field "url" D.string
            |> D.andThen
                (\u -> u |> Url.fromString |> Maybe.map D.succeed |> Maybe.withDefault (D.fail <| "Malformed URL: " ++ u))
        )
        (D.field "headers" (D.keyValuePairs D.string) |> D.map Dict.fromList)
        (D.field "body" D.string)
        (D.field "cookies" (D.keyValuePairs D.string) |> D.map Dict.fromList)
        (D.field "session" (D.keyValuePairs D.string) |> D.map Dict.fromList)


decodeRequestId : D.Value -> Result D.Error String
decodeRequestId raw =
    raw |> D.decodeValue (D.field "requestId" D.string)


id : Request -> String
id (Request req) =
    req.id


now : Request -> Time.Posix
now (Request req) =
    req.now


url : Request -> Url.Url
url (Request req) =
    req.url


method : Request -> Method
method (Request req) =
    req.method


headers : Request -> Dict.Dict String String
headers (Request req) =
    req.headers


header : String -> Request -> Maybe String
header key (Request req) =
    Dict.get key req.headers


cookies : Request -> Dict.Dict String String
cookies (Request req) =
    req.cookies


cookie : String -> Request -> Maybe String
cookie key (Request req) =
    Dict.get key req.cookies


session : String -> Request -> Maybe String
session key (Request req) =
    Dict.get key req.session


body : Request -> String
body (Request req) =
    req.body
