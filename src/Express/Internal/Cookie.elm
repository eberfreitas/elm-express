module Express.Internal.Cookie exposing
    ( Cookie
    , domain
    , encode
    , httpOnly
    , maxAge
    , new
    , path
    , sameSite
    , secure
    , signed
    )

import Express.Request as Request
import Json.Encode as E
import Url


type Cookie
    = Cookie
        { name : String
        , value : String
        , domain : String
        , maxAge : Maybe Int
        , httpOnly : Bool
        , path : String
        , secure : Bool
        , signed : Bool
        , sameSite : String
        }


encode : Cookie -> E.Value
encode (Cookie cookie) =
    E.object
        [ ( "name", E.string cookie.name )
        , ( "value", E.string cookie.value )
        , ( "domain", E.string cookie.domain )
        , ( "maxAge", cookie.maxAge |> Maybe.map E.int |> Maybe.withDefault E.null )
        , ( "httpOnly", E.bool cookie.httpOnly )
        , ( "path", E.string cookie.path )
        , ( "secure", E.bool cookie.secure )
        , ( "signed", E.bool cookie.signed )
        , ( "sameSite", E.string cookie.sameSite )
        ]


new : Request.Request -> String -> String -> Maybe Int -> Cookie
new request name value maxAge_ =
    Cookie
        { name = name
        , value = value
        , domain = request |> Request.url |> .host
        , maxAge = maxAge_
        , httpOnly = True
        , path = "/"
        , secure =
            if request |> Request.url |> .protocol |> (==) Url.Https then
                True

            else
                False
        , signed = True
        , sameSite = "Strict"
        }


domain : String -> Cookie -> Cookie
domain domain_ (Cookie cookie) =
    { cookie | domain = domain_ } |> Cookie


maxAge : Maybe Int -> Cookie -> Cookie
maxAge maxAge_ (Cookie cookie) =
    { cookie | maxAge = maxAge_ } |> Cookie


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


sameSite : String -> Cookie -> Cookie
sameSite sameSite_ (Cookie cookie) =
    { cookie | sameSite = sameSite_ } |> Cookie
