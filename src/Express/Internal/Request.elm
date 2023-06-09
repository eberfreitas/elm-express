module Express.Internal.Request exposing
    ( Method(..)
    , Request
    , body
    , cookie
    , cookies
    , decode
    , header
    , headers
    , id
    , method
    , now
    , session
    , url
    )

import Dict
import Json.Decode as D
import Time
import Url


type Method
    = Get
    | Head
    | Post
    | Put
    | Delete
    | Patch
    | Checkout
    | Copy
    | Lock
    | Merge
    | Mkactivity
    | Mkcol
    | Move
    | Notify
    | Options
    | Purge
    | Report
    | Search
    | Subscribe
    | Trace
    | Unlock
    | Unsubscribe


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
                    ( "GET", Get ) :: list |> helper

                Just ( _, Get ) ->
                    ( "HEAD", Head ) :: list |> helper

                Just ( _, Head ) ->
                    ( "POST", Post ) :: list |> helper

                Just ( _, Post ) ->
                    ( "PUT", Put ) :: list |> helper

                Just ( _, Put ) ->
                    ( "DELETE", Delete ) :: list |> helper

                Just ( _, Delete ) ->
                    ( "PATCH", Patch ) :: list |> helper

                Just ( _, Patch ) ->
                    ( "CHECKOUT", Checkout ) :: list |> helper

                Just ( _, Checkout ) ->
                    ( "COPY", Copy ) :: list |> helper

                Just ( _, Copy ) ->
                    ( "LOCK", Lock ) :: list |> helper

                Just ( _, Lock ) ->
                    ( "MERGE", Merge ) :: list |> helper

                Just ( _, Merge ) ->
                    ( "MKACTIVITY", Mkactivity ) :: list |> helper

                Just ( _, Mkactivity ) ->
                    ( "MKCOL", Mkcol ) :: list |> helper

                Just ( _, Mkcol ) ->
                    ( "MOVE", Move ) :: list |> helper

                Just ( _, Move ) ->
                    ( "NOTIFY", Notify ) :: list |> helper

                Just ( _, Notify ) ->
                    ( "OPTIONS", Options ) :: list |> helper

                Just ( _, Options ) ->
                    ( "PURGE", Purge ) :: list |> helper

                Just ( _, Purge ) ->
                    ( "REPORT", Report ) :: list |> helper

                Just ( _, Report ) ->
                    ( "SEARCH", Search ) :: list |> helper

                Just ( _, Search ) ->
                    ( "SUBSCRIBE", Subscribe ) :: list |> helper

                Just ( _, Subscribe ) ->
                    ( "TRACE", Trace ) :: list |> helper

                Just ( _, Trace ) ->
                    ( "UNLOCK", Unlock ) :: list |> helper

                Just ( _, Unlock ) ->
                    ( "UNSUBSCRIBE", Unsubscribe ) :: list |> helper

                Just ( _, Unsubscribe ) ->
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
