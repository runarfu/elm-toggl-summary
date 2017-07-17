module Main exposing (main)

import Html
import Task
import Time
import Date
import State exposing (update)
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
    { status = Types.NotLoaded
    , entries = []
    , date = Date.fromTime 0
    , errorMessage = Nothing
    }
