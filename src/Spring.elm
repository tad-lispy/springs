module Spring exposing
    ( Spring
    , create
    , setTarget
    , animate
    , jumpTo
    , value
    , target
    , atRest
    )

{-| This module can be used to create and track oscillating values. A value like that will change over time in a way similar to a center of mass attached to an anchored spring. See [the ReadMe](./) for an overview, demos and use cases.


# Type

@docs Spring


# Constructor

@docs create


# Control

@docs setTarget


# Update

@docs animate
@docs jumpTo


# Query

@docs value
@docs target
@docs atRest

-}


{-| Let's say we are creating a program that animates the position of an element towards the last click position.

    type alias Model =
        { x : Spring
        , y : Spring
        }

-}
type Spring
    = Spring
        { strength : Float
        , dampness : Float
        , target : Float
        , value : Float
        , velocity : Float
        }


{-| Create a spring with the value and target set to `0`.

Let's say we are creating a program that animates the position of an element toward last click position.

    type alias Model =
        { x : Spring
        , y : Spring
        }

    init : Flags -> ( Model, Cmd msg )
    init flags =
        ( { x = Spring.create { strength = 20, dampness = 4.5 }
          , y = Spring.create { strength = 20, dampness = 4.5 }
          }
        , Cmd.none
        )

Note that the `dampness` is a logarythmic value: `dampness = 5` results in damping ratio 25 times higher than `dampness = 1`.

-}
create : { strength : Float, dampness : Float } -> Spring
create { strength, dampness } =
    Spring
        { strength = strength
        , dampness = dampness ^ 2
        , target = 0
        , value = 0
        , velocity = 0
        }


{-| Set a new target (relaxed value) for the spring.

The current value and its velocity will be preserved, so the spring will smoothly transition its movement. Typically you would set a target in response to an event, e.g.:

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            Click x y ->
                ( { model
                    | x = Spring.setTarget x model.x
                    , y = Spring.setTarget y model.y
                  }
                , Cmd.none
                )

-}
setTarget : Float -> Spring -> Spring
setTarget newTarget (Spring spring) =
    Spring
        { spring
            | target =
                newTarget
        }


{-| Gently update the internal state of the spring

Typically you would do it in response to an animation frame message, like this:

    subscriptions : Model -> Sub Msg
    subscriptions model =
        Browser.Events.onAnimationFrameDelta Animate

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            Animate delta ->
                ( { model
                    | x = Spring.animate delta model.x
                    , y = Spring.animate delta model.y
                  }
                , Cmd.none
                )

> Note: that if the frame rate is low, the time passage experienced by the spring will deviate from the real time. See the comment in source code for more details.

-}
animate : Float -> Spring -> Spring
animate delta ((Spring this) as spring) =
    if atRest spring then
        {- If it's in equilibrium, then let's just skip the whole calculation. Be lazy. -}
        spring

    else
        let
            time =
                {- Low sampling rates often result in nasty errors.

                   With this cap on delta, if the frame rate is lower than 30fps the animation will slow down and good sampling rate will be preserved.
                -}
                min delta 32 / 1000

            stretch =
                this.target - this.value

            force =
                stretch * this.strength

            damping =
                this.velocity * this.dampness

            acceleration =
                time * (force - damping)

            velocity =
                this.velocity + acceleration

            newValue =
                this.value + (velocity * time)
        in
        if
            (abs (this.value - this.target) < 0.05)
                && (abs this.velocity < 0.05)
        then
            {- In reality the spring never stops vibrating, but at some point the vibration is lost in the background noise. In our case it's also a wasted computation. Let's just say that it is at rest already. -}
            jumpTo this.target spring

        else
            Spring
                { this
                    | value =
                        newValue
                    , velocity =
                        velocity
                }


{-| Measure the current value of the spring.

Typically you want to access it in the view function, like this:

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

> Above I use [Elm UI](https://package.elm-lang.org/packages/mdgriffith/elm-ui/latest/) Elements and Attributes, but it's not difficult to implement the same behaviour using CSS transformations. The value of a Spring is just a `Float` - you can do with it whatever you need.

-}
value : Spring -> Float
value (Spring this) =
    this.value


{-| Get current target of a spring

Can be useful to see where the spring is going. Maybe you want to display something there?

-}
target : Spring -> Float
target (Spring this) =
    this.target


{-| Check if the spring is at rest

It indicates that the spring has reached its target and no motion is going on. Maybe you want to unsubscribe from animation frames? Or remove an element?

    subscriptions : Model -> Sub Msg
    subscriptions model =
        if Spring.atRest model.x && Spring.atRest model.y then
            Sub.none

        else
            Browser.Events.onAnimationFrameDelta Animate

-}
atRest : Spring -> Bool
atRest (Spring this) =
    this.value == this.target && this.velocity == 0.0


{-| Forcefully set the value and interrupt the motion.

The target will be preserved, but velocity will be set to 0. It is useful when you set the spring for the first time (e.g. in the `init` function) or you want to reset the animation.

    init : Flags -> ( Model, Cmd msg )
    init flags =
        ( { x =
                Spring.create 20 20
                    |> Spring.setTarget 200
                    |> Spring.jumpTo 200
          , y =
                Spring.create 20 20
                    |> Spring.setTarget 200
                    |> Spring.jumpTo 200
          }
        , Cmd.none
        )

-}
jumpTo : Float -> Spring -> Spring
jumpTo newValue (Spring this) =
    Spring
        { this
            | value = newValue
            , velocity = 0.0
        }
