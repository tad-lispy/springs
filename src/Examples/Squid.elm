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
            10
    in
    ( { x =
            Spring.create strength dampness
                |> Spring.setTarget 200
      , y =
            Spring.create strength dampness
                |> Spring.setTarget 200
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
    in
    model
        |> ui
        |> Element.layout
            [ Element.width Element.fill
            , Element.height Element.fill
            , Events.onClick Click
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
                    ]
                |> Element.behindContent
            ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Animate delta ->
            if Spring.atRest model.x && Spring.atRest model.y then
                if model.state == Running then
                    ( { model
                        | state = Over
                      }
                    , Cmd.none
                    )

                else
                    -- State must be Start or Over. Keep it that way.
                    ( model, Cmd.none )

            else
                ( { model
                    | x = Spring.animate delta model.x
                    , y = Spring.animate delta model.y
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


mouseDecoder : Decoder Msg
mouseDecoder =
    Decode.map2 Move
        (Decode.field "clientX" Decode.float)
        (Decode.field "clientY" Decode.float)


subscriptions : Model -> Sub Msg
subscriptions model =
    -- [ if Spring.atRest model.x && Spring.atRest model.y then
    --
    --
    --   else
    [ if model.state == Over then
        Sub.none

      else
        Browser.Events.onAnimationFrameDelta Animate
    , Browser.Events.onMouseMove mouseDecoder
    ]
        |> Sub.batch
