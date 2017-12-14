module State exposing (update)

import Date exposing (Date)
import Date.Extra.Period exposing (add)
import Http
import Set
import Toggl exposing (..)
import Types exposing (..)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NewTime time ->
            setNewDateAndSendNewRequest model <| Date.fromTime time

        HttpResponse (Ok togglEntries) ->
            { model
                | togglEntries = togglEntries
                , rows = collapseEntriesWithSameTitle togglEntries
                , state = Loaded
            }
                ! []

        HttpResponse (Err error) ->
            { model | errors = Errors [ toString error ] } ! []

        AddHalfHour rowId ->
            { model | rows = changeDurationForId model.rows rowId 1 } ! []

        SubtractHalfHour rowId ->
            { model | rows = changeDurationForId model.rows rowId -1 } ! []

        AddDays days ->
            addDaysAndSendNewRequest model days

        ToggleIsDone rowId ->
            { model | rows = toggleIsDone model.rows rowId } ! []


setNewDateAndSendNewRequest : Model -> Date -> ( Model, Cmd Msg )
setNewDateAndSendNewRequest model date =
    ( { model | date = date, state = NotLoaded }, getTogglEntries date )


addDaysAndSendNewRequest : Model -> Int -> ( Model, Cmd Msg )
addDaysAndSendNewRequest model days =
    let
        newDate =
            model.date
                |> add Date.Extra.Period.Day days
    in
    ( { model | date = newDate, state = NotLoaded }, getTogglEntries newDate )


getTogglEntries : Date -> Cmd Msg
getTogglEntries date =
    getTogglEntriesRequest date
        |> Http.send HttpResponse


changeDurationForId : List SummaryRow -> RowId -> Int -> List SummaryRow
changeDurationForId entries rowId delta =
    entries
        |> List.map
            (\entry ->
                if entry.rowId == rowId then
                    { entry | halfHours = max (entry.halfHours + delta) 0 }
                else
                    entry
            )


toggleIsDone : List SummaryRow -> RowId -> List SummaryRow
toggleIsDone entries rowId =
    entries
        |> List.map
            (\entry ->
                if entry.rowId == rowId then
                    { entry | isDone = not entry.isDone }
                else
                    entry
            )


collapseEntriesWithSameTitle : List TogglEntry -> List SummaryRow
collapseEntriesWithSameTitle togglEntries =
    togglEntries
        |> List.map .title
        |> Set.fromList
        |> Set.toList
        |> List.indexedMap
            (\index title ->
                togglEntries
                    |> List.filter ((==) title << .title)
                    |> List.map .durationInMilliseconds
                    |> List.sum
                    |> (\totalDurationInMilliseconds ->
                            { rowId = index
                            , title = title
                            , totalDurationInMilliseconds = totalDurationInMilliseconds
                            , halfHours = roundMillisecondsToNearestHalfHours totalDurationInMilliseconds
                            , isDone = False
                            }
                       )
            )


roundMillisecondsToNearestHalfHours : Int -> Int
roundMillisecondsToNearestHalfHours ms =
    let
        halfHours =
            toFloat ms / 1800000

        upperLimit =
            ceiling halfHours

        lowerLimit =
            floor halfHours
    in
    if toFloat upperLimit - halfHours < halfHours - toFloat lowerLimit then
        upperLimit
    else
        lowerLimit
