module Views exposing (view)

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
        h1 [] [ "Toggl Summary for " ++ dateText |> text ]


viewErrorMessage : Model -> Html Msg
viewErrorMessage model =
    case model.errorMessage of
        Just error ->
            p [ style [ ( "color", "red" ) ] ] [ "Oh no! " ++ error |> text ]

        Nothing ->
            p [] []


dayNavigation : Html Msg
dayNavigation =
    p []
        [ button [ onClick (AddDays -1) ] [ text "Previous day" ]
        , button [ onClick (AddDays 1) ] [ text "Next day" ]
        ]


mainView : Model -> Html Msg
mainView model =
    case model.status of
        NotLoaded ->
            p [] [ text "Loading…" ]

        Loaded ->
            viewLastet model.entries


viewLastet : List Entry -> Html Msg
viewLastet model =
    let
        header =
            [ "Jira", "Title", "Time tracked in Toggl", "", "Hours to bill", "", "Done billing" ]
                |> List.map (\h -> th [] [ text h ])
                |> tr []
    in
        table []
            (header
                :: List.map
                    (\e ->
                        let
                            ( jira, title ) =
                                splitTitle e.togglEntry.title

                            hasHalfHours =
                                e.halfHours > 0

                            rowColor =
                                if hasHalfHours then
                                    "lightgrey"
                                else
                                    "white"
                        in
                            tr [ style [ ( "background-color", rowColor ) ] ]
                                [ td [] [ makeLinkIfStartOfTitleLooksLikeJiraIdentifier jira ]
                                , td [] [ text title ]
                                , td [] [ text (millisecondsAsTimeStamp e.togglEntry.time) ]
                                , td [] [ minus e.id ]
                                , td []
                                    [ e.halfHours
                                        |> toFloat
                                        |> (\f -> f / 2)
                                        |> toString
                                        |> text
                                    ]
                                  --text (millisecondsAsTimeStamp (e.halfHours * 1800000)) ]
                                , td [] [ plus e.id ]
                                , td [] [ input [ type_ "checkbox" ] [] ]
                                ]
                    )
                    (List.reverse
                        (List.sortBy (.time << .togglEntry) model)
                    )
                ++ [ tr []
                        [ td [] [ b [] [ text "SUM" ] ]
                        , td [] [ text "" ]
                        , td [] [ text "" ]
                        , td [] [ text "" ]
                        , td []
                            [ b []
                                [ model
                                    |> List.map .halfHours
                                    |> List.sum
                                    |> toFloat
                                    |> (\f -> f / 2)
                                    |> toString
                                    |> text
                                ]
                            ]
                          --text (millisecondsAsTimeStamp (1800000 * List.sum (List.map .halfHours model))) ] ]
                        ]
                   ]
            )


plus : Id -> Html Msg
plus id =
    button [ onClick (AddHalfHour id) ] [ text "+" ]


minus : Id -> Html Msg
minus id =
    button [ onClick (SubtractHalfHour id) ] [ text "-" ]


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
                text title


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
