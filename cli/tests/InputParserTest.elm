module InputParserTest exposing (..)

import Expect exposing (Expectation)
import Main exposing (Player, playerParser)
import Test exposing (..)


playerParser : Test
playerParser =
    describe "Parser"
        [ test "parses simple name, rank and rank int" <|
            \_ ->
                let
                    expected =
                        Ok (Player "l0lpalme" "gnm." 0 10)

                    actual =
                        Main.playerParser 0 "l0lpalme\t\tgnm.\t\t10"
                in
                Expect.equal expected actual
        , test "parses input with more complex name " <|
            \_ ->
                let
                    expected =
                        Ok (Player "Dr.eggman/eask64" "mg1." 0 11)

                    actual =
                        Main.playerParser 0 "Dr.eggman/eask64\tmg1.\t11"
                in
                Expect.equal expected actual
        , test "parses input with space in name" <|
            \_ ->
                let
                    expected =
                        Ok (Player "lil gab lolz" "mg1." 0 11)

                    actual =
                        Main.playerParser 0 "lil gab lolz\tmg1.\t11"
                in
                Expect.equal expected actual
        , test "parses input with team preference value" <|
            \_ ->
                let
                    expected =
                        Ok (Player "lil gab lolz" "mg1." 1 11)

                    actual =
                        Main.playerParser 0 "lil gab lolz\tmg1.\t1\t11"
                in
                Expect.equal expected actual
        , test "can handle empty string" <|
            \_ ->
                let
                    expected =
                        Err "Can not parse empty string"

                    actual =
                        Main.playerParser 0 ""
                in
                Expect.equal expected actual
        , test "gives error when fails to parse rank " <|
            \_ ->
                let
                    expected =
                        Err "Could not parse rank for line 1 with name lil gab lolz"

                    actual =
                        Main.playerParser 0 "lil gab lolz\tmg1.\televen"
                in
                Expect.equal expected actual
        ]
