module Element.Extra exposing (css)

import Element exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Html exposing (Html)
import Html.Attributes


css : String -> String -> Element.Attribute msg
css property value =
    Element.htmlAttribute
        (Html.Attributes.style
            property
            value
        )
