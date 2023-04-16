module Express.Cookie exposing
    ( Cookie, SameSite(..)
    , new
    , domain, maxAge, httpOnly, path, secure, signed, sameSite
    )

{-| This module provides a set of types and functions that allow you to manage cookies in your `elm-express`
application. This includes setting, reading, and deleting cookies during requests. The module offers a range of options
for working with cookies, such as setting the expiration date and domain for a cookie. By using the functions provided
in this module, you can ensure that cookies are managed securely and efficiently within your application.

It aims to provide a straightforward way to work with cookies in Elm that is based on the Express.js API, while also
including some slight adaptations when necessary. To a more comprehensive understanding it is recommended to read the
Express.js [documentation](https://expressjs.com/en/4x/api.html#res.cookie) surrounding cookie setting.


# Types

@docs Cookie, SameSite


# Creating a cookie

@docs new


# Handling cookies

@docs domain, maxAge, httpOnly, path, secure, signed, sameSite

-}

import Express.Internal.Cookie as InternalCookie
import Express.Request as Request


{-| The `SameSite` type describe the three possible values for the `sameSite` key in the cookie definition. To better
understand the effects of each value we recommend [this article](https://owasp.org/www-community/SameSite) from the
OWASP website.
-}
type SameSite
    = None
    | Strict
    | Lax


{-| The `Cookie` type is an [opaque type](https://sporto.github.io/elm-patterns/advanced/opaque-types.html) that
describes a cookie according with Express.js APIs. It contains all the required information on the Express.js
[documentation](https://expressjs.com/en/4x/api.html#res.cookie) to define a cookie.

One particular difference is that we don't use the `expires` key, only the `maxAge` key. That means you can't specify a
precise date and time in which the cookie will expire, only how long it will live from the current server time when the
cookie is set.

This difference exists to simplify the interface as dealing with dates would be more troublesome (while still completely
possible).

-}
type alias Cookie =
    InternalCookie.Cookie


{-| Creates a new `Cookie`. It tries to use the most sensible defaults optimized for security. That means that:

  - `domain` is defined using the request's URL host
  - `path` is the root `/`
  - `httpOnly` is `True`
  - `secure` is defined according to the request's URL protocol
  - `signed` is `True` and
  - `sameSite` is `Strict`

All of these parameters you can later change with functions from this module.

The `maxAge` needs to be informed in milliseconds. If omitted by passing in a `Nothing` value, the cookie will be set as
a session cookie.

    cookie =
        -- expires in 30 minutes
        Express.Cookie.new "cookieName" "cookieValue" (Just 1800000)

If you need to store more complex data, make sure to encode it to a string before creating the cookie itself.

-}
new : Request.Request -> String -> String -> Maybe Int -> Cookie
new =
    InternalCookie.new


{-| Sets the `domain` property of the cookie. Defaults to the host of the request's URL.

    newCookie =
        Express.Cookie.domain "subdomain.example.com" oldCookie

-}
domain : String -> Cookie -> Cookie
domain =
    InternalCookie.domain


{-| Sets or unsets the `maxAge` property of the cookie. Passing a `Nothing` value will turn the cookie into a session
cookie.

    newCookie =
        Express.Cookie.maxAge (Just 3600000) oldCookie

-}
maxAge : Maybe Int -> Cookie -> Cookie
maxAge =
    InternalCookie.maxAge


{-| Sets the `httpOnly` property of the cookie. If `httpOnly` is `True` the cookie is only accessible through the web
server, making it impossible to fetch the cookie via JavaScript in the client side. `True` is the default value when you
create a new `Cookie`.

    newCookie =
        -- The contents of this cookie will be accessible in client side JavaScript code
        Express.Cookie.httpOnly False oldCookie

-}
httpOnly : Bool -> Cookie -> Cookie
httpOnly =
    InternalCookie.httpOnly


{-| Sets the `path` property of the cookie. Defaults to the root `/`. Changing this value will make the cookie only
available in the specified path and its subdirectories.

    newCookie =
        Express.Cookie.path "/api" oldCookie

-}
path : String -> Cookie -> Cookie
path =
    InternalCookie.path


{-| Sets the `secure` property of the cookie. If `secure` is `True` than the cookie will only be readable from secure
(https) connections. The default value depends on the protocol from the request's URL. If it is `Https`, than `secure`
will be `True`.

    newCookie =
        Express.Cookie.secure True oldCookie

-}
secure : Bool -> Cookie -> Cookie
secure =
    InternalCookie.secure


{-| Sets the `signed` property of the cookie. Signed cookies can only be read when the secrets match. You can set a
secret when creating an `elmExpress` application in the JavaScript land code. This prevents tampering of data, making
the cookie unavailable if it was not signed with the correct secret.

It is important to note that this does not encrypt the cookies value, as it will be exposed somehow. Defaults to `True`.

    newCookie =
        Express.Cookie.signed True oldCookie

-}
signed : Bool -> Cookie -> Cookie
signed =
    InternalCookie.signed


{-| Sets the `sameSite` property of the cookie. To better understand what each value means check
[this reference](https://owasp.org/www-community/SameSite) from the OWASP website. Defaults to `Strict`.

    newCookie =
        Express.Cookie.sameSite Express.Cookie.Lax oldCookie

-}
sameSite : SameSite -> Cookie -> Cookie
sameSite sameSite_ =
    let
        sameSiteString : String
        sameSiteString =
            case sameSite_ of
                None ->
                    "None"

                Strict ->
                    "Strict"

                Lax ->
                    "Lax"
    in
    InternalCookie.sameSite sameSiteString
