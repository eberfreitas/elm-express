module Express.Conn exposing (Conn, Pool, send)

import Dict
import Express.Request as Request
import Express.Response as Response
import Json.Encode as E


type alias Conn model =
    { request : Request.Request
    , response : Response.Response
    , model : model
    }


type alias Pool model =
    Dict.Dict String (Conn model)


send : Conn model -> E.Value
send conn =
    E.object [ ( "requestId", E.string (Request.id conn.request) ), ( "response", Response.encode conn.response ) ]
