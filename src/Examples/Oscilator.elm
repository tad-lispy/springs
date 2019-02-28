module Examples.Oscillator exposing
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
    { oscillator : Spring
    , tape : List ( Float, Float, Bool )
    , clock : Float

    -- Knobs
    , start : Float
    , strength : Float
    , dampness : Float
    }


type alias Flags =
    ()


init : Flags -> ( Model, Cmd msg )
init flags =
    let
        start =
            200

        strength =
            8

        dampness =
            1
    in
    ( { oscillator = Spring.create strength dampness
      , tape = []
      , clock = 0.0
      , start = start
      , strength = strength
      , dampness = dampness
      }
    , Cmd.none
    )


type Msg
    = Animate Float
    | SetDampness Float
    | SetStrength Float
    | Run


view : Model -> Html Msg
view model =
    model
        |> ui
        |> Element.layout
            [ Element.width Element.fill
            , Element.height Element.fill
            ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Animate delta ->
            ( { model
                | oscillator = Spring.animate delta model.oscillator
                , clock = model.clock + delta
                , tape =
                    ( model.clock
                    , Spring.value model.oscillator
                    , Spring.atRest model.oscillator
                    )
                        :: model.tape
                        |> List.take 6000
              }
            , Cmd.none
            )

        SetDampness factor ->
            ( { model | dampness = factor }
            , Cmd.none
            )

        SetStrength strength ->
            ( { model | strength = strength }
            , Cmd.none
            )

        Run ->
            ( { model
                | oscillator =
                    model.dampness
                        |> square
                        |> Spring.create model.strength
                        |> Spring.jumpTo model.start
              }
            , Cmd.none
            )


subscriptions : Model -> Sub Msg
subscriptions model =
    if Spring.atRest model.oscillator then
        Sub.none

    else
        Browser.Events.onAnimationFrameDelta Animate


{-| Square and round a number. Used for setting and displaing dumpness.
-}
square : Float -> Float
square number =
    let
        precision =
            1000
    in
    (number ^ 2)
        |> (*) precision
        |> floor
        |> toFloat
        |> (\n -> n / precision)


ui model =
    [ graph model
    , controls model
    ]
        |> Element.column
            [ Element.width Element.fill
            , Element.height Element.fill
            , Element.padding 20
            , Element.spacing 20
            ]


graph : Model -> Element Msg
graph model =
    let
        trace ( time, value, equilibrium ) =
            Svg.circle
                [ Svg.Attributes.r "1"
                , Svg.Attributes.fill colors.trace
                , Transformations.Translate ((model.clock - time) / 10) value
                    |> Transformations.toString
                    |> Svg.Attributes.transform
                ]
                []

        head =
            Svg.circle
                [ Svg.Attributes.r "7"
                , Html.Attributes.style "filter" "blur(2px)"
                , Svg.Attributes.fill <|
                    if Spring.atRest model.oscillator then
                        colors.rest

                    else
                        colors.trace
                , model.oscillator
                    |> Spring.value
                    |> Transformations.Translate 0
                    |> Transformations.toString
                    |> Svg.Attributes.transform
                ]
                []

        marks =
            100
                |> List.range 0
                |> List.map ((*) 100)
                |> List.map toFloat
                |> List.map mark

        mark distance =
            Svg.line
                [ Transformations.Translate distance 0
                    |> Transformations.toString
                    |> Svg.Attributes.transform
                , Svg.Attributes.y1 "-400"
                , Svg.Attributes.y2 "400"
                , Svg.Attributes.x1 "0"
                , Svg.Attributes.x2 "0"
                , Svg.Attributes.stroke colors.marks
                ]
                []

        colors =
            { background = "hsl(200, 60%, 10%)"
            , rest = "hsl(200, 100%, 70%)"
            , trace = "hsl(0, 60%, 50%)"
            , marks = "hsl(200, 60%, 40%)"
            }
    in
    model.tape
        |> List.map trace
        |> (++) marks
        |> (::) head
        |> Svg.svg
            [ Svg.Attributes.viewBox "-20 -500 1000 1000"
            , Html.Attributes.style "width" "100%"
            , Html.Attributes.style "height" "100%"
            , Svg.Attributes.preserveAspectRatio "xMinYMid meet"
            , Html.Attributes.style "background" colors.background
            ]
        |> Element.html


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
                |> square
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
    , Input.button [ Element.width Element.fill ]
        { onPress = Just Run
        , label =
            "Plot"
                |> Element.text
                |> Element.el [ Element.centerX ]
                |> Element.el
                    [ Element.padding 20
                    , Element.width Element.fill
                    , Border.width 2
                    ]
        }
    ]
        |> Element.column
            [ Element.width Element.fill
            , Element.padding 20
            , Element.spacing 20
            ]
