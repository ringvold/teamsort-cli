module Example exposing (..)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Main exposing (Input, generateDznFile, inputParser)
import Parser
import Test exposing (..)


suite : Test
suite =
    describe "All"
        [ test "outputs file content from input" <|
            \_ ->
                let
                    output =
                        Main.generateDznFile inputList
                in
                Expect.equal expectedOutput output
        ]


inputList =
    [ Input "Darkness sem" 6
    , Input "Samuelps s3." 3
    , Input "l0lpalme gnm." 10
    , Input "Dr.eggman/eask64 mg1." 11
    , Input "Madde gnm" 10
    , Input "Chicken lem" 16
    ]


rawInput =
    """Darkness  sem 6
Samuelps  s3. 3
l0lpalme  gnm.  10
Dr.eggman/eask64  mg1.  11
Madde gnm  10
Chicken lem 16"""


expectedOutput =
    """playerRanks = [6,3,10,11,10,16];
players = ["Darkness sem 6","Samuelps s3. 3","l0lpalme gnm. 10","Dr.eggman/eask64 mg1. 11","Madde gnm 10","Chicken lem 16"];
tonjeIndex = 15;
haraldIndex = 18;"""
