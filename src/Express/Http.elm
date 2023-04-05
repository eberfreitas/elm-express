module Express.Http exposing (Body(..), Method(..), Status(..), bodyToMIMEType, encodeBody, statusToCode, stringToMethod)

import Dict
import Json.Encode as E


type Method
    = GET
    | HEAD
    | POST
    | PUT
    | DELETE
    | PATCH


stringMap : Dict.Dict String Method
stringMap =
    let
        helper list =
            case List.head list of
                Nothing ->
                    ( "GET", GET ) :: list |> helper

                Just ( _, GET ) ->
                    ( "HEAD", HEAD ) :: list |> helper

                Just ( _, HEAD ) ->
                    ( "POST", POST ) :: list |> helper

                Just ( _, POST ) ->
                    ( "PUT", PUT ) :: list |> helper

                Just ( _, PUT ) ->
                    ( "DELETE", DELETE ) :: list |> helper

                Just ( _, DELETE ) ->
                    ( "PATCH", PATCH ) :: list |> helper

                Just ( _, PATCH ) ->
                    list
    in
    [] |> helper |> Dict.fromList


stringToMethod : String -> Maybe Method
stringToMethod method =
    Dict.get method stringMap



-- Reference: https://developer.mozilla.org/en-US/docs/Web/HTTP/Status


type Status
    = OK
    | NotFound
    | InternalServerError


statusToCode : Status -> Int
statusToCode status =
    case status of
        OK ->
            200

        NotFound ->
            404

        InternalServerError ->
            500


type Body
    = Json E.Value
    | Text String
      -- TODO: Can we create an Html type later?
    | Html String


bodyToMIMEType : Body -> String
bodyToMIMEType body =
    case body of
        Json _ ->
            "application/json"

        Text _ ->
            "text/plain"

        Html _ ->
            "text/html"


encodeBody : Body -> E.Value
encodeBody body =
    let
        mime =
            body |> bodyToMIMEType |> E.string
    in
    case body of
        Json val ->
            E.object [ ( "mime", mime ), ( "body", val ) ]

        Text text ->
            E.object [ ( "mime", mime ), ( "body", E.string text ) ]

        Html html ->
            E.object [ ( "mime", mime ), ( "body", E.string html ) ]
