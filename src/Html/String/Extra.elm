module Html.String.Extra exposing (html, head, title, meta, link, script, style, base, body)

{-| Extends on the [zwilias/elm-html-string](https://package.elm-lang.org/packages/zwilias/elm-html-string/latest/)
package adding extra HTML tags and attributes to fully represent an HTML document as the original package, as well as
the original [elm/html](https://package.elm-lang.org/packages/elm/html/latest/) package, does not have tags for things
like `<html>`, `<head>` and `<body>`.

@docs html, head, title, meta, link, script, style, base, body

-}

import Html.String as Html


nodeWithNoChildren : String -> List (Html.Attribute msg) -> Html.Html msg
nodeWithNoChildren node attrs =
    Html.node node attrs []


{-| Represents the root (top-level element) of an HTML document, so it is also referred to as the root element. All
other elements must be descendants of this element
([source](https://developer.mozilla.org/en-US/docs/Web/HTML/Element)).
-}
html : List (Html.Attribute msg) -> List (Html.Html msg) -> Html.Html msg
html =
    Html.node "html"


{-| Contains machine-readable information (metadata) about the document, like its title, scripts, and style sheets
([source](https://developer.mozilla.org/en-US/docs/Web/HTML/Element)).
-}
head : List (Html.Attribute msg) -> List (Html.Html msg) -> Html.Html msg
head =
    Html.node "head"


{-| Defines the document's title that is shown in a browser's title bar or a page's tab. It only contains text; tags
within the element are ignored
([source](https://developer.mozilla.org/en-US/docs/Web/HTML/Element)).
-}
title : List (Html.Attribute msg) -> String -> Html.Html msg
title attrs title_ =
    Html.node "title" attrs [ Html.text title_ ]


{-| Specifies relationships between the current document and an external resource. This element is most commonly used
to link to CSS, but is also used to establish site icons (both "favicon" style icons and icons for the home screen and
apps on mobile devices) among other things
([source](https://developer.mozilla.org/en-US/docs/Web/HTML/Element)).
-}
link : List (Html.Attribute msg) -> Html.Html msg
link =
    nodeWithNoChildren "link"


{-| Represents metadata that cannot be represented by other HTML meta-related elements, like `<base>`, `<link>`,
`<script>`, `<style>` and `<title>`
([source](https://developer.mozilla.org/en-US/docs/Web/HTML/Element)).
-}
meta : List (Html.Attribute msg) -> Html.Html msg
meta =
    nodeWithNoChildren "meta"


{-| Specifies the base URL to use for all relative URLs in a document. There can be only one such element in a document
([source](https://developer.mozilla.org/en-US/docs/Web/HTML/Element)).
-}
base : List (Html.Attribute msg) -> Html.Html msg
base =
    nodeWithNoChildren "base"


{-| Used to embed executable code or data; this is typically used to embed or refer to JavaScript code. The `<script>`
element can also be used with other languages, such as WebGL's GLSL shader programming language and JSON
([source](https://developer.mozilla.org/en-US/docs/Web/HTML/Element)).

**Note**: `elm-html-string` automatically escapes all text content, making the usage of this tag for actual scripts
almost impossible. It is best to embed scripts from other files.

-}
script : List (Html.Attribute msg) -> String -> Html.Html msg
script attrs script_ =
    Html.node "script" attrs [ Html.text script_ ]


{-| Contains style information for a document, or part of a document. It contains CSS, which is applied to the contents
of the document containing this element
([source](https://developer.mozilla.org/en-US/docs/Web/HTML/Element)).
-}
style : List (Html.Attribute msg) -> String -> Html.Html msg
style attrs style_ =
    Html.node "style" attrs [ Html.text style_ ]


{-| Represents the content of an HTML document. There can be only one such element in a document.
([source](https://developer.mozilla.org/en-US/docs/Web/HTML/Element)).
-}
body : List (Html.Attribute msg) -> List (Html.Html msg) -> Html.Html msg
body =
    Html.node "body"
