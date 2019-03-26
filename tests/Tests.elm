module Tests exposing (suite)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, float, int, list, string)
import Spring exposing (Spring)
import Test exposing (..)


suite : Test
suite =
    describe "Springs"
        [ fuzz float
            "Spring with 0 strength won't move"
            (\dampness ->
                { strength = 0, dampness = dampness }
                    |> Spring.create
                    |> Spring.jumpTo 100
                    |> Spring.animate 16
                    |> Spring.value
                    |> Expect.equal 100
            )
        , fuzz float
            "Spring at rest won't move"
            (\strength ->
                { strength = strength, dampness = 0 }
                    |> Spring.create
                    |> Spring.animate 16
                    |> Spring.value
                    |> Expect.equal 0
            )
        ]
