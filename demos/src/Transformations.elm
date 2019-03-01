module Transformations exposing
    ( Transformation(..)
    , toString
    )


type Transformation
    = Identity
    | Scale Float Float
    | Translate Float Float
    | Rotate Float


toString : Transformation -> String
toString transformation =
    case transformation of
        Identity ->
            ""

        Scale x y ->
            "scale("
                ++ String.fromFloat x
                ++ ", "
                ++ String.fromFloat y
                ++ ")"

        Translate x y ->
            "translate("
                ++ String.fromFloat x
                ++ ", "
                ++ String.fromFloat y
                ++ ")"

        Rotate angle ->
            "rotate("
                ++ String.fromFloat angle
                ++ ")"
