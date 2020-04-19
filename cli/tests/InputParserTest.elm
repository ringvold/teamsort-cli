module InputParserTest exposing (..)

import Expect exposing (Expectation)
import Main exposing (Input, generateDznFile, inputParser)
import Test exposing (..)


inputParser : Test
inputParser =
    describe "Parser"
        [ test "parses simple name rank and rank int" <|
            \_ ->
                let
                    expected =
                        Ok (Input "l0lpalme gnm." 10)

                    actual =
                        Main.inputParser "l0lpalme gnm.  10"
                in
                Expect.equal expected actual
        , test "parses input with more complex name " <|
            \_ ->
                let
                    expected =
                        Ok (Input "Dr.eggman/eask64 mg1." 11)

                    actual =
                        Main.inputParser "Dr.eggman/eask64  mg1.  11"
                in
                Expect.equal expected actual
        , test "parses input with space in name" <|
            \_ ->
                let
                    expected =
                        Ok (Input "lil gab lolz mg1." 11)

                    actual =
                        Main.inputParser "lil gab lolz  mg1.  11"
                in
                Expect.equal expected actual
        , test "can handle empty string" <|
            \_ ->
                let
                    expected =
                        Err "Can not parse empty string"

                    actual =
                        Main.inputParser ""
                in
                Expect.equal expected actual
        , test "gives error when fails to parse rank " <|
            \_ ->
                let
                    expected =
                        Err "Could not parse line with description lil gab lolz mg1."

                    actual =
                        Main.inputParser "lil gab lolz  mg1.  eleven"
                in
                Expect.equal expected actual
        ]
