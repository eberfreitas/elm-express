module Express.Request exposing
    ( Id
    , Request
    , cookie
    , cookies
    , decode
    , header
    , headers
    , id
    , method
    , now
    , url
    )

import Dict
import Express.Http as Http
import Json.Decode as D
import Time
import Url


type alias Id =
    String


type Request
    = Request
        { id : Id
        , now : Time.Posix
        , method : Http.Method
        , url : Url.Url
        , headers : Dict.Dict String String
        , body : String
        , cookies : Dict.Dict String String
        }


decode : D.Decoder Request
decode =
    D.map7
        (\id_ now_ method_ url_ headers_ body_ cookies_ ->
            Request
                { id = id_
                , now = now_
                , method = method_
                , url = url_
                , headers = headers_
                , body = body_
                , cookies = cookies_
                }
        )
        (D.field "id" D.string)
        (D.field "now" D.int |> D.map Time.millisToPosix)
        (D.field "method" D.string
            |> D.andThen
                (\m -> m |> Http.stringToMethod |> Maybe.map D.succeed |> Maybe.withDefault (D.fail <| "Unsupported HTTP method: " ++ m))
        )
        (D.field "url" D.string
            |> D.andThen
                (\u -> u |> Url.fromString |> Maybe.map D.succeed |> Maybe.withDefault (D.fail <| "Malformed URL: " ++ u))
        )
        (D.field "headers" (D.keyValuePairs D.string) |> D.map Dict.fromList)
        (D.field "body" D.string)
        (D.field "cookies" (D.keyValuePairs D.string) |> D.map Dict.fromList)


id : Request -> Id
id (Request req) =
    req.id


now : Request -> Time.Posix
now (Request req) =
    req.now


url : Request -> Url.Url
url (Request req) =
    req.url


method : Request -> Http.Method
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
