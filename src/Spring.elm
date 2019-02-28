module Spring exposing
    ( Spring
    , animate
    , atRest
    , create
    , jumpTo
    , setTarget
    , target
    , value
    )

{-| A rough model of a mass attached to a spring, as described by [Hooke's law](https://en.wikipedia.org/wiki/Hooke's_law). Good for making smooth and organic looking animations or modelling oscillating values (e.g. emotions). High physical accuracy is not a priority - performance and API is more important.
-}


{-| A model of mass attached to a spring. The spring is anchored to a target. The mass is constant (1).

Value represents the current position of the mass. It is re-calculated (together with velocity) by animate function.

Strength regulates how strongly the spring pulls toward target. It is also called the stiffness but I find the former term more intuitive.

Dampness is how resistant the spring is to change in it's stretch (both stretching out and contracting in). If dumpness is low relative to strength, then the animation will end in long period of vibration around the target value - in other words lowering dumpness will increase wobbliness. Setting dumpness to 0 will result in something like a sine wave oscillator (but it's not advise to depend on it's accuracy).

Target is the value toward which the mass is pulled. Typically the spring will start in an equilibrium position (i.e. value == target) and later on (due to an event) the target will be changed and the value will follow according to the strength and dampness of the spring.

Value is where the mass is. It can be extracted from the spring using `value` function and set (with `setValue` function - rarely useful).

Velocity is an internal property that cannot be directly modified or read.

Let's say we are creating a program that animates the position of an element toward last click position.

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


{-| Create a spring in an equilibrium state.

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

Note that dampness is a logarythmic value - dampness of 5 translates to damping retion 25 higher than dampness of 1.

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

The current value and it's velocity will remain the same. Typically you would set a target in response to an event, e.g.:

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
setTarget target_ (Spring spring) =
    Spring
        { spring
            | target =
                target_
        }


{-| Update the spring

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

-}
animate : Float -> Spring -> Spring
animate delta ((Spring spring) as this) =
    if atRest this then
        {- If it's in equilibrium, then let's just skip the whole calculation. Be lazy. -}
        Spring spring

    else
        let
            time =
                {- Low sampling rates often result in nasty errors.

                   With this cap on delta, if the frame rate is lower than 30fps the animation will slow down and good sampling rate will be preserved.
                -}
                min delta 32 / 1000

            stretch =
                spring.target - spring.value

            force =
                stretch * spring.strength

            damping =
                spring.velocity * spring.dampness

            acceleration =
                time * (force - damping)

            velocity =
                spring.velocity + acceleration

            value_ =
                spring.value + (velocity * time)
        in
        if
            (abs (spring.value - spring.target) < 0.05)
                && (abs spring.velocity < 0.05)
        then
            {- In reality the spring never stops vibrating, but at some point the vibration is lost in the background noise (uncertainity principle). In our case it's also a wasted computation. Let's just say that it is at rest already. -} {- Snap to ideal equilibrium -}
            Spring
                { spring
                    | value = spring.target
                    , velocity = 0
                }

        else
            Spring
                { spring
                    | value =
                        value_
                    , velocity =
                        velocity
                }


{-| Measure the value of the spring.

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

Above we use Elm UI Elements and Attributes, but it's not difficult to implement same behavior using CSS transformations. Spring value is just a `Float`.

-}
value : Spring -> Float
value (Spring spring) =
    spring.value


{-| Get current target of a spring

Can be useful to see where the spring is going. Maybe you want to display something there?

-}
target : Spring -> Float
target (Spring spring) =
    spring.target


{-| Check if the spring is at rest

It indicates that no animation is running. Maybe you want to unsubscribe from animation frames? Or remove an element?

    subscriptions : Model -> Sub Msg
    subscriptions model =
        if Spring.atRest model.x && Spring.atRest model.y then
            Sub.none

        else
            Browser.Events.onAnimationFrameDelta Animate

-}
atRest : Spring -> Bool
atRest (Spring spring) =
    spring.value == spring.target && spring.velocity == 0.0


{-| Forcefully set the value and interrupt the animation.

It is useful when you set the spring for the first time (e.g. in init function) or you want to reset the animation.

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
jumpTo value_ (Spring spring) =
    Spring
        { spring
            | value = value_
            , velocity = 0.0
        }
