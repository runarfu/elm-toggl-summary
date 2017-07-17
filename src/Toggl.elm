module Toggl exposing (getTogglEntriesRequest)

import Date exposing (Date)
import Base64
import Json.Decode as Decode
import Strftime
import Http
import QueryString exposing (add)
import Types exposing (..)
import Config exposing (myTogglCredentials)


getTogglEntriesRequest : Date -> Http.Request (List TogglEntry)
getTogglEntriesRequest date =
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
    in
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


date : Decode.Decoder Date
date =
    let
        convert : String -> Decode.Decoder Date
        convert raw =
            case Date.fromString raw of
                Ok date ->
                    Decode.succeed date

                Err error ->
                    Decode.fail error
    in
        Decode.string |> Decode.andThen convert


entry : Decode.Decoder TogglEntry
entry =
    Decode.map4 TogglEntry
        (Decode.field "dur" Decode.int)
        (Decode.field "description" Decode.string)
        (Decode.field "start" date)
        (Decode.field "end" date)


entries : Decode.Decoder (List TogglEntry)
entries =
    Decode.field "data" (Decode.list entry)
