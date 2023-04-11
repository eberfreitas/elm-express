module Html.String.Extra.Document exposing (Document, new, toString)

import Html.String as Html
import Html.String.Extra as EHtml


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
        |> Html.toString 0
        |> (\doc -> "<!DOCTYPE html>\n" ++ doc)
