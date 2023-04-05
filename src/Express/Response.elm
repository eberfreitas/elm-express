module Express.Response exposing
    ( Response
    , Status(..)
    , empty
    , encode
    , html
    , json
    , lock
    , map
    , send
    , setCookie
    , status
    , text
    , unsetCookie
    )

import Express.Cookie as Cookie
import Json.Encode as E



-- Reference: https://developer.mozilla.org/en-US/docs/Web/HTTP/Status


type Status
    = OK
    | NotFound
    | InternalServerError


type Body
    = Json E.Value
    | Text String
    | Html String


type alias InternalResponse =
    { status : Status
    , body : Body
    , cookieSet : List Cookie.Cookie
    , cookieUnset : List Cookie.Cookie
    }


type Response
    = Unlocked InternalResponse
    | Locked InternalResponse


bodyToMIMEType : Body -> String
bodyToMIMEType body =
    case body of
        Json _ ->
            "application/json"

        Text _ ->
            "text/plain"

        Html _ ->
            "text/html"


empty : Response
empty =
    Unlocked { status = OK, body = Text "", cookieSet = [], cookieUnset = [] }


extractInternalResponse : Response -> InternalResponse
extractInternalResponse response =
    case response of
        Unlocked res ->
            res

        Locked res ->
            res


map : (Response -> Response) -> Response -> Response
map mapFn response =
    case response of
        Unlocked _ ->
            mapFn response

        Locked _ ->
            response


internalMap : (InternalResponse -> InternalResponse) -> Response -> Response
internalMap fn response =
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


send : String -> Response -> E.Value
send id response =
    E.object [ ( "id", E.string id ), ( "response", encode response ) ]


status : Status -> Response -> Response
status status_ response =
    response |> internalMap (\res -> { res | status = status_ })


text : String -> Response -> Response
text text_ response =
    response |> internalMap (\res -> { res | body = Text text_ })


json : E.Value -> Response -> Response
json val response =
    response |> internalMap (\res -> { res | body = Json val })


html : String -> Response -> Response
html html_ response =
    response |> internalMap (\res -> { res | body = Html html_ })


setCookie : Cookie.Cookie -> Response -> Response
setCookie cookie response =
    response |> internalMap (\res -> { res | cookieSet = cookie :: res.cookieSet })


unsetCookie : Cookie.Cookie -> Response -> Response
unsetCookie cookie response =
    response |> internalMap (\res -> { res | cookieUnset = cookie :: res.cookieUnset })


statusToCode : Status -> Int
statusToCode status_ =
    case status_ of
        OK ->
            200

        NotFound ->
            404

        InternalServerError ->
            500


encodeBody : Body -> E.Value
encodeBody body =
    let
        mime =
            body |> bodyToMIMEType |> E.string
    in
    case body of
        Json val ->
            E.object [ ( "mime", mime ), ( "body", val ) ]

        Text text_ ->
            E.object [ ( "mime", mime ), ( "body", E.string text_ ) ]

        Html html_ ->
            E.object [ ( "mime", mime ), ( "body", E.string html_ ) ]


encode : Response -> E.Value
encode response =
    let
        res =
            extractInternalResponse response
    in
    E.object
        [ ( "status", res.status |> statusToCode |> E.int )
        , ( "body", res.body |> encodeBody )
        , ( "cookieSet", res.cookieSet |> E.list Cookie.encode )
        , ( "cookieUnset", res.cookieUnset |> E.list Cookie.encode )
        ]
