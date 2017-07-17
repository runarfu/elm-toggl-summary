module Types exposing (..)

import Http
import Time exposing (Time)
import Date exposing (Date)


type alias Model =
    { status : Status
    , entries : List Entry
    , date : Date
    , errorMessage : Maybe String
    }


type Status
    = NotLoaded
    | Loaded


type alias Id =
    Int


type alias Entry =
    { id : Id
    , togglEntry : TogglEntry
    , halfHours : Int
    }


type alias TogglEntry =
    { time : Int
    , title : String
    }


type alias TogglCredentials =
    { workspaceId : String
    , userAgent : String
    , apiToken : String
    }


type Msg
    = NewTime Time
    | AddHalfHour Id
    | SubtractHalfHour Id
    | AddDays Int
    | HttpResultat (Result Http.Error (List TogglEntry))
