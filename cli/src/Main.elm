port module Main exposing (Input, generateDznFile, inputParser)

import Array
import Cli.Option as Option
import Cli.OptionsParser as OptionsParser
import Cli.Program as Program
import List
import Result.Extra
import String.Interpolate exposing (interpolate)


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


type alias Model =
    ()


type alias Flags =
    Program.FlagsIncludingArgv {}


init : Flags -> CliOptions -> ( Model, Cmd Msg )
init flags cliOptions =
    case cliOptions of
        Generate fileName ->
            ( (), readFile fileName )


update : CliOptions -> Msg -> Model -> ( Model, Cmd Msg )
update cliOptions msg model =
    case msg of
        FileReceived content ->
            ( model
            , generateCommand content
            )


generateCommand : String -> Cmd Msg
generateCommand string =
    let
        printAndSave ( file, content ) =
            Cmd.batch
                [ print <| "\nCopy the following into data.dzn:\n\n" ++ content
                , writeFile ( file, content )
                ]
    in
    case parseInput string of
        Ok list ->
            generateDznFile list
                |> Tuple.pair "data.dzn"
                |> printAndSave

        Err error ->
            printAndExitFailure error


generateDznFile : List Input -> String
generateDznFile input =
    let
        ranks =
            List.map (.rank >> String.fromInt) input
                |> String.join ","

        descriptions =
            input
                |> List.map
                    (\cur ->
                        interpolate
                            "\"{0} {1}\""
                            [ cur.description, String.fromInt cur.rank ]
                    )
                |> String.join ","
    in
    interpolate """playerRanks = [{0}];
players = [{1}];
tonjeIndex = 15;
haraldIndex = 18;"""
        [ ranks, descriptions ]


type alias Input =
    { description : String
    , rank : Int
    }


parseInput : String -> Result String (List Input)
parseInput input =
    String.lines input
        |> Result.Extra.combineMap inputParser


inputParser : String -> Result String Input
inputParser line =
    let
        words =
            String.words line
                |> Array.fromList

        size =
            Array.length words

        desc =
            Array.slice 0 (size - 1) words
                |> Array.toList
                |> String.join " "

        rankInt =
            Array.get (size - 1) words
                |> Maybe.andThen String.toInt

        errorMsg =
            if String.length desc > 0 then
                "Could not parse line with description " ++ desc

            else
                "Error parsing input line"
    in
    if String.isEmpty line then
        Err "Can not parse empty string"

    else
        Result.fromMaybe
            errorMsg
            (Maybe.map (Input desc) rankInt)


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
        ]


port print : String -> Cmd msg


port printAndExitFailure : String -> Cmd msg


port printAndExitSuccess : String -> Cmd msg


port readFile : String -> Cmd msg


port writeFile : ( String, String ) -> Cmd msg


port fileReceive : (String -> msg) -> Sub msg
