module Views exposing (view)

import Date
import Html exposing (..)
import Html.Events exposing (..)
import Html.Attributes exposing (..)
import String
import Strftime
import Regex
import Types exposing (..)
import Config exposing (jiraUrl)


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
            [ "JIRA", "", "Description", "Time tracked in Toggl", "", "Hours", "", "Done" ]
                |> List.map (\h -> th [] [ text h ])
                |> tr []

        viewRow index row =
            let
                ( jira, title ) =
                    splitTitle row.title

                clipboardId =
                    "copy-" ++ (toString row.rowId)

                rowClass =
                    if index % 2 == 0 then
                        ""
                    else
                        "pure-table-odd"
            in
                tr [ class rowClass ]
                    [ td [ id clipboardId ] [ makeLinkIfStartOfTitleLooksLikeJiraIdentifier jira ]
                    , td [] [ copyJiraReferenceButton clipboardId ]
                    , td [] [ text title ]
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
                    , td [] [ input [ type_ "checkbox" ] [] ]
                    ]

        footer =
            model.rows
                |> List.map .halfHours
                |> List.sum
                |> viewHalfHoursAsDecimalNumber
                |> \totalHalfHours ->
                    tr []
                        [ th [] []
                        , th [] []
                        , th [] []
                        , th [] []
                        , th [] []
                        , th [ class "total-half-hours" ] [ "Total: " ++ totalHalfHours |> text ]
                        , th [] []
                        , th [] []
                        ]
    in
        table [ class "pure-table" ]
            [ thead [] [ header ]
            , tbody []
                (model.rows
                    |> List.sortBy .totalDurationInMilliseconds
                    |> List.reverse
                    |> List.indexedMap viewRow
                )
            , tfoot [] [ footer ]
            ]


copyJiraReferenceButton : String -> Html msg
copyJiraReferenceButton clipboardId =
    div
        [ class "copy-button"
        , attribute "data-clipboard-target" ("#" ++ clipboardId)
        , title "Copy JIRA reference to clipboard"
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
    toString <| (toFloat halfHours) / 2


makeLinkIfStartOfTitleLooksLikeJiraIdentifier : String -> Html Msg
makeLinkIfStartOfTitleLooksLikeJiraIdentifier title =
    let
        pattern =
            Regex.regex "^[A-Z]{1,10}-[0-9]+"
    in
        case
            title
                |> Regex.find (Regex.AtMost 1) pattern
                |> List.map .match
                |> List.head
        of
            Just jiranumber ->
                a [ href (jiraUrl ++ jiranumber) ] [ text jiranumber ]

            Nothing ->
                span [] [ text title ]


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
                ++ if amount == 1 then
                    ""
                   else
                    "s"
    in
        txt "hour" hours ++ ", " ++ txt "minute" minutes
