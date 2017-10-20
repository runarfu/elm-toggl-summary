module Types exposing (..)

import Http
import Time exposing (Time)
import Date exposing (Date)


type alias Model =
    { state : State
    , togglEntries : List TogglEntry
    , rows : List SummaryRow
    , date : Date
    , errors : Errors
    }


type alias RowId =
    Int


type Errors
    = NoErrors
    | Errors (List String)


type State
    = NotLoaded
    | Loaded


type alias SummaryRow =
    { rowId : RowId
    , title : String
    , totalDurationInMilliseconds : Int
    , halfHours : Int
    , isDone : Bool
    }


type alias TogglEntry =
    { durationInMilliseconds : Int
    , title : String
    , start : Date
    , end : Date
    }


type alias TogglCredentials =
    { workspaceId : String
    , userAgent : String
    , apiToken : String
    }


type Msg
    = NewTime Time
    | HttpResponse (Result Http.Error (List TogglEntry))
    | AddHalfHour RowId
    | SubtractHalfHour RowId
    | AddDays Int
    | ToggleIsDone RowId
