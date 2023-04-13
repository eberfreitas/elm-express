module Express.Conn exposing
    ( Conn
    , send
    )

{-| This module exposes the `Conn` type, which represents the combination of three types: `Express.Request`,
`Express.Response`, and your application's model/state. The `Conn` type is used to conveniently pass the request
information through your application's functions.


# Types

@docs Conn


# Helpers

@docs send

-}

import Express.Request as Request
import Express.Response as Response
import Json.Encode as E


{-| The `Conn` type is a combination of the `Express.Request`, `Express.Response` types and your application's
model/state. It is used to efficiently pass request information through your app's functions.
-}
type alias Conn model =
    { request : Request.Request
    , response : Response.Response
    , model : model
    }


{-| The `send` function is a utility function that encodes a Conn into a JSON object that can be sent through the
`responsePort` of your application. The JavaScript part of `elm-express` expects the JSON object to have a certain
format, which can be achieved using this function. Once the `Conn` has been encoded, you can use the following pattern
to send your responses:

    conn |> Express.Conn.send |> responsePort

This will send the encoded `Conn` through the `responsePort`, allowing you to respond to the client with the
appropriate data.

-}
send : Conn model -> E.Value
send conn =
    E.object [ ( "requestId", E.string (Request.id conn.request) ), ( "response", Response.encode conn.response ) ]
