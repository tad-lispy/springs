module Tests exposing (suite)

import Expect exposing (Expectation, FloatingPointTolerance(..))
import Fuzz exposing (Fuzzer, float, int, list, string)
import Spring exposing (Spring)
import Test exposing (..)


suite : Test
suite =
    describe "Springs"
        [ let
            fuzzer =
                Fuzz.map3
                    (\dampness target displacement ->
                        { dampness = dampness
                        , target = target
                        , initial = target + displacement
                        }
                    )
                    float
                    float
                    (Fuzz.oneOf
                        [ Fuzz.floatRange -10000 -0.1
                        , Fuzz.floatRange 0.1 10000
                        ]
                    )
          in
          fuzz fuzzer
            "Spring with 0 strength won't move"
            (\{ dampness, target, initial } ->
                { strength = 0, dampness = dampness }
                    |> Spring.create
                    |> Spring.jumpTo initial
                    |> Spring.setTarget target
                    |> animate 100
                    |> Expect.all
                        [ Spring.value >> Expect.within (Absolute 0) initial
                        , Spring.atRest >> Expect.false "Spring is at rest."
                        ]
            )
        , let
            fuzzer =
                Fuzz.map3
                    (\strength dampness target ->
                        { strength = strength
                        , dampness = dampness
                        , target = target
                        }
                    )
                    float
                    float
                    float
          in
          fuzz fuzzer
            "Spring at rest won't move"
            (\{ strength, dampness, target } ->
                { strength = strength, dampness = dampness }
                    |> Spring.create
                    |> Spring.jumpTo target
                    |> Spring.setTarget target
                    |> animate 100
                    |> Expect.all
                        [ Spring.value >> Expect.within (Absolute 0) target
                        , Spring.atRest >> Expect.true "Spring is not at rest."
                        ]
            )
        , let
            fuzzer =
                Fuzz.map4
                    (\strength dampness target start ->
                        { strength = strength
                        , dampness = dampness
                        , target = target
                        , start = start
                        }
                    )
                    (Fuzz.floatRange 1 500)
                    (Fuzz.floatRange 0.5 5)
                    (Fuzz.floatRange -500 500)
                    (Fuzz.floatRange -500 500)
          in
          fuzz fuzzer
            "A spring with positive strength and dampness will eventually reach it's target"
            (\{ strength, dampness, target, start } ->
                { strength = strength, dampness = dampness }
                    |> Spring.create
                    |> Spring.jumpTo start
                    |> Spring.setTarget target
                    |> animate 100000
                    |> Expect.all
                        [ Spring.value >> Expect.within (Absolute 0) target
                        , Spring.atRest >> Expect.true "Spring is not at rest."
                        ]
            )
        ]


{-| A helper function to animate the spring multiple times (as if running for many animation frames)
-}
animate : Int -> Spring -> Spring
animate frames spring =
    frames
        |> List.range 0
        |> List.foldl (\_ snapshot -> Spring.animate 16 snapshot) spring
