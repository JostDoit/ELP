module Bouton exposing (..)

import Browser
import Html exposing (Html, div, text, input, button)
import Html.Attributes exposing (placeholder)
import Html.Events exposing (onClick, onInput)

type alias Model =
    { 
    mot_secret : String, 
    userInput : String, 
    message : String
    }

init : Model
init =
    { mot_secret = "cheval"
    , userInput = ""
    , message = ""
    }

view : Model -> Html Msg
view model =
    div []
        [ text model.mot_secret
        , div [] []
        , input [placeholder "Entrez le mot secret", onInput TextChanged] []
        , button [onClick (CheckGuess model.mot_secret)] [text "Vérifier"]
        , div [] [text model.message]
        ]

type Msg
    = CheckGuess String
    | TextChanged String

update : Msg -> Model -> Model
update msg model =
    case msg of
        TextChanged newText ->
            { model | userInput = newText }
        CheckGuess secret ->
            { model | message = if model.userInput == secret then "Bien joué!" else "Essaie encore!" }
        

main =
    Browser.sandbox
        { init = init
        , view = view
        , update = update
        }