module Html.String.Extra.Attributes exposing
    ( async
    , blocking
    , charset
    , content
    , crossorigin
    , defer
    , httpEquiv
    , imagesizes
    , imagesrcset
    , integrity
    , nomodule
    , nonce
    , referrerpolicy
    , xmlns
    )

import Html.String as Html
import Html.String.Attributes as Attributes


async : String -> Html.Attribute msg
async =
    Attributes.attribute "async"


blocking : String -> Html.Attribute msg
blocking =
    Attributes.attribute "blocking"


charset : String -> Html.Attribute msg
charset =
    Attributes.attribute "charset"


content : String -> Html.Attribute msg
content =
    Attributes.attribute "content"


crossorigin : String -> Html.Attribute msg
crossorigin =
    Attributes.attribute "crossorigin"


defer : String -> Html.Attribute msg
defer =
    Attributes.attribute "defer"


httpEquiv : String -> Html.Attribute msg
httpEquiv =
    Attributes.attribute "http-equiv"


imagesizes : String -> Html.Attribute msg
imagesizes =
    Attributes.attribute "imagesizes"


imagesrcset : String -> Html.Attribute msg
imagesrcset =
    Attributes.attribute "imagesrcset"


integrity : String -> Html.Attribute msg
integrity =
    Attributes.attribute "integrity"


nomodule : String -> Html.Attribute msg
nomodule =
    Attributes.attribute "nomodule"


nonce : String -> Html.Attribute msg
nonce =
    Attributes.attribute "nonce"


referrerpolicy : String -> Html.Attribute msg
referrerpolicy =
    Attributes.attribute "referrerpolicy"


xmlns : String -> Html.Attribute msg
xmlns =
    Attributes.attribute "xmlns"
