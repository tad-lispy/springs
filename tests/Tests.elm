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
                    (\dampness target initial ->
                        { dampness = dampness
                        , target = target
                        , initial = initial
                        }
                    )
                    float
                    float
                    float
          in
          fuzz fuzzer
            "Spring with 0 strength won't move"
            (\{ dampness, target, initial } ->
                { strength = 0, dampness = dampness }
                    |> Spring.create
                    |> Spring.jumpTo initial
                    |> Spring.setTarget target
                    |> animate 100
                    |> Spring.value
                    |> Expect.within (Absolute 0.05) initial
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
                    |> Spring.value
                    |> Expect.within (Expect.Absolute 0) target
            )
        ]


{-| A helper function to animate the spring multiple times (as if running for many animation frames)
-}
animate : Int -> Spring -> Spring
animate frames spring =
    frames
        |> List.range 0
        |> List.foldl (\_ s -> Spring.animate 16 s) spring
