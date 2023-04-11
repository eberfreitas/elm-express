module Express.Response exposing
    ( Redirect(..)
    , Response
    , Status(..)
    , encode
    , html
    , json
    , lock
    , map
    , new
    , rawRedirect
    , redirect
    , send
    , setCookie
    , setHeader
    , setSession
    , status
    , text
    , unsetCookie
    , unsetSession
    )

import Dict
import Express.Cookie as Cookie
import Json.Encode as E



-- Reference: https://developer.mozilla.org/en-US/docs/Web/HTTP/Status


type Status
    = OK
    | NotFound
    | InternalServerError


type Redirect
    = MovedPermanently String
    | Found String


type Body
    = Json E.Value
    | Text String
    | Html String


type alias InternalResponse =
    { status : Status
    , body : Body
    , headers : Dict.Dict String String
    , cookieSet : List Cookie.Cookie
    , cookieUnset : List Cookie.Cookie
    , sessionSet : Dict.Dict String String
    , sessionUnset : List String
    , redirect : Maybe Redirect
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


new : Response
new =
    Unlocked
        { status = OK
        , body = Text ""
        , cookieSet = []
        , cookieUnset = []
        , sessionSet = Dict.empty
        , sessionUnset = []
        , headers = Dict.empty
        , redirect = Nothing
        }


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


setHeader : String -> String -> Response -> Response
setHeader name value response =
    response |> internalMap (\res -> { res | headers = Dict.insert name value res.headers })


setCookie : Cookie.Cookie -> Response -> Response
setCookie cookie response =
    response |> internalMap (\res -> { res | cookieSet = cookie :: res.cookieSet })


unsetCookie : Cookie.Cookie -> Response -> Response
unsetCookie cookie response =
    response |> internalMap (\res -> { res | cookieUnset = cookie :: res.cookieUnset })


setSession : String -> String -> Response -> Response
setSession key value response =
    response |> internalMap (\res -> { res | sessionSet = Dict.insert key value res.sessionSet })


unsetSession : String -> Response -> Response
unsetSession key response =
    response |> internalMap (\res -> { res | sessionUnset = key :: res.sessionUnset })


redirect : String -> Response -> Response
redirect path response =
    response |> internalMap (\res -> { res | redirect = Just (Found path) }) |> lock


rawRedirect : Redirect -> Response -> Response
rawRedirect redirect_ response =
    response |> internalMap (\res -> { res | redirect = Just redirect_ }) |> lock


statusToCode : Status -> Int
statusToCode status_ =
    case status_ of
        OK ->
            200

        NotFound ->
            404

        InternalServerError ->
            500


redirectToCodeAndPath : Redirect -> ( Int, String )
redirectToCodeAndPath redirect_ =
    case redirect_ of
        MovedPermanently path ->
            ( 301, path )

        Found path ->
            ( 302, path )


encodeRedirect : Maybe Redirect -> E.Value
encodeRedirect redirect_ =
    redirect_
        |> Maybe.map
            (redirectToCodeAndPath
                >> (\( code, path ) -> E.object [ ( "code", E.int code ), ( "path", E.string path ) ])
            )
        |> Maybe.withDefault E.null


encodeBody : Body -> E.Value
encodeBody body =
    let
        mime: E.Value
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
        res : InternalResponse
        res =
            extractInternalResponse response
    in
    E.object
        [ ( "status", res.status |> statusToCode |> E.int )
        , ( "body", res.body |> encodeBody )
        , ( "headers", res.headers |> E.dict identity E.string )
        , ( "cookieSet", res.cookieSet |> E.list Cookie.encode )
        , ( "cookieUnset", res.cookieUnset |> E.list Cookie.encode )
        , ( "sessionSet", res.sessionSet |> E.dict identity E.string )
        , ( "sessionUnset", res.sessionUnset |> E.list E.string )
        , ( "redirect", res.redirect |> encodeRedirect )
        ]
