module State exposing (update)

import Types exposing (..)
import Date
import Toggl exposing (..)
import Date.Extra.Period exposing (add)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NewTime time ->
            let
                date =
                    Date.fromTime time
            in
                ( { model | date = date }, getTogglEntries date )

        HttpResultat resultat ->
            case resultat of
                Ok togglEntries ->
                    ( { model
                        | entries =
                            togglEntries
                                |> collapseSameThings
                                |> toEntries
                        , status = Loaded
                      }
                    , Cmd.none
                    )

                Err error ->
                    ( { model | errorMessage = toString error |> Just }, Cmd.none )

        AddDays days ->
            let
                newDate =
                    model.date
                        |> add Date.Extra.Period.Day days
            in
                ( { model | date = newDate }, getTogglEntries newDate )

        SubtractHalfHour id ->
            ( { model | entries = changeDurationForId model.entries id (-1) }, Cmd.none )

        AddHalfHour id ->
            ( { model | entries = changeDurationForId model.entries id 1 }, Cmd.none )


changeDurationForId : List Entry -> Id -> Int -> List Entry
changeDurationForId entries id change =
    entries
        |> List.map
            (\entry ->
                if entry.id == id then
                    { entry | halfHours = max (entry.halfHours + change) 0 }
                else
                    entry
            )


toEntries : List TogglEntry -> List Entry
toEntries togglEntries =
    List.indexedMap toEntry togglEntries


toEntry : Id -> TogglEntry -> Entry
toEntry id togglEntry =
    { id = id
    , togglEntry = togglEntry
    , halfHours = nearestHalfHours togglEntry.time
    }


nearestHalfHours : Int -> Int
nearestHalfHours ms =
    ms // 1800000
