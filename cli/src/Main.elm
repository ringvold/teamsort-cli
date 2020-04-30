port module Main exposing (Player, playerParser)

import Array
import Cli.Option as Option
import Cli.OptionsParser as OptionsParser
import Cli.Program as Program
import Http
import Json.Decode as JD
import Json.Encode as JE
import List
import List.Extra
import Maybe.Extra as ME
import Result.Extra
import SolverResult exposing (SolverResult, solverResultDecoder)
import String.Interpolate exposing (interpolate)
import Tuple
import Url.Builder


type CliOptions
    = Sort SortOptions


type alias TrelloIntegration =
    { boardName : String
    , key : Maybe String
    , token : Maybe String
    }


type alias SortOptions =
    { fileName : String
    , trelloIntegration : Maybe TrelloIntegration
    }


programConfig : Program.Config CliOptions
programConfig =
    Program.config
        |> Program.add
            (OptionsParser.build (\file -> SortOptions file Nothing)
                |> OptionsParser.with (Option.requiredPositionalArg "file-name")
                |> OptionsParser.withDoc "run sorting algorithm based on input file"
                |> OptionsParser.map Sort
            )
        |> Program.add
            (OptionsParser.build
                (\file board key token ->
                    Just (TrelloIntegration board key token)
                        |> SortOptions file
                )
                |> OptionsParser.with (Option.requiredPositionalArg "file-name")
                |> OptionsParser.with (Option.requiredPositionalArg "trello-board-name")
                |> OptionsParser.with (Option.optionalKeywordArg "trello-key")
                |> OptionsParser.with (Option.optionalKeywordArg "trello-token")
                |> OptionsParser.withDoc "sort and send result to given trello board"
                |> OptionsParser.map Sort
            )


type Msg
    = FileReceived String
    | SolverResultReceived SolverResult
    | ErrorFromSubs String
    | TrelloListCreated (Result Http.Error ( Team, TrelloList ))
    | TrelloCardCreated (Result Http.Error String)
    | TrelloSearchReceived (Result Http.Error ( List Team, List Board ))


type alias Model =
    { players : List Player
    , outputIntegration : OutputIntegration
    , trelloConfig : Maybe TrelloConfig
    }


type OutputIntegration
    = Trello TrelloConfig String
    | Terminal


type alias TrelloConfig =
    { key : String
    , token : String
    }


type alias Flags =
    Program.FlagsIncludingArgv Extras


type alias Extras =
    { trelloKey : Maybe String
    , trelloToken : Maybe String
    }


init : Flags -> CliOptions -> ( Model, Cmd Msg )
init flags cliOptions =
    let
        initModel =
            { players = []
            , outputIntegration = Terminal
            , trelloConfig =
                Maybe.map2
                    TrelloConfig
                    flags.trelloKey
                    flags.trelloToken
            }
    in
    case cliOptions of
        Sort options ->
            case options.trelloIntegration of
                Just trello ->
                    let
                        inlineOrEnvConfig =
                            Maybe.map2 TrelloConfig trello.key trello.token
                                |> ME.orElse initModel.trelloConfig
                    in
                    case inlineOrEnvConfig of
                        Just config ->
                            ( { initModel | outputIntegration = Trello config trello.boardName }
                            , Cmd.batch
                                readFile
                                options.fileName
                            )

                        Nothing ->
                            ( initModel, printAndExitFailure "Can not find trello config. Exiting." )

                Nothing ->
                    ( initModel, readFile options.fileName )


update : CliOptions -> Msg -> Model -> ( Model, Cmd Msg )
update cliOptions msg model =
    case msg of
        FileReceived content ->
            sortCommand model content

        SolverResultReceived result ->
            let
                teams =
                    resultToTeams result model.players

                output =
                    case model.outputIntegration of
                        Terminal ->
                            teamsToString teams
                                |> printAndExitSuccess

                        Trello config boardName ->
                            Cmd.batch
                                [ teamsToString teams
                                    |> String.append
                                        ("\nSending result to Trello board \""
                                            ++ boardName
                                            ++ "\".\n\n"
                                        )
                                    |> print
                                , trelloSearch config teams
                                ]
            in
            ( model
            , output
            )

        TrelloListCreated (Ok ( team, list )) ->
            case model.outputIntegration of
                Trello config _ ->
                    ( model
                    , Cmd.batch <|
                        print ("Adding players to list " ++ list.name)
                            :: List.map
                                (addPlayerToTrelloList config list)
                                team.players
                    )

                _ ->
                    {- This should not happen, but best way I have found so
                       far to safely acces trello config
                    -}
                    ( model, Cmd.none )

        TrelloListCreated (Err error) ->
            ( model, print <| errorcheck error )

        TrelloCardCreated (Ok resultString) ->
            ( model, Cmd.none )

        TrelloCardCreated (Err error) ->
            ( model, print <| errorcheck error )

        TrelloSearchReceived (Ok ( teams, boards )) ->
            case model.outputIntegration of
                Trello config boardName ->
                    let
                        boardId =
                            boards
                                |> List.Extra.find (.name >> (==) boardName)
                                |> Maybe.map .id
                    in
                    case boardId of
                        Just id ->
                            ( model, sendToTrello config id teams )

                        Nothing ->
                            ( model, print "Could not find the spesified board" )

                _ ->
                    {- This should not happen, but best way I have found so
                       far to safely acces trello config
                    -}
                    ( model, print "Could not find the spesified board" )

        TrelloSearchReceived (Err error) ->
            ( model
            , Cmd.batch
                [ print <| errorcheck error
                , print "Board search error:"
                ]
            )

        ErrorFromSubs error ->
            ( model, printAndExitFailure error )


errorcheck : Http.Error -> String
errorcheck error =
    case error of
        Http.BadUrl url ->
            "Bad url: " ++ url

        Http.Timeout ->
            "HTTP timeout"

        Http.NetworkError ->
            "Network error"

        Http.BadStatus status ->
            "Bad status: " ++ String.fromInt status

        Http.BadBody body ->
            "Bad body: " ++ body


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
    if String.length (String.trim input) == 0 then
        Err "Empty input file"

    else
        String.lines input
            |> List.filter (not << String.isEmpty)
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
            Err "Empty input?"



{-
   Trello
-}


trelloSearch : TrelloConfig -> List Team -> Cmd Msg
trelloSearch config teams =
    let
        url =
            Url.Builder.absolute
                [ "1/members/me/boards"
                ]
                (Url.Builder.string "fields" "name,id"
                    :: keyAndToken config
                )
    in
    Http.get
        { url = "https://api.trello.com" ++ url
        , expect =
            Http.expectJson TrelloSearchReceived (JD.map (Tuple.pair teams) boardsDecoder)
        }


boardsDecoder : JD.Decoder (List Board)
boardsDecoder =
    JD.list boardDecoder


type alias Board =
    { id : String
    , name : String
    }


boardDecoder : JD.Decoder Board
boardDecoder =
    JD.map2 Board
        (JD.field "id" JD.string)
        (JD.field "name" JD.string)


addPlayerToTrelloList : TrelloConfig -> TrelloList -> Player -> Cmd Msg
addPlayerToTrelloList trelloConfig list player =
    let
        url =
            Url.Builder.absolute
                [ "1/cards"
                ]
                (Url.Builder.string "name"
                    (String.join " "
                        [ player.name
                        , player.rankName
                        , String.fromInt player.rank
                        ]
                    )
                    :: Url.Builder.string "idList" list.id
                    :: keyAndToken trelloConfig
                )
    in
    Http.post
        { url = "https://api.trello.com" ++ url
        , body = Http.emptyBody
        , expect =
            Http.expectString TrelloCardCreated
        }


sendToTrello : TrelloConfig -> String -> List Team -> Cmd Msg
sendToTrello trelloConfig boardId teams =
    print "Creating lists from teams"
        :: List.map (teamToListCreateRequest trelloConfig boardId) teams
        |> Cmd.batch


teamToListCreateRequest : TrelloConfig -> String -> Team -> Cmd Msg
teamToListCreateRequest trelloConfig boardId team =
    let
        url =
            Url.Builder.absolute
                [ "1/boards"
                , boardId
                , "lists"
                ]
                (Url.Builder.string "pos" "bottom"
                    :: Url.Builder.string "name" ("Team " ++ team.name)
                    :: keyAndToken trelloConfig
                )
    in
    Http.post
        { url = "https://api.trello.com" ++ url
        , body = Http.emptyBody
        , expect =
            Http.expectJson TrelloListCreated
                (JD.map (Tuple.pair team) trelloListDecoder)
        }


type alias TrelloList =
    { id : String
    , name : String
    , closed : Bool
    , pos : Int
    , idBoard : String
    }


trelloListDecoder : JD.Decoder TrelloList
trelloListDecoder =
    JD.map5 TrelloList
        (JD.field "id" JD.string)
        (JD.field "name" JD.string)
        (JD.field "closed" JD.bool)
        (JD.field "pos" JD.int)
        (JD.field "idBoard" JD.string)


keyAndToken : TrelloConfig -> List Url.Builder.QueryParameter
keyAndToken config =
    [ Url.Builder.string "key" config.key
    , Url.Builder.string "token" config.token
    ]



{-
   Program
-}


main : Program.StatefulProgram Model Msg CliOptions Extras
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
