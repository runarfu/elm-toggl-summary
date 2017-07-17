module Toggl exposing (getTogglEntries, collapseSameThings)

import Date exposing (Date)
import Base64
import Json.Decode as Decode
import Strftime
import Http
import Set
import QueryString exposing (add)
import Types exposing (..)
import Config exposing (myTogglCredentials)


getTogglEntries : Date -> Cmd Msg
getTogglEntries date =
    let
        dateString =
            Strftime.format "%Y-%m-%d" date

        query =
            QueryString.empty
                |> add "workspace_id" myTogglCredentials.workspaceId
                |> add "user_agent" myTogglCredentials.userAgent
                |> add "since" dateString
                |> add "until" dateString
                |> QueryString.render

        request =
            Http.request
                { method = "GET"
                , headers =
                    [ basicAuthHeader myTogglCredentials.apiToken "api_token" ]
                , url =
                    "https://toggl.com/reports/api/v2/details/" ++ query
                , body = Http.emptyBody
                , expect = Http.expectJson entries
                , timeout = Nothing
                , withCredentials = False
                }
    in
        Http.send Types.HttpResultat request


basicAuthHeader : String -> String -> Http.Header
basicAuthHeader username password =
    let
        base64EncodedValue =
            username
                ++ ":"
                ++ password
                |> Base64.encode
    in
        Http.header "Authorization" ("Basic " ++ base64EncodedValue)


entry : Decode.Decoder TogglEntry
entry =
    Decode.map2 TogglEntry
        (Decode.field "dur" Decode.int)
        (Decode.field "description" Decode.string)


entries : Decode.Decoder (List TogglEntry)
entries =
    Decode.field "data" (Decode.list entry)


collapseSameThings : List TogglEntry -> List TogglEntry
collapseSameThings togglEntries =
    let
        allOfTitle title =
            togglEntries
                |> List.filter ((==) title << .title)
                |> List.map .time
                |> List.sum
                |> \time -> { time = time, title = title }
    in
        togglEntries
            |> List.map .title
            |> Set.fromList
            |> Set.toList
            |> List.map allOfTitle
