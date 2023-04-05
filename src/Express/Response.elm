module Express.Response exposing
    ( Response
    , empty
    , encode
    , html
    , json
    , lock
    , send
    , setCookie
    , status
    , text
    , unsetCookie
    )

import Express.Cookie as Cookie
import Express.Http as Http
import Express.Request as Request
import Json.Encode as E


type alias InternalResponse =
    { status : Http.Status
    , body : Http.Body
    , cookieSet : List Cookie.Cookie
    , cookieUnset : List Cookie.Cookie
    }


type Response
    = Unlocked InternalResponse
    | Locked InternalResponse


empty : Response
empty =
    Unlocked { status = Http.OK, body = Http.Text "", cookieSet = [], cookieUnset = [] }


extractInternalResponse : Response -> InternalResponse
extractInternalResponse response =
    case response of
        Unlocked res ->
            res

        Locked res ->
            res


map : (InternalResponse -> InternalResponse) -> Response -> Response
map fn response =
    case response of
        Unlocked res ->
            Unlocked <| fn res

        Locked _ ->
            response


lock : Response -> Response
lock response =
    case response of
        Unlocked res ->
            Locked res

        Locked _ ->
            response


send : Request.Id -> Response -> E.Value
send id response =
    E.object [ ( "id", E.string id ), ( "response", encode response ) ]


status : Http.Status -> Response -> Response
status status_ response =
    response |> map (\res -> { res | status = status_ })


text : String -> Response -> Response
text text_ response =
    response |> map (\res -> { res | body = Http.Text text_ })


json : E.Value -> Response -> Response
json val response =
    response |> map (\res -> { res | body = Http.Json val })


html : String -> Response -> Response
html html_ response =
    response |> map (\res -> { res | body = Http.Html html_ })


setCookie : Cookie.Cookie -> Response -> Response
setCookie cookie response =
    response |> map (\res -> { res | cookieSet = cookie :: res.cookieSet })


unsetCookie : Cookie.Cookie -> Response -> Response
unsetCookie cookie response =
    response |> map (\res -> { res | cookieUnset = cookie :: res.cookieUnset })


encode : Response -> E.Value
encode response =
    let
        internal =
            extractInternalResponse response
    in
    E.object
        [ ( "status", internal.status |> Http.statusToCode |> E.int )
        , ( "body", internal.body |> Http.encodeBody )
        , ( "cookieSet", internal.cookieSet |> E.list Cookie.encode )
        , ( "cookieUnset", internal.cookieUnset |> E.list Cookie.encode )
        ]
