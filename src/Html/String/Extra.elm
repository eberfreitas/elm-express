module Html.String.Extra exposing
    ( base
    , body
    , head
    , html
    , link
    , meta
    , script
    , style
    , title
    )

import Html.String as Html


nodeWithNoChildren : String -> List (Html.Attribute msg) -> Html.Html msg
nodeWithNoChildren node attrs =
    Html.node node attrs []


html : List (Html.Attribute msg) -> List (Html.Html msg) -> Html.Html msg
html =
    Html.node "html"


head : List (Html.Attribute msg) -> List (Html.Html msg) -> Html.Html msg
head =
    Html.node "head"


title : List (Html.Attribute msg) -> String -> Html.Html msg
title attrs title_ =
    Html.node "title" attrs [ Html.text title_ ]


link : List (Html.Attribute msg) -> Html.Html msg
link =
    nodeWithNoChildren "link"


meta : List (Html.Attribute msg) -> Html.Html msg
meta =
    nodeWithNoChildren "meta"


base : List (Html.Attribute msg) -> Html.Html msg
base =
    nodeWithNoChildren "base"


script : List (Html.Attribute msg) -> String -> Html.Html msg
script attrs script_ =
    Html.node "script" attrs [ Html.text script_ ]


style : List (Html.Attribute msg) -> String -> Html.Html msg
style attrs style_ =
    Html.node "style" attrs [ Html.text style_ ]


body : List (Html.Attribute msg) -> List (Html.Html msg) -> Html.Html msg
body =
    Html.node "body"
