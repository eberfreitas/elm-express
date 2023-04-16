module Html.String.Extra.Attributes exposing (async, blocking, charset, content, crossorigin, defer, httpEquiv, imagesizes, imagesrcset, integrity, nomodule, nonce, referrerpolicy, xmlns)

{-| Extra attributes for
[zwilias/elm-html-string](https://package.elm-lang.org/packages/zwilias/elm-html-string/latest/). The attributes here
are simple attributes build with
[`Attributes.attribute`](https://package.elm-lang.org/packages/zwilias/elm-html-string/latest/Html-String-Attributes#attribute).
That means that we can't keep the API consistency for attributes of different types, like booleans, unfortunately.

@docs async, blocking, charset, content, crossorigin, defer, httpEquiv, imagesizes, imagesrcset, integrity, nomodule, nonce, referrerpolicy, xmlns

-}

import Html.String as Html
import Html.String.Attributes as Attributes


{-| Defines the `async` attribute.
-}
async : String -> Html.Attribute msg
async =
    Attributes.attribute "async"


{-| Defines the `blocking` attribute.
-}
blocking : String -> Html.Attribute msg
blocking =
    Attributes.attribute "blocking"


{-| Defines the `charset` attribute.
-}
charset : String -> Html.Attribute msg
charset =
    Attributes.attribute "charset"


{-| Defines the `content` attribute.
-}
content : String -> Html.Attribute msg
content =
    Attributes.attribute "content"


{-| Defines the `crossorigin` attribute.
-}
crossorigin : String -> Html.Attribute msg
crossorigin =
    Attributes.attribute "crossorigin"


{-| Defines the `defer` attribute.
-}
defer : String -> Html.Attribute msg
defer =
    Attributes.attribute "defer"


{-| Defines the `http-equiv` attribute.
-}
httpEquiv : String -> Html.Attribute msg
httpEquiv =
    Attributes.attribute "http-equiv"


{-| Defines the `imagesizes` attribute.
-}
imagesizes : String -> Html.Attribute msg
imagesizes =
    Attributes.attribute "imagesizes"


{-| Defines the `imagesrcset` attribute.
-}
imagesrcset : String -> Html.Attribute msg
imagesrcset =
    Attributes.attribute "imagesrcset"


{-| Defines the `integrity` attribute.
-}
integrity : String -> Html.Attribute msg
integrity =
    Attributes.attribute "integrity"


{-| Defines the `nomodule` attribute.
-}
nomodule : String -> Html.Attribute msg
nomodule =
    Attributes.attribute "nomodule"


{-| Defines the `nonce` attribute.
-}
nonce : String -> Html.Attribute msg
nonce =
    Attributes.attribute "nonce"


{-| Defines the `referrerpolicy` attribute.
-}
referrerpolicy : String -> Html.Attribute msg
referrerpolicy =
    Attributes.attribute "referrerpolicy"


{-| Defines the `xmlns` attribute.
-}
xmlns : String -> Html.Attribute msg
xmlns =
    Attributes.attribute "xmlns"
