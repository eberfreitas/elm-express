module Html.String.Extra.Document exposing
    ( Document
    , new, toString
    )

{-| This module attempts to expose a type-safe way of describing a full HTML document.


# Type

@docs Document


# Creating a document

@docs new, toString

-}

import Html.String as Html
import Html.String.Extra as EHtml


{-| The `Document` type is an [opaque type](https://sporto.github.io/elm-patterns/advanced/opaque-types.html) that tries
to organize a way to create a full HTML document. To create a new document you need to use the `new` function.
-}
type Document msg
    = Document
        { htmlAttributes : List (Html.Attribute msg)
        , head : Html.Html msg
        , body : Html.Html msg
        }


{-| This function creates a new document. It receives a list of attributes for the root element (`<html>`), the `<head>`
HTML node and the `<body>` HTML node. After creating your `Document`, you can convert it to a string using the
`toString` function.
-}
new : List (Html.Attribute msg) -> Html.Html msg -> Html.Html msg -> Document msg
new htmlAttrs head body =
    Document { htmlAttributes = htmlAttrs, head = head, body = body }


{-| This function will properly build your HTML document according to the `Document` type by converting all your nodes
to strings. It also automatically adds the doctype to the generated string so your HTML is fully valid for browsers to
consume.
-}
toString : Document msg -> String
toString (Document { htmlAttributes, head, body }) =
    EHtml.html htmlAttributes [ head, body ]
        |> Html.toString 0
        |> (\doc -> "<!DOCTYPE html>\n" ++ doc)
