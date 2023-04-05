module Express.Conn exposing (Conn, Pool)

import Dict
import Express.Request as Request
import Express.Response as Response


type alias Conn model =
    { request : Request.Request
    , response : Response.Response
    , model : model
    }


type alias Pool model =
    Dict.Dict String (Conn model)
