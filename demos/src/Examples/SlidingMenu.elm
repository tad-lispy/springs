module Examples.SlidingMenu exposing
    ( Model
    , Msg
    , init
    , main
    , subscriptions
    , ui
    , update
    )

import Browser
import Browser.Events
import Element exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events
import Element.Font as Font
import Element.Input as Input
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Json.Decode as Decode exposing (Decoder)
import Spring exposing (Spring)
import Svg exposing (Svg)
import Svg.Attributes
import Transformations exposing (Transformation)


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias Model =
    { menuSpring : Spring
    , menuWidth : Int

    -- Knobs
    , strength : Float
    , dampness : Float
    }


type alias Flags =
    ()


init : Flags -> ( Model, Cmd msg )
init flags =
    let
        strength =
            200

        dampness =
            4
    in
    ( { menuSpring =
            Spring.create
                { strength = strength
                , dampness = dampness
                }
      , menuWidth = 400
      , strength = strength
      , dampness = dampness
      }
    , Cmd.none
    )


type Msg
    = Animate Float
    | SetDampness Float
    | SetStrength Float
    | Toggle


view : Model -> Html Msg
view model =
    model
        |> ui
        |> Element.layout
            [ Element.width Element.fill
            , Element.height Element.fill
            , menu model
                |> Element.inFront
            ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Animate delta ->
            ( { model
                | menuSpring = Spring.animate delta model.menuSpring
              }
            , Cmd.none
            )

        SetDampness dampness ->
            ( { model
                | dampness = dampness
                , menuSpring =
                    { dampness = dampness
                    , strength = model.strength
                    }
                        |> Spring.create
                        |> Spring.setTarget (toFloat model.menuWidth)
                        |> Spring.jumpTo (toFloat model.menuWidth)
              }
            , Cmd.none
            )

        SetStrength strength ->
            ( { model
                | strength = strength
                , menuSpring =
                    { dampness = model.dampness
                    , strength = strength
                    }
                        |> Spring.create
                        |> Spring.setTarget (toFloat model.menuWidth)
                        |> Spring.jumpTo (toFloat model.menuWidth)
              }
            , Cmd.none
            )

        Toggle ->
            let
                target =
                    if Spring.target model.menuSpring == 0 then
                        toFloat model.menuWidth

                    else
                        0
            in
            ( { model
                | menuSpring = Spring.setTarget target model.menuSpring
              }
            , Cmd.none
            )


subscriptions : Model -> Sub Msg
subscriptions model =
    if Spring.atRest model.menuSpring then
        Sub.none

    else
        Browser.Events.onAnimationFrameDelta Animate


ui : a -> Element msg
ui model =
    Html.iframe
        [ Html.Attributes.style "width" "100%"
        , Html.Attributes.style "height" "100%"
        , Html.Attributes.style "border" "none"
        , Html.Attributes.sandbox ""
        , Html.Attributes.src "https://en.wikipedia.org/wiki/Hooke's_law"
        ]
        []
        |> Element.html
        |> Element.el
            [ Element.paddingEach
                { top = 0
                , right = 0
                , bottom = 0
                , left = 40
                }
            , Element.width Element.fill
            , Element.height Element.fill
            ]


menu : Model -> Element Msg
menu model =
    let
        handle =
            "↨ Menu"
                |> Element.text
                |> Element.el
                    [ Element.rotate (degrees 90)
                    , Element.centerX
                    , Element.centerY
                    ]
                |> Element.el
                    [ Element.width (Element.px handleWidth)
                    , Element.height Element.fill
                    , Events.onClick Toggle
                    , Element.pointer
                    ]

        handleWidth =
            40

        width =
            2 * model.menuWidth + handleWidth
    in
    [ Element.el [ Element.width (Element.px model.menuWidth) ] Element.none
    , [ controls model
      , explanation
      ]
        |> Element.column
            [ Element.width Element.fill
            , Element.height Element.fill
            , Element.padding 20
            ]
    , handle
    ]
        |> Element.row
            [ Element.width (Element.px width)
            , Element.height Element.fill
            , Background.color (Element.rgb 1 1 1)
            , Border.shadow
                { offset = ( -3, 0 )
                , size = 5
                , blur = 2
                , color = Element.rgb 0.4 0.4 0.4
                }
            , model.menuSpring
                |> Spring.value
                |> (\value -> (2 * toFloat model.menuWidth) - value)
                |> Element.moveLeft
            ]


explanation : Element msg
explanation =
    [ Element.text "⚠️ Note that setting values to their extreme may cause very weird (or even unpleasant) effects. Be careful with dampness - if it's low, the menu will wobble for a long time and may cause motion sickness or even epillepsy. To develop some intuition about these settings, try "
    , Element.link [ Font.underline ] { url = "Oscillator.html", label = Element.text "the oscillator example" }
    , Element.text "."
    ]
        |> Element.paragraph
            [ Font.size 18
            , Font.justify
            ]


controls : Model -> Element Msg
controls model =
    [ Input.slider
        [ Element.behindContent
            (Element.el
                [ Element.width Element.fill
                , Element.height (Element.px 2)
                , Element.centerY
                , Background.color <| Element.rgb 0.7 0.7 0.7
                , Border.rounded 2
                ]
                Element.none
            )
        ]
        { onChange = SetDampness
        , label =
            model.dampness
                |> String.fromFloat
                |> (++) "dampness = "
                |> Element.text
                |> Input.labelBelow [ Element.centerX ]
        , min = 0
        , max = 5
        , value = model.dampness
        , thumb = Input.defaultThumb
        , step = Just 0.1
        }
    , Input.slider
        [ Element.behindContent
            (Element.el
                [ Element.width Element.fill
                , Element.height (Element.px 2)
                , Element.centerY
                , Background.color <| Element.rgb 0.7 0.7 0.7
                , Border.rounded 2
                ]
                Element.none
            )
        ]
        { onChange = SetStrength
        , label =
            model.strength
                |> String.fromFloat
                |> (++) "strength = "
                |> Element.text
                |> Input.labelBelow [ Element.centerX ]
        , min = 0
        , max = 500
        , value = model.strength
        , thumb = Input.defaultThumb
        , step = Just 0.1
        }
    ]
        |> Element.column
            [ Element.width Element.fill
            , Element.spacing 20
            , Element.alignTop
            ]
