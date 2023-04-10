module Html.String.Extra.Document exposing (..)

import Html.String as Html
import Html.String.Extra as EHtml
import List exposing (head)


type Document msg
    = Document
        { htmlAttributes : List (Html.Attribute msg)
        , head : Html.Html msg
        , body : Html.Html msg
        }


new : List (Html.Attribute msg) -> Html.Html msg -> Html.Html msg -> Document msg
new htmlAttrs head body =
    Document { htmlAttributes = htmlAttrs, head = head, body = body }


toString : Document msg -> String
toString (Document { htmlAttributes, head, body }) =
    EHtml.html htmlAttributes [ head, body ]
        |> Html.toString 2
        |> (++) "<!DOCTYPE html>\n"
