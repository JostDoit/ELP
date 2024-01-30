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
  , meaningUsed : Package
  , partOfSpeachUsed : Meaning
  , definitionUsed : Definition
  , userInput : String
  , wordsList : List String
  , userFoundword : Bool
  , wordPackages : List Package
  , boxChecked : Bool
  , showPopup : Bool
  , startGame : Bool
  , score : Int
  , difficulty : String
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
  , meaningUsed = Package "" []
  , partOfSpeachUsed = Meaning "" []
  , definitionUsed = Definition "" [] []
  , userInput = ""
  , wordsList = []
  , wordPackages =  []
  , userFoundword = False
  , boxChecked = False
  , showPopup = False
  , startGame = False
  , score = 0
  , difficulty = "easy"
  }


-- UPDATE


type Msg
  = GotWordsList (Result Http.Error String)
  | GotPackages (Result Http.Error (List Package))
  | UserInput String
  | BoxChecked
  | RandomNumberForWord Int
  | RandomNumberForPackage Int
  | RandomNumberForMeaning Int
  | RandomNumberForDefinition Int
  | StartGame
  | QuitGame
  | ShowPopup
  | HidePopup
  | SetDiffEasy
  | SetDiffHard



update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of    
    GotWordsList (Ok words) ->
      let
        wordsList =
          String.split " " words
        
        randomNumber =
          Random.generate RandomNumberForWord (Random.int 0 (List.length wordsList - 1)) 
      in
        ( { model | wordsList = wordsList }, randomNumber)
    
    GotWordsList (Err _) ->
      (model, Cmd.none)

    RandomNumberForWord rnumber ->
      let
        wordToGuess =
          get rnumber (fromList model.wordsList)
      in
        case wordToGuess of
          Nothing ->
            (model, Cmd.none)

          Just word ->
            ( { model | wordToGuess = wordToGuess }, askApi word)
    
    GotPackages (Ok wordPackages)  ->
      case wordPackages of
        [] ->
          (model, Cmd.none)
        
        (x :: xs) ->
        
          let 
            randomNumber =
              Random.generate RandomNumberForPackage (Random.int 0 (List.length wordPackages - 1))
          in
            ( { model | wordPackages = wordPackages }, randomNumber)
    
    GotPackages (Err _) ->
      (model, Cmd.none)
    
    RandomNumberForPackage rnumber ->
      case model.wordPackages of
        [] ->
          (model, Cmd.none)
        
        (x :: xs) ->
          let
            meaningUsed =
              get rnumber (fromList model.wordPackages)
            
          in
            case meaningUsed of
              Nothing ->
                (model, Cmd.none)
              
              Just meaning ->
              
                ( { model | meaningUsed = meaning}, getMeaning meaning)
    
    RandomNumberForMeaning rnumber ->
      case model.meaningUsed.meanings of
        [] ->
          (model, Cmd.none)
        
        (x :: xs) ->
          let
            partOfSpeach =
              get rnumber (fromList model.meaningUsed.meanings)
          in
            case partOfSpeach of
              Nothing ->
                (model, Cmd.none)
               
              Just partOfS ->
                ( { model | partOfSpeachUsed = partOfS }, getDefinition partOfS)

    RandomNumberForDefinition rnumber ->
      case model.partOfSpeachUsed.definitions of
        [] ->
          (model, Cmd.none)
        
        (x :: xs) ->
          let
            definition =
              get rnumber (fromList model.partOfSpeachUsed.definitions)
          in
            case definition of
              Nothing ->
                (model, Cmd.none)
              
              Just def ->
                ( { model | definitionUsed = def }, Cmd.none)

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
          if model.boxChecked then
            ( { model | userInput = input, userFoundword = wordFound}, Cmd.none )
          else
            ( { model | userInput = input, userFoundword = wordFound, score = model.score + 1  }, Cmd.none )
        else
          ( { model | userInput = input, userFoundword = wordFound }, Cmd.none )
    
    BoxChecked ->
      ( { model | boxChecked = not model.boxChecked }, Cmd.none )
    
    StartGame ->
      ( { model | startGame = True, showPopup = False }, Cmd.none )
    
    QuitGame ->
      ( { model | startGame = False }, Cmd.none )
    
    ShowPopup ->
      ( { model | showPopup = True }, Cmd.none )
    
    HidePopup ->
      ( { model | showPopup = False }, Cmd.none )
    
    SetDiffEasy ->
      ( { model | difficulty = "Easy" }, Cmd.none )
    
    SetDiffHard ->
      ( { model | difficulty = "Hard" }, Cmd.none )
    
getMeaning : Package -> Cmd Msg
getMeaning package =
  let
    randomNumber =
      Random.generate RandomNumberForMeaning (Random.int 0 (List.length package.meanings - 1))
  in
    randomNumber

getDefinition : Meaning -> Cmd Msg
getDefinition meaning =
  let
    randomNumber =
      Random.generate RandomNumberForDefinition (Random.int 0 (List.length meaning.definitions - 1))
  in
    randomNumber


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
        [ case model.wordPackages of
            packages ->
              div [ class "quiz-box"]
                [ 
                  h1 [] [ text (if model.boxChecked then ("The answer was : "++ Maybe.withDefault "Error"  model.wordToGuess) else "Guess it !") ]
                  , div [class "quiz-header"]
                    [ span [class "header-score"] [ text ("Score : " ++ String.fromInt model.score) ]
                    , span [] [ text model.difficulty ]
                    ]
                  , h2 [ class "question-text"] [text "Try to find the word"]
                  ,div [ class "option-list"]
                    [ ul[] (viewPackage model packages)]
                  ,div [ class "quiz-input"]
                    [ 
                      label [] [ text (if model.userFoundword then ("Got it! It is indeed " ++ (Maybe.withDefault ""model.wordToGuess)) else "") ]
                      ,input [ value model.userInput, onInput UserInput, placeholder "Write your answer here"] []
                    ]
                  ,div [  class "quiz-footer"]
                    [ button [class "show-answer-btn", onClick BoxChecked ] [ text "Show Answer"]
                    , button [class "quit-btn", onClick QuitGame] [ text "Quit"]
                    ]
                ]
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
          , div [class "diff-choice"]
            [ h3 [] [ text "Choose your difficulty" ]
            , div [class "diff-btn-group"]
              [ button [class "diff-btn", onClick SetDiffEasy] [ text "Easy" ]
              , button [class "diff-btn", onClick SetDiffHard] [ text "Hard" ]
              ]
            ]
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
viewPackage : Model -> List Package -> List (Html Msg)
viewPackage model listPackage =
  case model.difficulty of
    "Easy" ->
      viewPackageEasy listPackage

    "Hard" ->
      viewPackageHard model.partOfSpeachUsed.partOfSpeech model.definitionUsed.definition
    _ ->
      viewPackageEasy listPackage

viewPackageHard : String -> String -> List (Html Msg)
viewPackageHard partOfSpeach definition =
  [ h2 [] [ text (partOfSpeach ++ " : " ++ definition) ]]

viewPackageEasy : List Package -> List (Html Msg)
viewPackageEasy listPackage =
  case listPackage of
    [] ->
      [text ""]

    (package :: rest) ->
      [ li [ class "meaning"] 
        [ text "Meaning"
        , ol [ class "part-of-speach"] (viewMeanings package.meanings)
        ]
      ] ++ viewPackageEasy rest

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