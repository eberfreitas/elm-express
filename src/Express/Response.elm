module Express.Response exposing
    ( Response, Status(..), Redirect(..)
    , new
    , text, json, html, status, setHeader
    , redirect, rawRedirect
    , setCookie, unsetCookie
    , setSession, unsetSession
    , lock, map
    , send
    )

{-| This module allows you to create new responses and manipulate them in order to send them to the client. It tries to
simplify the interaction compared with the original [Express.js API](https://expressjs.com/en/4x/api.html#res) by
allowing only one way to define things and going to the lowest layers while abstracting some inconsistencies and
providing type safety to the response definition.


# Types

@docs Response, Status, Redirect


# Creating responses

@docs new


# Adding content

@docs text, json, html, status, setHeader


# Redirecting

@docs redirect, rawRedirect


# Cookies

@docs setCookie, unsetCookie


# Session

@docs setSession, unsetSession


# Manipulating responses

@docs lock, map


# Helpers

@docs send

-}

import Dict
import Express.Cookie as Cookie
import Express.Internal.Cookie as InternalCookie
import Express.Request as Request
import Json.Encode as E


type Body
    = Json E.Value
    | Text String
    | Html String


{-| The `Status` type describes the possible response statuses that you can send.

Reference: <https://developer.mozilla.org/en-US/docs/Web/HTTP/Status>

-}
type Status
    = OK
    | NotFound
    | InternalServerError


{-| The `Redirect` type defines the possible redirection statuses you can use when sending a response.

Reference: <https://developer.mozilla.org/en-US/docs/Web/HTTP/Status#redirection_messages>

-}
type Redirect
    = MovedPermanently String
    | Found String


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


{-| The `Response` type wraps the actual definition of your response. It can appear in two different states:

  - `Unlocked`: means you can manipulate the response and change its properties;
  - `Locked`: means that whatever changes you perform in the response won't have any effect.

When you create a new response using the `new` function, it will be `Unlocked` by default. You can always lock a
response using the `lock` function.

But why do we need that? Consider that you have a middleware that will check if the user is logged in, and if they are
not, you want to redirect to the login page. The middleware will run at the very start of the request cycle and you
probably don't want any other parts of your application to change the state of the response if the user needs to be
redirected. That is why we lock the response. Once locked, the response's state will never change and whatever your
middleware decided to do will be respected.

-}
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


{-| Creates a new, mostly empty, response. It will have a `OK` status and an empty text body. Once created you can
manipulate the contents of the response with other functions from this module.

    response =
        Express.Response.new

-}
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


{-| When manipulating responses it is advised to wrap those manipulations inside the `map` function.

Imagine that you have something expensive to run during a request, but the existing response you are manipulating has
been locked. Using the `map` function you guarantee that any manipulation will only be called if the response is
unlocked.

    newResponse =
        oldResponse |> Express.Response.map (Express.Response.text "IT WORKS!")

-}
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


{-| Locks the response guaranteeing that it can't be changed after this fact.

    lockedResponse =
        Express.Response.lock unlockedResponse

-}
lock : Response -> Response
lock response =
    case response of
        Unlocked res ->
            Locked res

        Locked _ ->
            response


{-| Sets the status of the response.

    somethingTerribleHasHappened =
        Express.Response.status Express.Response.InternalServerError response

-}
status : Status -> Response -> Response
status status_ response =
    response |> internalMap (\res -> { res | status = status_ })


{-| Sets a plain text response.

    textResponse =
        Express.Response.text "Hello world!" response

-}
text : String -> Response -> Response
text text_ response =
    response |> internalMap (\res -> { res | body = Text text_ })


{-| Sets a JSON response.

    jsonResponse =
        Express.Response.text encodedValue response

-}
json : E.Value -> Response -> Response
json val response =
    response |> internalMap (\res -> { res | body = Json val })


{-| Sets a HTML response. The HTML should be represented as a string but you can use packages like
[zwilias/elm-html-string](https://package.elm-lang.org/packages/zwilias/elm-html-string/latest/) to generate HTML like
you would for front-end code. We also include a `Html.String.Extra` module with `elm-review` to allow you to create
full HTML documents.

There is a full example in the `/example` folder in the repository/source.

    htmlResponse =
        Express.Response.html "<h1>Hello World</h1>" response

-}
html : String -> Response -> Response
html html_ response =
    response |> internalMap (\res -> { res | body = Html html_ })


{-| Sets a header in the response.

    newResponse =
        Express.Response.setHeader
            "X-Awesome-Header"
            "Look ma! No JS!"
            oldResponse

-}
setHeader : String -> String -> Response -> Response
setHeader name value response =
    response |> internalMap (\res -> { res | headers = Dict.insert name value res.headers })


{-| Sets a cookie with the response. To learn how to create a new cookie visit the docs for `Express.Cookie` module.

    newResponse =
        Express.Response.setCookie myCookie oldResponse

-}
setCookie : Cookie.Cookie -> Response -> Response
setCookie cookie response =
    response |> internalMap (\res -> { res | cookieSet = cookie :: res.cookieSet })


{-| Deletes a cookie. In order to delete a cookie you must recreate it with the same properties as the original cookie
excluding `maxAge`.

    newResponse =
        Express.Response.unsetCookie badCookie oldResponse

-}
unsetCookie : Cookie.Cookie -> Response -> Response
unsetCookie cookie response =
    response |> internalMap (\res -> { res | cookieUnset = cookie :: res.cookieUnset })


{-| Sets a new session data.

    newResponse =
        Express.Response.setSession "user" userDataAsString oldResponse

-}
setSession : String -> String -> Response -> Response
setSession key value response =
    response |> internalMap (\res -> { res | sessionSet = Dict.insert key value res.sessionSet })


{-| Deletes a session data.

    newResponse =
        Express.Response.unsetSession "flashMsg" oldResponse

-}
unsetSession : String -> Response -> Response
unsetSession key response =
    response |> internalMap (\res -> { res | sessionUnset = key :: res.sessionUnset })


{-| Makes the response redirect to another URL/path. This will make a simple `Found` (302) redirect. To use other
redirection statuses, use `rawRedirect`.

_Attention_: this function **locks** the response.

    redirect =
        Express.Response.redirect "/login" response

-}
redirect : String -> Response -> Response
redirect path response =
    response |> internalMap (\res -> { res | redirect = Just (Found path) }) |> lock


{-| Makes the response directs to another URL/path using the specified `Redirect` type you wanna use.

_Attention_: this function **locks** the response.

    redirect =
        Express.Response.rawRedirect (Express.Response.MovedPermanently "/new-blog/article/123") response

-}
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
        mime : E.Value
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
        , ( "cookieSet", res.cookieSet |> E.list InternalCookie.encode )
        , ( "cookieUnset", res.cookieUnset |> E.list InternalCookie.encode )
        , ( "sessionSet", res.sessionSet |> E.dict identity E.string )
        , ( "sessionUnset", res.sessionUnset |> E.list E.string )
        , ( "redirect", res.redirect |> encodeRedirect )
        ]


{-| Helper function to send a response. This is most useful if you still don't have a `Conn` in place like in
middlewares. When you have a `Conn` you can use `Express.Conn.send` instead.

Here is how you can use this to create a response command:

    cmd =
        Express.Response send request response |> responsePort

-}
send : Request.Request -> Response -> E.Value
send request response =
    E.object [ ( "requestId", E.string (Request.id request) ), ( "response", encode response ) ]
