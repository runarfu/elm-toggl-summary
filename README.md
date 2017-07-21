# elm-toggl-summary
Summarize your working hours using the Toggl API and distribute half hours for billing.


# Config
You need to create a file `src/Config.elm` with your personal data for connecting
with Toggl:

```elm
module Config exposing (myTogglCredentials, jiraUrl)

import Types exposing (TogglCredentials)


myTogglCredentials : TogglCredentials
myTogglCredentials =
    { workspaceId = "..."
    , userAgent = "user@company.com"
    , apiToken = "..."
    }


jiraUrl : String
jiraUrl =
    "" -- The prefix of the Jira system you use (or leave it blank)
```

# Install
After creating `src/Config.elm`, compile the app like this:
```
$ elm make src/Main.elm --output=main.js
```
Then open `index.html` in a browser.
