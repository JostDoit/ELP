module Main exposing (..)

import Browser exposing (sandbox)
import Html exposing (Html, div, text)
import Http exposing (..)
import Debug exposing (toString)

-- MODEL

type alias Model =
    { definition : String
    }

init : Model
init =
    { definition = "Loading..." }

-- UPDATE

type Msg
    = DefinitionFetched (Result Http.Error String)

update : Msg -> Model -> Model
update msg model =
    case msg of
        DefinitionFetched (Ok result) ->
            { model | definition = result }

        DefinitionFetched (Err error) ->
            let
                errorMsg = "Error fetching definition: " ++ toString error
            in
            Debug.log "Error" (Debug.todo "dummy value") -- Use Debug.todo as a placeholder
            { model | definition = errorMsg }



-- VIEW

view : Model -> Html Msg
view model =
    div []
        [ div [] [ text ("Definition: " ++ model.definition) ]
        ]

-- HTTP

apiUrl : String
apiUrl =
    "https://api.dictionaryapi.dev/api/v2/entries/en/anywhere"

fetchDefinition : Cmd Msg
fetchDefinition =
    Http.get
        { url = apiUrl
        , expect = Http.expectString DefinitionFetched
        }

-- PROGRAM

main =
    Browser.sandbox { init = init, update = update, view = view, subscriptions = subscriptions}
