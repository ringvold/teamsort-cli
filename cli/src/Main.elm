port module Main exposing (Player, playerParser)

import Array
import Cli.Option as Option
import Cli.OptionsParser as OptionsParser
import Cli.Program as Program
import Json.Decode as JD
import List
import List.Extra
import Result.Extra
import SolverResult exposing (SolverResult, solverResultDecoder)
import String.Interpolate exposing (interpolate)
import Tuple


type CliOptions
    = Generate String


programConfig : Program.Config CliOptions
programConfig =
    Program.config
        |> Program.add
            (OptionsParser.buildSubCommand "sort" Generate
                |> OptionsParser.with (Option.requiredPositionalArg "fileName")
                |> OptionsParser.withDoc "run sorting algorithm based on input file"
            )


type Msg
    = FileReceived String
    | SolverResultReceived SolverResult
    | ErrorFromSubs String


type alias Model =
    { players : List Player }


type alias Flags =
    Program.FlagsIncludingArgv {}


init : Flags -> CliOptions -> ( Model, Cmd Msg )
init flags cliOptions =
    let
        initModel =
            { players = [] }
    in
    case cliOptions of
        Generate fileName ->
            ( initModel, readFile fileName )


update : CliOptions -> Msg -> Model -> ( Model, Cmd Msg )
update cliOptions msg model =
    case msg of
        FileReceived content ->
            sortCommand model content

        SolverResultReceived result ->
            let
                teams =
                    resultToTeams result model.players
            in
            ( model
            , teamsToString teams
                |> printAndExitSuccess
            )

        ErrorFromSubs error ->
            ( model, printAndExitFailure error )


resultToTeams : SolverResult -> List Player -> List Team
resultToTeams result players =
    List.Extra.zip result.output.team players
        |> List.Extra.gatherEqualsBy Tuple.first
        |> List.sortBy (Tuple.first << Tuple.first)
        |> List.map
            (\( firstTuple, rest ) ->
                let
                    teamPlayers : List Player
                    teamPlayers =
                        List.map Tuple.second rest

                    fullTeam =
                        Tuple.second firstTuple :: teamPlayers
                in
                { name = String.fromInt <| Tuple.first firstTuple
                , players = fullTeam
                , score = fullTeam |> List.map .rank |> List.sum
                }
            )


sortCommand : Model -> String -> ( Model, Cmd Msg )
sortCommand model input =
    case parsePlayers input of
        Ok players ->
            let
                ranks =
                    List.map .rank players

                preference =
                    List.map .teamPreference players
            in
            ( { model | players = players }
            , runSolver ( ranks, preference )
            )

        Err error ->
            ( model, printAndExitFailure error )


type alias Team =
    { name : String
    , players : List Player
    , score : Int
    }


teamsToString : List Team -> String
teamsToString teams =
    teams
        |> List.map
            (\curr ->
                let
                    players : List String
                    players =
                        curr.players
                            |> List.sortBy (.rank >> negate)
                            |> List.map
                                (\p ->
                                    String.join
                                        " "
                                        [ p.name
                                        , p.rankName
                                        , String.fromInt p.rank
                                        , String.repeat p.teamPreference "*"
                                        ]
                                )
                in
                String.join ""
                    [ "# Team " ++ curr.name ++ " \n"
                    , String.join "\n" players
                    , "\n"
                    , String.append "Sum: " <| String.fromInt <| List.sum <| List.map .rank curr.players
                    , "\n"
                    ]
            )
        |> String.join "\n"


type alias Player =
    { name : String
    , rankName : String
    , teamPreference : Int
    , rank : Int
    }


parsePlayers : String -> Result String (List Player)
parsePlayers input =
    String.lines input
        |> combineMapWithIndex playerParser


playerParser : Int -> String -> Result String Player
playerParser index content =
    let
        columns =
            String.split "\t" content
                |> List.filter (not << String.isEmpty)

        lineNumber =
            index
                + 1
                |> String.fromInt
    in
    if String.isEmpty content then
        Err "Can not parse empty string"

    else
        case columns of
            [ name, rankName, rank ] ->
                Result.fromMaybe
                    ("Could not parse rank for line " ++ lineNumber ++ " with name " ++ name)
                    (Maybe.map
                        (Player name rankName 0)
                        (String.toInt rank)
                    )

            [ name, rankName, pref, rank ] ->
                Result.fromMaybe
                    "Could not parse team preferance and/or rank"
                    (Maybe.map2
                        (Player name rankName)
                        (String.toInt pref)
                        (String.toInt rank)
                    )

            name :: rankName :: pref :: rank :: lulz ->
                Err "ÅH NOES! Too many elements. Does not comprendzz"

            [ name, rank ] ->
                Maybe.map (Player name "" 0) (String.toInt rank)
                    |> Result.fromMaybe
                        ("Could not parse rank for line " ++ lineNumber ++ " with name " ++ name)

            [ rank ] ->
                Maybe.map
                    (Player
                        ("Player " ++ (String.fromInt <| index + 1))
                        ""
                        0
                    )
                    (String.toInt rank)
                    |> Result.fromMaybe
                        "Found only one element and could not parse rank int"

            [] ->
                Err "OMG! NOTHNG!"



--Result.fromMaybe
--    errorMsg
--    (Maybe.map (Player desc) rankInt)


main : Program.StatefulProgram Model Msg CliOptions {}
main =
    Program.stateful
        { printAndExitFailure = printAndExitFailure
        , printAndExitSuccess = printAndExitSuccess
        , init = init
        , config = programConfig
        , update = update
        , subscriptions = subscriptions
        }


subscriptions : a -> Sub Msg
subscriptions model =
    Sub.batch
        [ fileReceive FileReceived
        , receiveSolverResult decodeSolverResult
        ]


decodeSolverResult : JD.Value -> Msg
decodeSolverResult json =
    case JD.decodeValue solverResultDecoder json of
        Ok list ->
            SolverResultReceived list

        Err error ->
            error
                |> JD.errorToString
                |> ErrorFromSubs


port print : String -> Cmd msg


port printAndExitFailure : String -> Cmd msg


port printAndExitSuccess : String -> Cmd msg


port readFile : String -> Cmd msg


port fileReceive : (String -> msg) -> Sub msg


port writeFile : ( String, String ) -> Cmd msg


port runSolver : ( List Int, List Int ) -> Cmd msg


port receiveSolverResult : (JD.Value -> msg) -> Sub msg



-- Combining
-- Based on code from Result.Extra
-- https://github.com/elm-community/result-extra/blob/bb8c2461bf7ed9001f0fdd16e0a143bd39b6c03b/src/Result/Extra.elm#L139


{-| Combine a list of results into a single result (holding a list).
Also known as `sequence` on lists.
-}
combine : List (Result x a) -> Result x (List a)
combine =
    List.foldr (Result.map2 (::)) (Ok [])


{-| Map a function producing results on a list
and combine those into a single result (holding a list).
Also known as `traverse` on lists.
combineMap f xs == combine (List.map f xs)
-}
combineMapWithIndex : (Int -> a -> Result x b) -> List a -> Result x (List b)
combineMapWithIndex f =
    combine << List.indexedMap f
