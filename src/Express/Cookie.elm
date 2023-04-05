module Express.Cookie exposing
    ( Cookie
    , Expires(..)
    , SameSite(..)
    , domain
    , encode
    , expires
    , httpOnly
    , new
    , path
    , sameSite
    , secure
    , signed
    )

import Express.Request as Request
import Html.Attributes exposing (name, value)
import Json.Encode as E
import Time


type Expires
    = At Time.Posix
    | Session


type SameSite
    = None
    | Strict
    | Lax


type Cookie
    = Cookie
        { name : String
        , value : String
        , domain : String
        , expires : Expires
        , httpOnly : Bool
        , path : String
        , secure : Bool
        , signed : Bool
        , sameSite : SameSite
        }


encodeExpires : Expires -> E.Value
encodeExpires expires_ =
    case expires_ of
        At posix ->
            E.object [ ( "type", E.string "at" ), ( "posix", E.int <| Time.posixToMillis posix ) ]

        Session ->
            E.object [ ( "type", E.string "session" ) ]


encodeSameSite : SameSite -> E.Value
encodeSameSite sameSite_ =
    case sameSite_ of
        None ->
            E.string "None"

        Strict ->
            E.string "Strict"

        Lax ->
            E.string "Lax"


encode : Cookie -> E.Value
encode (Cookie cookie) =
    E.object
        [ ( "name", E.string cookie.name )
        , ( "value", E.string cookie.value )
        , ( "domain", E.string cookie.domain )
        , ( "expires", encodeExpires cookie.expires )
        , ( "httpOnly", E.bool cookie.httpOnly )
        , ( "path", E.string cookie.path )
        , ( "secure", E.bool cookie.secure )
        , ( "signed", E.bool cookie.signed )
        , ( "sameSite", encodeSameSite cookie.sameSite )
        ]


new : Request.Request -> String -> String -> Expires -> Cookie
new request name value expires_ =
    Cookie
        { name = name
        , value = value
        , domain = request |> Request.url |> .host
        , expires = expires_
        , httpOnly = False
        , path = "/"
        , secure = False
        , signed = False
        , sameSite = Strict
        }


domain : String -> Cookie -> Cookie
domain domain_ (Cookie cookie) =
    { cookie | domain = domain_ } |> Cookie


expires : Expires -> Cookie -> Cookie
expires expires_ (Cookie cookie) =
    { cookie | expires = expires_ } |> Cookie


httpOnly : Bool -> Cookie -> Cookie
httpOnly toggle (Cookie cookie) =
    { cookie | httpOnly = toggle } |> Cookie


path : String -> Cookie -> Cookie
path path_ (Cookie cookie) =
    { cookie | path = path_ } |> Cookie


secure : Bool -> Cookie -> Cookie
secure toggle (Cookie cookie) =
    { cookie | secure = toggle } |> Cookie


signed : Bool -> Cookie -> Cookie
signed toggle (Cookie cookie) =
    { cookie | signed = toggle } |> Cookie


sameSite : SameSite -> Cookie -> Cookie
sameSite sameSite_ (Cookie cookie) =
    { cookie | sameSite = sameSite_ } |> Cookie
