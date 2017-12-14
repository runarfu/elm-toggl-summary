module Views exposing (view)

import Config exposing (createURLFromTitle)
import Date
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Strftime
import String
import Types exposing (..)


view : Model -> Html Msg
view model =
    div [ class "main" ]
        [ header model
        , viewErrorMessage model
        , dayNavigation
        , mainView model
        ]


header : Model -> Html Msg
header model =
    let
        dateText =
            Strftime.format "%Y-%m-%d" model.date
    in
    div []
        [ h1 [] [ "Toggl Summary for " ++ dateText |> text ]
        , h2 []
            [ "Have been working for "
                ++ (durationOfEntireDay model.togglEntries |> millisecondsAsTimeStamp)
                |> text
            ]
        ]


viewErrorMessage : Model -> Html Msg
viewErrorMessage model =
    case model.errors of
        Errors errors ->
            div [ style [ ( "color", "red" ) ] ]
                [ h2 [] [ text "Errors:" ]
                , p [] [ String.join ", " errors |> text ]
                ]

        NoErrors ->
            span [] []


dayNavigation : Html Msg
dayNavigation =
    p [ class "pure-button-group", attribute "role" "group" ]
        [ button [ class "pure-button", onClick (AddDays -1) ] [ text "Previous day" ]
        , button [ class "pure-button", onClick (AddDays 1) ] [ text "Next day" ]
        ]


mainView : Model -> Html Msg
mainView model =
    case model.state of
        NotLoaded ->
            h2 [] [ text "Loading ..." ]

        Loaded ->
            viewLoaded model


viewLoaded : Model -> Html Msg
viewLoaded model =
    let
        header =
            [ "Issue", "", "Description", "Time tracked in Toggl", "", "Hours", "", "Done" ]
                |> List.map (\h -> th [] [ text h ])
                |> tr []

        allDone =
            model.rows
                |> List.filter (\r -> r.halfHours > 0)
                |> List.all .isDone

        viewRow index row =
            let
                clipboardId =
                    "copy-" ++ toString row.rowId

                rowClass =
                    if row.isDone then
                        "pure-table-odd"
                    else
                        ""

                urlOrNothing =
                    createURLFromTitle row.title
                        |> Maybe.map (\x -> a [ href x.url ] [ text x.linkText ])
                        |> Maybe.withDefault (span [] [])
            in
            tr [ class rowClass ]
                [ td [ id clipboardId ] [ urlOrNothing ]
                , td [] [ copyIssueReferenceButton clipboardId ]
                , td [] [ text row.title ]
                , td [] [ text (millisecondsAsTimeStamp row.totalDurationInMilliseconds) ]
                , td []
                    [ button
                        [ class "pure-button"
                        , onClick (SubtractHalfHour row.rowId)
                        , Html.Attributes.title "Subtract half an hour"
                        ]
                        [ text "-" ]
                    ]
                , td [ style [ ( "text-align", "right" ) ] ] [ text <| viewHalfHoursAsDecimalNumber row.halfHours ]
                , td []
                    [ button
                        [ class "pure-button"
                        , onClick (AddHalfHour row.rowId)
                        , Html.Attributes.title "Add half an hour"
                        ]
                        [ text "+" ]
                    ]
                , td []
                    [ input
                        [ onClick (ToggleIsDone row.rowId)
                        , type_ "checkbox"
                        ]
                        []
                    ]
                ]

        footer =
            model.rows
                |> List.map .halfHours
                |> List.sum
                |> viewHalfHoursAsDecimalNumber
                |> (\totalHalfHours ->
                        tr []
                            [ th [] []
                            , th [] []
                            , th [] []
                            , th [] []
                            , th [] []
                            , th [ class "total-half-hours" ] [ "Total: " ++ totalHalfHours |> text ]
                            , th [] []
                            , th []
                                [ if allDone then
                                    text "🌈"
                                  else
                                    text ""
                                ]
                            ]
                   )
    in
    div []
        [ table [ class "pure-table" ]
            [ thead [] [ header ]
            , tbody []
                (model.rows
                    |> List.sortBy .totalDurationInMilliseconds
                    |> List.reverse
                    |> List.indexedMap viewRow
                )
            , tfoot [] [ footer ]
            ]
        ]


copyIssueReferenceButton : String -> Html msg
copyIssueReferenceButton clipboardId =
    div
        [ class "copy-button"
        , attribute "data-clipboard-target" ("#" ++ clipboardId)
        , title "Copy issue to clipboard"
        ]
        [ text "📋" ]


durationOfEntireDay : List TogglEntry -> Int
durationOfEntireDay togglEntries =
    let
        startTime =
            togglEntries
                |> List.map .start
                |> List.map Date.toTime
                |> List.sort
                |> List.head
                |> Maybe.withDefault 0

        stopTime =
            togglEntries
                |> List.map .end
                |> List.map Date.toTime
                |> List.sort
                |> List.reverse
                |> List.head
                |> Maybe.withDefault 0
    in
    stopTime - startTime |> round


viewHalfHoursAsDecimalNumber : Int -> String
viewHalfHoursAsDecimalNumber halfHours =
    toString <| toFloat halfHours / 2


splitTitle : String -> ( String, String )
splitTitle title =
    case String.split " " title of
        first :: rest ->
            ( first, String.join " " rest )

        _ ->
            ( "N/A", title )


millisecondsAsTimeStamp : Int -> String
millisecondsAsTimeStamp ms =
    let
        hours =
            ms // 3600000

        restAfterHours =
            ms % 3600000

        minutes =
            restAfterHours // 60000

        restAfterMinutes =
            restAfterHours % 60000

        seconds =
            restAfterMinutes // 1000

        txt prefix amount =
            toString amount
                ++ " "
                ++ prefix
                ++ (if amount == 1 then
                        ""
                    else
                        "s"
                   )
    in
    txt "hour" hours ++ ", " ++ txt "minute" minutes
