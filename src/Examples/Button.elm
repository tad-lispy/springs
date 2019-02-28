module Button exposing (main)

import Browser
import Browser.Events
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Spring exposing (Spring)


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias Model =
    { size : Spring }


type Msg
    = Animate Float
    | Click


init : () -> ( Model, Cmd Msg )
init () =
    let
        strength =
            100

        dumpness =
            5
    in
    ( { size =
            Spring.create strength dumpness
                |> Spring.setTarget 100
      }
    , Cmd.none
    )


view : Model -> Html Msg
view model =
    div
        [ style "width" "100%"
        , style "padding" "20px"
        ]
        [ div
            [ style "width" "100px"
            , style "height" "100px"
            , style "margin" "auto"
            , style "border-radius" "50%"
            , style "background" "maroon"
            , model.size
                |> Spring.value
                |> (\value -> value / 100)
                |> String.fromFloat
                |> (\value -> "scale(" ++ value ++ ")")
                |> style "transform"
            , onClick Click
            ]
            []
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Animate delta ->
            ( { model
                | size =
                    model.size
                        |> Spring.animate delta
                        |> (\spring ->
                                if
                                    (Spring.target spring == 0)
                                        && Spring.atRest spring
                                then
                                    Spring.setTarget 100 spring

                                else
                                    spring
                           )
              }
            , Cmd.none
            )

        Click ->
            ( { model | size = Spring.setTarget 0 model.size }
            , Cmd.none
            )


subscriptions : Model -> Sub Msg
subscriptions model =
    if Spring.atRest model.size then
        Sub.none

    else
        Browser.Events.onAnimationFrameDelta Animate
