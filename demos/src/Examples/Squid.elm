module Examples.Squid exposing
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
import Element.Events as Events
import Element.Extra as Element
import Element.Font as Font
import Element.Input as Input
import Html exposing (Html)
import Html.Events
import Json.Decode as Decode exposing (Decoder)
import Spring exposing (Spring)


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias Model =
    { x : Spring
    , y : Spring
    , hurt : Spring
    , state : GameState
    }


type GameState
    = Start
    | Running
    | Over


type alias Flags =
    ()


init : Flags -> ( Model, Cmd msg )
init flags =
    let
        strength =
            100

        dampness =
            3
    in
    ( { x =
            Spring.create
                { strength = strength
                , dampness = dampness
                }
                |> Spring.setTarget 200
      , y =
            Spring.create
                { strength = strength
                , dampness = dampness
                }
                |> Spring.setTarget 200
      , hurt =
            Spring.create
                { strength = 40
                , dampness = 1.3
                }
      , state = Start
      }
    , Cmd.none
    )


ui : Model -> Element Msg
ui model =
    Element.el
        [ Element.width (Element.px 20)
        , Element.height (Element.px 20)
        , Font.size 30
        , model.x
            |> Spring.value
            |> Element.moveRight
        , model.y
            |> Spring.value
            |> Element.moveDown
        ]
        (Element.text "\u{1F991}")


type Msg
    = Animate Float
    | Move Float Float
    | Click


view : Model -> Html Msg
view model =
    let
        message =
            case model.state of
                Start ->
                    "Don't move"

                Running ->
                    "Run!"

                Over ->
                    "The squid gotcha! Click to restart."

        clickDecoder =
            if model.state == Over then
                Decode.succeed Click

            else
                moveDecoder
    in
    model
        |> ui
        |> Element.layout
            [ Element.width Element.fill
            , Element.height Element.fill
            , Background.color (Element.rgb (Spring.value model.hurt) 0.2 0.6)
            , clickDecoder
                |> Html.Events.on "click"
                |> Element.htmlAttribute
            , Element.css "user-select" "none"
            , Element.css "-webkit-user-select" "none"
            , Element.css "-ms-user-select" "none"
            , Element.css "-webkit-touch-callout" "none"
            , Element.css "-o-user-select" "none"
            , Element.css "-moz-user-select" "none"
            , message
                |> Element.text
                |> Element.el
                    [ Element.centerX
                    , Element.centerY
                    , Font.color (Element.rgb 1 1 1)
                    , Font.size 36
                    ]
                |> Element.behindContent
            ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Animate delta ->
            case model.state of
                Start ->
                    ( { model
                        | x = Spring.animate delta model.x
                        , y = Spring.animate delta model.y
                      }
                    , Cmd.none
                    )

                Running ->
                    if Spring.atRest model.x && Spring.atRest model.y then
                        -- Spring got the player!
                        ( { model
                            | state = Over
                            , hurt = Spring.setTarget 0.6 model.hurt
                          }
                        , Cmd.none
                        )

                    else
                        ( { model
                            | x = Spring.animate delta model.x
                            , y = Spring.animate delta model.y
                          }
                        , Cmd.none
                        )

                Over ->
                    ( { model
                        | hurt = Spring.animate delta model.hurt
                      }
                    , Cmd.none
                    )

        Move x y ->
            ( { model
                | x = Spring.setTarget x model.x
                , y = Spring.setTarget (y - 20) model.y
                , state =
                    case model.state of
                        Start ->
                            Running

                        Running ->
                            Running

                        Over ->
                            Over
              }
            , Cmd.none
            )

        Click ->
            if model.state == Over then
                init ()

            else
                ( model, Cmd.none )


moveDecoder : Decoder Msg
moveDecoder =
    Decode.map2 Move
        (Decode.field "clientX" Decode.float)
        (Decode.field "clientY" Decode.float)


subscriptions : Model -> Sub Msg
subscriptions model =
    let
        calm =
            case model.state of
                Start ->
                    Spring.atRest model.x && Spring.atRest model.y

                Running ->
                    False

                Over ->
                    Spring.atRest model.hurt
    in
    [ if calm then
        Sub.none

      else
        Browser.Events.onAnimationFrameDelta Animate
    , Browser.Events.onMouseMove moveDecoder
    ]
        |> Sub.batch
