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
    div []
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
    p []
        [ button [ onClick (AddDays -1) ] [ text "Previous day" ]
        , button [ onClick (AddDays 1) ] [ text "Next day" ]
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

        viewRow row =
            let
                ( jira, title ) =
                    splitTitle row.title

                hasHalfHours =
                    row.halfHours > 0

                clipboardId =
                    "copy-" ++ (toString row.rowId)

                rowColor =
                    if hasHalfHours then
                        "lightgrey"
                    else
                        "white"
            in
                tr [ style [ ( "background-color", rowColor ) ] ]
                    [ button
                        [ class "copy-button"
                        , attribute "data-clipboard-target" ("#" ++ clipboardId)
                        , id clipboardId
                        , "Copy '"
                            ++ jira
                            ++ "' to clipboard'"
                            |> Html.Attributes.title
                        ]
                        [ text jira ]
                    , td [] [ makeLinkIfStartOfTitleLooksLikeJiraIdentifier jira ]
                    , td [] [ text title ]
                    , td [] [ text (millisecondsAsTimeStamp row.totalDurationInMilliseconds) ]
                    , td [] [ button [ onClick (SubtractHalfHour row.rowId) ] [ text "-" ] ]
                    , td [] [ text <| viewHalfHoursAsDecimalNumber row.halfHours ]
                    , td [] [ button [ onClick (AddHalfHour row.rowId) ] [ text "+" ] ]
                    , td [] [ input [ type_ "checkbox" ] [] ]
                    ]

        summary =
            model.rows
                |> List.map .halfHours
                |> List.sum
                |> viewHalfHoursAsDecimalNumber
                |> \totalHalfHours -> h3 [] [ "Total: " ++ totalHalfHours ++ " hours" |> text ]
    in
        div []
            [ table []
                (header
                    :: (model.rows
                            |> List.sortBy .totalDurationInMilliseconds
                            |> List.reverse
                            |> List.map viewRow
                       )
                )
            , summary
            ]


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
                a [ href (jiraUrl ++ jiranumber) ] [ text "🔗" ]

            Nothing ->
                span [] []


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
