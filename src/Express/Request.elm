module Express.Request exposing
    ( Request, Method(..)
    , id, method, url, body, now, headers, header, cookies, cookie, session
    , decodeRequestId
    )

{-| This module exposes ways of dealing with requests. Requests are only "acquired" when a new request incomes to the
application. You should be able to access most of the original attributes of a request coming from Express.js with the
methods exposed in this method.

Everything should be "read-only" so there is no way to change a request, only read from its attributes.


# Types

@docs Request, Method


# Reading from requests

@docs id, method, url, body, now, headers, header, cookies, cookie, session


# Helpers

@docs decodeRequestId

-}

import Dict
import Express.Internal.Request as InternalRequest
import Json.Decode as D
import Time
import Url


{-| Defines the possible HTTP methods from a request.
-}
type Method
    = Get
    | Head
    | Post
    | Put
    | Delete
    | Patch


{-| The `Request` is an [opaque type](https://sporto.github.io/elm-patterns/advanced/opaque-types.html) that holds the
data from the request. It should have most of the readable attributes as described in the
[Express.js API reference](https://expressjs.com/en/4x/api.html#req).
-}
type alias Request =
    InternalRequest.Request


{-| This is a helper function that takes a `Json.Decode.Value` (most likely a JSON object from JavaScript) and extracts
the `requestId` key from such `Value`. It is very useful when defining the `decodeRequestId` function when creating your
application with `Express.application`. For an example on how this can be used, check the
[`/example`](https://github.com/eberfreitas/elm-express/tree/main/example) folder in the repository/source.
-}
decodeRequestId : D.Value -> Result D.Error String
decodeRequestId raw =
    raw |> D.decodeValue (D.field "requestId" D.string)


{-| All requests have an attached unique identifier. This function exposes such id of the request being passed. Id's are
just UUID (v4) strings and they are used to track requests inside and outside the Elm application.

    myId =
        Express.Request.id request

-}
id : Request -> String
id =
    InternalRequest.id


{-| This exposes the `Time.Posix` of the moment the request arrived, relative to the server time.

    rightNow =
        Express.Request.now request

-}
now : Request -> Time.Posix
now =
    InternalRequest.now


{-| The `url` function will return an Elm `Url` describing the current request details. For more information, please
refer to Elm's original [docs for URLs](https://package.elm-lang.org/packages/elm/url/latest/Url#Url).

Because `elm-express` does not have a dedicated router, you can use the URL data to perform routing like you would if
you were creating an SPA with Elm. Elm's guide on [Parsing URLs](https://guide.elm-lang.org/webapps/url_parsing.html)
should be a very good starting point to understand how we can leverage Elm's APIs with `elm-express` for routing.

For a more detailed example, look at the [`/example`](https://github.com/eberfreitas/elm-express/tree/main/example)
folder in the repository/source.

    url =
        Express.Request.url request

-}
url : Request -> Url.Url
url =
    InternalRequest.url


{-| Returns the request's method. Nice to use when pattern matching for specific routes. For a good example on how this
could be used, look at the [`/example`](https://github.com/eberfreitas/elm-express/tree/main/example) folder in the
repository/source.

    method =
        Express.Request.method request

-}
method : Request -> Method
method request =
    case InternalRequest.method request of
        InternalRequest.Get ->
            Get

        InternalRequest.Head ->
            Head

        InternalRequest.Post ->
            Post

        InternalRequest.Put ->
            Put

        InternalRequest.Patch ->
            Patch

        InternalRequest.Delete ->
            Delete


{-| Returns all the request's headers in a `Dict`.

    headers =
        Express.Request.headers request

-}
headers : Request -> Dict.Dict String String
headers =
    InternalRequest.headers


{-| Fetches a specific header from the request.

    isAjax =
        request
            |> Express.Request.header "X-Requested-With"
            |> Maybe.map ((==) "XMLHttpRequest")
            |> Maybe.withDefault False

-}
header : String -> Request -> Maybe String
header =
    InternalRequest.header


{-| Returns all the request's cookies in a `Dict`. Although Express.js makes a distinction between signed and unsigned
cookies, making them accessible with different attributes, _all_ cookies, signed or not, will be be available in this
`Dict`.

    cookies =
        Express.Request.cookies request

-}
cookies : Request -> Dict.Dict String String
cookies =
    InternalRequest.cookies


{-| Gets the value of a specific cookie. All cookies, signed or not, can be accessed through this function.

    lastVisit =
        Express.Request.cookie "lastVisit" request

-}
cookie : String -> Request -> Maybe String
cookie =
    InternalRequest.cookie


{-| Allows access to specific session keys. Details on how you can setup your session are in the documentation for the
JavaScript portion of this library. Please refer to the `README` for that.

    user =
        Express.Request.session "user" request

-}
session : String -> Request -> Maybe String
session =
    InternalRequest.session


{-| Gives access to the body of the request.

`elm-express` will always return the body as a `String` so it is your job to decode whatever is the content into the
desired type. If you are getting a JSON payload, you can leverage Elm's own
[`Json.Decode.decodeString`](https://package.elm-lang.org/packages/elm/json/latest/Json-Decode#decodeString) and if it
is a form payload, Elm's [`Url.Parser.Query`](https://package.elm-lang.org/packages/elm/url/latest/Url-Parser-Query)
should be up for the job.

    simpleBody =
        Express.Request.body request

-}
body : Request -> String
body =
    InternalRequest.body
