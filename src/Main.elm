module Main exposing (main)

import Date
import Html
import State exposing (update)
import Task
import Time
import Types exposing (Model, Msg)
import Views exposing (view)


main : Program Never Model Msg
main =
    Html.program
        { init = ( initModel, getCurrentTime )
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        }


getCurrentTime : Cmd Msg
getCurrentTime =
    Task.perform Types.NewTime Time.now


initModel : Model
initModel =
    { state = Types.NotLoaded
    , togglEntries = []
    , rows = []
    , date = Date.fromTime 0
    , errors = Types.NoErrors
    }
