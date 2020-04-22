module SolverResult exposing (..)

import Json.Decode exposing (..)


type alias SolverResult =
    { stauts : Status
    , output : Output
    , complete : Bool
    }


solverResultDecoder : Decoder SolverResult
solverResultDecoder =
    map3
        SolverResult
        (field "status" (string |> andThen (succeed << solverStatusFromString)))
        (field "output" solverOutputDecoder)
        (field "complete" bool)


type alias Output =
    { team : List Int
    , score : List Int
    , teamSize : List Int
    }


solverOutputDecoder : Decoder Output
solverOutputDecoder =
    map3 Output
        (field "team" (list int))
        (field "score" (list int))
        (field "teamSize" (list int))


type Status
    = Error
    | Unknown
    | Unbounded
    | Unsatisfiable
    | Satisfied
    | AllSolutions
    | OptimalSolution


solverStatusFromString : String -> Status
solverStatusFromString string =
    case string of
        "UNSATISFIABLE" ->
            Unsatisfiable

        "ERROR" ->
            Error

        "UNKNOWN" ->
            Unknown

        "UNBOUNDED" ->
            Unbounded

        "SATISFIED" ->
            Satisfied

        "ALL_SOLUTIONS" ->
            AllSolutions

        "OPTIMAL_SOLUTION" ->
            OptimalSolution

        _ ->
            Error
