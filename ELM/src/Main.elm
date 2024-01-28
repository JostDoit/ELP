module Main exposing (..)

import Browser
import Html exposing (..)
import Html.Attributes exposing (placeholder, value, type_, checked, class, href)
import Html.Events exposing (..)
import Http
import Random
import Array exposing (Array, get, fromList)
import Json.Decode exposing (Decoder, map2, map3, field, int, string, list, at)
import Html.Attributes exposing (start)



-- MAIN

main : Program () Model Msg
main =
  Browser.element
    { init = init
    , update = update
    , subscriptions = subscriptions
    , view = view
    }



-- MODEL


type alias Model = 
  { wordToGuess : Maybe String
  , userInput : String
  , wordsList : List String
  , userFoundword : Bool
  , result : Result Http.Error (List Package)
  , boxChecked : Bool
  , showPopup : Bool
  , startGame : Bool
  , score : Int
  }


type alias Package =
  { word : String
  , meanings : List Meaning
  }

type alias Meaning =
  { partOfSpeech : String
  , definitions : List Definition
  }

type alias Definition =
  { definition : String
  , synonyms : List String
  , antonyms : List String
  }


init : () -> (Model, Cmd Msg)
init _ =
  (initModel, getWordsList)

initModel : Model
initModel =
  { wordToGuess = Nothing
  , userInput = ""
  , wordsList = []
  , result = Ok []
  , userFoundword = False
  , boxChecked = False
  , showPopup = False
  , startGame = False
  , score = 0
  }


-- UPDATE


type Msg
  = GotWordsList (Result Http.Error String)
  | GotPackages (Result Http.Error (List Package))
  | UserInput String
  | BoxChecked
  | RandomNumber Int
  | StartGame
  | ShowPopup
  | HidePopup



update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of    
    GotWordsList (Ok words) ->
      let
        wordsList =
          String.split " " words
        
        randomNumber =
          Random.generate RandomNumber (Random.int 0 (List.length wordsList - 1))
      in
        ( { model | wordsList = wordsList }, randomNumber)
    
    GotWordsList (Err _) ->
      (model, Cmd.none)

    RandomNumber rnumber ->
      let
        wordToGuess =
          get rnumber (fromList model.wordsList)
      in
        case wordToGuess of
          Nothing ->
            (model, Cmd.none)

          Just word ->
            ( { model | wordToGuess = wordToGuess }, askApi word)

    GotPackages result ->
      ( { model | result = result }, Cmd.none )

    UserInput input ->
      let
        wordFound =
          case model.wordToGuess of
            Just correctWword ->
              input == correctWword
            
            Nothing ->
              False
      in
        if wordFound then
          ( { model | userInput = input, userFoundword = wordFound, score = model.score + 1 }, Cmd.none )
        else
          ( { model | userInput = input, userFoundword = wordFound }, Cmd.none )
    
    BoxChecked ->
      ( { model | boxChecked = not model.boxChecked }, Cmd.none )
    
    StartGame ->
      ( { model | startGame = True, showPopup = False }, Cmd.none )
    
    ShowPopup ->
      ( { model | showPopup = True }, Cmd.none )
    
    HidePopup ->
      ( { model | showPopup = False }, Cmd.none )
        


-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none


-- VIEW


view : Model -> Html Msg
view model =
  div [] 
  [ main_ [class (getMainClass model)]
    [ header [class "header"]
      [ a [ href "#", class "logo" ] [ text "ELM." ]
      , nav [ class "navbar"]
        [ a [ href "#", class "active" ] [ text "Home" ]
        , a [ href "#"] [ text "About" ]
        , a [ href "#"] [ text "Contact" ]
        ]
      ]
    , div [class "container"]
      [ section [class (getquizSectionClass model)]
        [ case model.result of
            Ok packages ->
              div [ class "quiz-box"]
                [ 
                  h1 [] [ text (if model.boxChecked then ("The answer was : "++ Maybe.withDefault "Error"  model.wordToGuess) else "Guess it !") ]
                  , div [class "quiz-header"]
                    [ span [class "header-score"] [ text ("Score : " ++ String.fromInt model.score) ]
                    , span [] [ text "Difficulté" ]
                    ]
                  , h2 [ class "question-text"] [text "Try to find the word"]
                  ,div [ class "option-list"]
                    [
                      ul[] (viewPackage packages)
                    ]
                  ,div [ class "quiz-input"]
                    [ 
                      label [] [ text (if model.userFoundword then ("Got it! It is indeed " ++ (Maybe.withDefault ""model.wordToGuess)) else "") ]
                      ,input [ value model.userInput, onInput UserInput, placeholder "Write your answer here"] []
                    ]
                  ,div [  class "quiz-footer"]
                    [ button [class "show-answer-btn", onClick BoxChecked ] [ text "Show Answer"]
                    , button [class "quit-btn"] [ text "Quit"]
                    ]
                ]
            Err _ ->
              text "Communication error with the API"
        ]
        
      , section [class "home"]
          [ div [class "home-content"]
            [ h1 [] [text "Guess it !"]
            , p [] [text "A game where you have to guess the word from its definition"]
            , button [onClick ShowPopup, class "start-btn"] [ text "Start Game" ]
            ]
          ]
      ]
    ]
  , case model.showPopup of
      False ->
        text ""
      True ->
        div [ class "popup-info"]
          [ h2 [] [ text "Rules" ]
          , span [class "info"] [ text "You have to guess the word from its definition" ]
          , span [class "info"] [ text "You can check the word if you are stuck" ]
          , span [class "info"] [ text "More options to come !" ]
          , div [class "btn-group"]
            [ button [onClick HidePopup, class "info-btn exit-btn"] [ text "Exit" ]
            , button [onClick StartGame, class "info-btn continue-btn"] [ text "Continue" ]
            ]
          ]
  ]
getMainClass : Model -> String
getMainClass model =
  case model.showPopup of
    False ->
      "main"
    True ->
      "main active"
getquizSectionClass : Model -> String
getquizSectionClass model =
  case model.startGame of
    False ->
      "quiz-section"
    True ->
      "quiz-section active"
viewPackage : List Package -> List (Html Msg)
viewPackage listPackage =
  case listPackage of
    [] ->
      [text ""]

    (package :: rest) ->
      [ li [ class "meaning"] 
        [ text "Meaning"
        , ol [ class "part-of-speach"] (viewMeanings package.meanings)
        ]
      ] ++ viewPackage rest

viewMeanings : List Meaning -> List (Html Msg)
viewMeanings meanings =
  case meanings of
    [] ->
      [text ""]

    (meaning :: rest) ->      
      
      [ li [] 
        [ text meaning.partOfSpeech
        , ol [ class "definition"] (viewDefinitions meaning.definitions)      
        ]
      ] ++ viewMeanings rest
      
        

viewDefinitions : List Definition -> List (Html Msg)
viewDefinitions definitions =
  List.map (\definition -> li[] [text definition.definition]) definitions

-- HTTP

getWordsList : Cmd Msg
getWordsList =
  Http.get
    { url = "mots.txt"
    , expect = Http.expectString GotWordsList
    }

getWordDefinition : Cmd Msg
getWordDefinition =
  Http.get
    { url = "https://api.dictionaryapi.dev/api/v2/entries/en/with"
    , expect = Http.expectJson GotPackages mainDecoder
    }

askApi : String -> Cmd Msg
askApi word =
  Http.get
    { url = "https://api.dictionaryapi.dev/api/v2/entries/en/" ++ word
    , expect = Http.expectJson GotPackages mainDecoder
    }

mainDecoder : Decoder (List Package)
mainDecoder = 
  list packageDecoder

packageDecoder : Decoder Package
packageDecoder =
  map2 Package
    (field "word" string)
    (field "meanings" (list meaningDecoder))

meaningDecoder : Decoder Meaning
meaningDecoder =
  map2 Meaning
    (field "partOfSpeech" string)
    (field "definitions" (list definitionDecoder))

definitionDecoder : Decoder Definition
definitionDecoder =
    map3 Definition
    (field "definition" string)
    (field "synonyms" (list string))
    (field "antonyms" (list string))