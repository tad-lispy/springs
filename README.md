# Elm Springs

A rough model of a mass attached to a spring, as described by [Hooke's law](https://en.wikipedia.org/wiki/Hooke's_law). Good for making smooth and organic looking animations or modelling oscillating values (e.g. emotions). High physical accuracy is not a priority - performance and API simplicity is more important.

![Logo](https://tad-lispy.gitlab.io/elm-springs/assets/elm-springs-logo.png)

## Demos

  - **[Sliding menu][]**  
    [source code](https://gitlab.com/tad-lispy/elm-springs/blob/master/demos/src/Examples/SlidingMenu.elm)

    Probably the most practical one at the moment :-)


  - **[Oscillometer][]**  
    [source code](https://gitlab.com/tad-lispy/elm-springs/blob/master/demos/src/Examples/Oscillator.elm)

    A little tool for experimenting with the properties (strength and damping ratio)


  - **[Squid game][]**  
    [source code](https://gitlab.com/tad-lispy/elm-springs/blob/master/demos/src/Examples/Squid.elm)

    A terrifying squid 🦑 Run!


  - **[Button][]**  
    [source code](https://gitlab.com/tad-lispy/elm-springs/blob/master/demos/src/Examples/Button.elm)

    Complete code of the program discussed in [the Use section below](#use), including the come-back behaviour.


## Install

```sh
elm install tad-lispy/springs
```


## Use

> I assume you are familiar with the Elm architecture and can setup a program using `Browser.element` or `Browser.application`. If not, best read [the official guide](https://guide.elm-lang.org/) first.

Import the `Spring` module exposing the type. Typically you would want to also import `Browser.Events` for it's `onAnimationFrameDelta` subscription. You will see below.

```elm
import Spring exposing (Spring)
import Browser.Events
```

In your model, where you would use `Float`, use `Spring` instead. In this case the spring will represent the size of a button in percent.

```elm
type alias Model =
    { size : Spring
    }

init : () -> ( Model, Cmd Msg )
init () =
    ( { size =
            Spring.create
                { strength = 100
                , dampness = 2
                }
                |> Spring.setTarget 100
      }
    , Cmd.none
    )
```

The stronger the spring, the faster it will go, but also there will be more oscillation cycles (it will wobble more). Eventually it should come to a rest. How soon it will stop depends on a damping ratio (I call it `dampness` for short). Good values for dampness are between 0 (it will oscillate forever) and 5 (it will stop pretty much as soon as it reaches the target). So these two parameters together dictate the motion characteristic of a spring. You can experiment with them here: https://tad-lispy.gitlab.io/elm-springs/Oscillator.html

Spring has a target value towards which it will move. Initially it's 0, so if you want another target, set it explicitly like in the example above.

Initial value of a spring is also 0. If you want the spring to immediately jump to a certain value, use `Spring.jumpTo : Float -> Spring -> Spring`. It's often used in `init` or if you want to abruptly terminate the animation. Often you will set the target and jump to it at the same time, like this:

```elm
Spring.create { strength = strength, dampness = dampness}
    |> Spring.setTarget 100
    |> Spring.jumpTo 100
```

You can always get the current value of a spring. Most likely you will want to do it in view function. To make a button that when clicked changes its size in a wobbly fashion, you could write a code like this:

```elm
wobblyButton : Model -> Html Msg
wobblyButton model =
    div
        [ style "width" "100px"
        , style "height" "100px"
        , model.size
            |> Spring.value
            |> (\value -> value / 100)
            |> String.fromFloat
            |> (\value -> "scale(" ++ value ++ ")")
            |> style "transform"
        , onClick Click
        ]
        []
```

> **Hint**: It's not directly related to Springs, but if you want your animations to run smoothly, try using CSS transformations (like shown above), instead of changing properties like `width`, `height`, `padding`, `margin`, etc. That way the browser won't have to recalculate layout, which is pretty tedious work and will slow your program down.

> **Hint 2**: Perhaps you have noticed that there is a funny business going on. First we set the motion of the spring be between 0 and 100 and then we divide the value by 100. Why not just set it between 0 and 1? It's because of the equilibrium detection system. With low targets and values it may consider your spring to be in equilibrium while it's still visibly vibrates, and abruptly stop the motion. You will avoid this kind of visual glitch by working with larger targets, even if it means scaling them down later.

Let's say that we want to animate the button in response to the `click` event. In the `update` function change the target to the desired final value, like this:

```elm
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Click ->
            ( { model | size = Spring.setTarget 0 model.size }
            , Cmd.none
            )

        Animate delta ->
            ( { model | size = Spring.animate delta model.size }
            , Cmd.none
            )
```

This way, whenever receiving the `Click` message, `update` will change the target of the spring to 0. This will make the button eventually disappear, but first it will shrink and wobble for some time.

But for its value to actually change over time the program needs to periodically call `Spring.animate : Float -> Spring -> Spring`. This function keeps track of the internal properties of the spring, like its momentum. All the magic is happening there. The `animate` function is taking a `Float` number (often called *delta*) representing the amount of time that passed since previous call (it's a little bit more complex than that, see the API docs for details). The *delta* is typically a number of milliseconds and the easiest way to get it is to subscribe to `animation frame` events, like this:

```elm
subscriptions : Model -> Sub Msg
subscriptions model =
    if Spring.atRest model.size then
        Sub.none

    else
        Browser.Events.onAnimationFrameDelta Animate
```

Note that when all the springs are at rest, it's best to cancel the subscription (like above). Otherwise your program will waste significant amount of CPU cycles which may drain the batteries of mobile devices (and contribute to pollution and climate change).

Note that you can use the same function to detect that the animation is finished. Let's say that we want to detect when the button is completely gone and give it a second chance:

```elm
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
```

What a splendid come back! Just as it seemed that it's gone forever, it popped back to life. Proud little button!

That's really all there is to it. For inspiration take a look at example programs built using springs.


## Some more theory

A `Spring` value is a model of a mass attached to a spring. The spring is anchored to a moving `target`. The mass is constant (1).

As the spring is animated, its centre of mass moves according to the forces acting on in and its momentum. Because the target can be moved while the mass is in motion, the spring is a good driver for animations that can smoothly transition one into another based on events that happen during the animation.

The `value` represents the current position of the mass. It is re-calculated (together with velocity) by `animate` function and can be retrieved with `value` function.

The `strength` is how strongly the spring pulls toward target. It is also called the stiffness but I find the former term more intuitive.

The `dampness` is how resistant the spring is to change in its stretch (both stretching out and contracting in). If dampness is low relative to strength, then the animation will end in long period of vibration around the target value - in other words lowering dampness will increase wobbliness. Setting dampness to 0 will result in something like a sine wave oscillator (but it's not advised to depend on its accuracy).

Target is the value toward which the mass is pulled. Typically the spring will start in an equilibrium position (i.e. value == target) and later on (due to an event) the target will be changed and the value will follow according to the strength and dampness of the spring.

Value is where the mass is. It can be extracted from the spring using `value` function and set (with `setValue` function - rarely useful).

Velocity is an internal property that cannot be directly modified or read.


## Thank you!

Thanks for your interest in this library. Feel free to open an issue or merge request. You can also reach to me on Elm Slack (`@lazurski`) with any questions. I'm usually happy to chat. If you build something with it please let me know.


[Button]: https://tad-lispy.gitlab.io/elm-springs/Button.html
[Sliding menu]: https://tad-lispy.gitlab.io/elm-springs/SlidingMenu.html
[Oscillometer]: https://tad-lispy.gitlab.io/elm-springs/Oscillator.html
[Squid game]: https://tad-lispy.gitlab.io/elm-springs/Squid.html
