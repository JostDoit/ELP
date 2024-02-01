module Main exposing (..)

import Browser
import Html exposing (..)
import Html.Attributes exposing (placeholder, value, type_, checked, class, href)
import Html.Events exposing (..)
import Http
import Random
import Array exposing (Array, get, fromList)
import Html.Attributes exposing (start)
import JsonDecoder


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
  { wordToGuess : Maybe String      -- The word to guess
  , meaningUsed : JsonDecoder.Meaning           -- Random meaning used in hard mode
  , partOfSpeachUsed : JsonDecoder.PartOfSpeach -- Random partofspeach used in hard mode
  , definitionUsed : JsonDecoder.Definition     -- Random definition used in hard mode
  , userInput : String              -- Current user input
  , wordsList : List String         -- List of all the words loaded from the txt file
  , userFoundword : Bool            -- Indicates if the user found the word
  , wordMeanings : List JsonDecoder.Meaning     -- List of all the meanings loaded from the API
  , showAnswerBoxChecked : Bool     -- Indicates if the user checked the showAnswer box
  , showPopup : Bool                -- Used to display the popup on screen
  , startGame : Bool                -- Indicates if the game has started
  , score : Int                     -- User score
  , difficulty : String             -- Difficulty of the game
  }

init : () -> (Model, Cmd Msg)
init _ =
  (initModel, getWordsList)

initModel : Model
initModel =
  { wordToGuess = Nothing
  , meaningUsed = JsonDecoder.Meaning "" []
  , partOfSpeachUsed = JsonDecoder.PartOfSpeach "" []
  , definitionUsed = JsonDecoder.Definition "" [] []
  , userInput = ""
  , wordsList = []
  , wordMeanings =  []
  , userFoundword = False
  , showAnswerBoxChecked = False
  , showPopup = False
  , startGame = False
  , score = 0
  , difficulty = "Easy"
  }


-- UPDATE


type Msg
  = GotWordsList (Result Http.Error String)
  | RandomNumberForWord Int
  | GotMeanings (Result Http.Error (List JsonDecoder.Meaning))
  | UserInput String
  | ShowAnswerBoxChecked  
  | RandomNumberForMeaning Int
  | RandomNumberForPartOfSpeach Int
  | RandomNumberForDefinition Int
  | StartGame
  | QuitGame
  | ShowPopup
  | HidePopup
  | SetDiffEasy
  | SetDiffHard
  | NewGame



update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of

    -- If we successfully got the words list, we split it and generate a random number to get a word from the list
    GotWordsList (Ok words) ->
      let
        wordsList =
          String.split " " words
      in
        ( { model | wordsList = wordsList }, getWord model)
    
    -- If we failed to get the words list, we do nothing
    GotWordsList (Err _) ->
      (model, Cmd.none)

    -- Use the random number generated in GotWordsList to select a random word to guess from the list
    RandomNumberForWord rnumber ->
      let
      -- Select a random word from the list
        wordToGuess =
          get rnumber (fromList model.wordsList)
      in
        case wordToGuess of
          -- If we failed to get a word, we do nothing
          Nothing ->
            (model, Cmd.none)

          -- If we successfully got a word, we ask the API for its meanings
          Just word ->
            ( { model | wordToGuess = wordToGuess }, askApi word)
    
    -- If we successfully got the meanings from the API, we update the model with these meanings
    GotMeanings (Ok wordMeanings)  ->
      ({ model | wordMeanings = wordMeanings }, Cmd.none)      
    
    -- If we failed to get the meanings from the API, we do nothing
    GotMeanings (Err _) ->
      (model, Cmd.none)

    -- Use to display the popup on screen
    ShowPopup ->
      ( { model | showPopup = True }, Cmd.none )
    
    -- Use to hide the popup from screen
    HidePopup ->
      ( { model | showPopup = False }, Cmd.none )
    
    -- Set the difficulty to easy, all the meanings, their partofspeach and definitions will be displayed
    SetDiffEasy ->
      ( { model | difficulty = "Easy" }, Cmd.none )

    -- Set the difficulty to hard, only a random definition of a random partofspeach of a random meaning of the word will be displayed
    SetDiffHard ->
      case model.wordMeanings of
          [] ->
            (model, Cmd.none)
          
          -- If we have one or more meanings, we generate a random number to get a random meaning from the list
          (x :: xs) ->          
            let 
              randomNumber =
                Random.generate RandomNumberForMeaning (Random.int 0 (List.length model.wordMeanings - 1))
            in
              ( { model | difficulty = "Hard" }, randomNumber)
    
    -- Uses the random number generated in SetDiffHard to get a random meaning from the meaning list, then uses this meaning to get a random partofspeach from its partofspeach list
    RandomNumberForMeaning rnumber ->      
      let
      -- Select a random meaning from the list
        meaningUsed =
          get rnumber (fromList model.wordMeanings)          
      in
        case meaningUsed of
          -- If we failed to get a meaning, we do nothing
          Nothing ->
            (model, Cmd.none)
            
          -- If we successfully got a meaning, we call the function getPartOfSpeach to get a random partofspeach from the selected meaning
          Just meaning ->            
            ( { model | meaningUsed = meaning}, getPartOfSpeach meaning)
    
    -- Uses the random number generated in RandomNumberForMeaning to get a random partofspeach from the partofspeach list of the selected meaning
    RandomNumberForPartOfSpeach rnumber ->      
      let
        selectedPartOfSpeach =
          get rnumber (fromList model.meaningUsed.meanings)
      in
        case selectedPartOfSpeach of
          Nothing ->
            (model, Cmd.none)
          
          -- If we successfully got a partofspeach, we call the function getDefinition to get a random definition from the selected partofspeach
          Just partOfSpeach ->
            ( { model | partOfSpeachUsed = partOfSpeach }, getDefinition partOfSpeach)
    
    RandomNumberForDefinition rnumber ->
      let
        selectedDefinition =
          get rnumber (fromList model.partOfSpeachUsed.definitions)
      in
        case selectedDefinition of
          Nothing ->
            (model, Cmd.none)
          
          Just definition ->
            ( { model | definitionUsed = definition }, Cmd.none)

    -- Used to start the game
    StartGame ->
      ( { model | startGame = True, showPopup = False }, Cmd.none )

    -- Used to update the user input
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
          if model.showAnswerBoxChecked then
            ( { model | userInput = input, userFoundword = wordFound}, Cmd.none )
          else
            ( { model | userInput = input, userFoundword = wordFound, score = model.score + 1  }, Cmd.none )
        else
          ( { model | userInput = input, userFoundword = wordFound }, Cmd.none )
    
    -- If the user checked the showAnswer box, we update the model to display the answer
    ShowAnswerBoxChecked ->
      ( { model | showAnswerBoxChecked = True }, Cmd.none )
    
    -- Used to quit the game
    QuitGame ->
      (clearModelIfQuit model, getWord model )       
    
    -- Used to start a new game, we reset the model and ask for a new word
    NewGame ->
      ( clearModelForNewGame model, getWord model)

getWord: Model -> Cmd Msg
getWord model =
  let
    randomNumber =
      Random.generate RandomNumberForWord (Random.int 0 (List.length model.wordsList - 1)) 
  in
    randomNumber


-- Used to get a random partofspeach from a meaning
getPartOfSpeach : JsonDecoder.Meaning -> Cmd Msg
getPartOfSpeach meaning =
  let
    randomNumber =
      Random.generate RandomNumberForPartOfSpeach (Random.int 0 (List.length meaning.meanings - 1))
  in
    randomNumber

-- Generates a random number to get a random definition from a partofspeach
getDefinition : JsonDecoder.PartOfSpeach -> Cmd Msg
getDefinition partofspeach =
  let
    randomNumber =
      Random.generate RandomNumberForDefinition (Random.int 0 (List.length partofspeach.definitions - 1))
  in
    randomNumber

clearModelForNewGame : Model -> Model
clearModelForNewGame model =
  { model | 
  wordToGuess = Nothing
  , meaningUsed = JsonDecoder.Meaning "" []
  , partOfSpeachUsed = JsonDecoder.PartOfSpeach "" []
  , definitionUsed = JsonDecoder.Definition "" [] []
  , userInput = ""
  , userFoundword = False
  , wordMeanings =  []
  , showAnswerBoxChecked = False
  , startGame = True}

clearModelIfQuit : Model -> Model
clearModelIfQuit model =
  { model | 
  wordToGuess = Nothing
  , meaningUsed = JsonDecoder.Meaning "" []
  , partOfSpeachUsed = JsonDecoder.PartOfSpeach "" []
  , definitionUsed = JsonDecoder.Definition "" [] []
  , userInput = ""
  , userFoundword = False
  , wordMeanings =  []
  , showAnswerBoxChecked = False
  , startGame = False}

  
  


-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none


-- VIEW


view : Model -> Html Msg
view model =
  div [] 
  [ main_ [class (getMainClass model)]
    [ -- Header
      header [class "header"]
      [ a [ href "#", class "logo" ] [ text "ELM." ]
      , nav [ class "navbar"]
        [ a [ href "#", class "active" ] [ text "Home" ]
        , a [ href "#"] [ text "About" ]
        , a [ href "#"] [ text "Contact" ]
        ]
      ]
      -- Container 
    , div [class "container"]
      -- Quiz Box, displayed when game is running
      [ section [class (getquizSectionClass model)]
        [ 
          div [ class (getQuizBoxClass model)]
            [ -- Quiz Header - Title, S
              h1 [] [ text "Guess it !" ]
              , div [class "quiz-header"]
                [ span [class "header-score"] [ text ("Score : " ++ String.fromInt model.score) ]
                , span [] [ text model.difficulty ]
                ]
              , h2 [ class "question-text"] [text "Try to find the word"]
              
              -- Div where the meanings of the word are displayed
              ,div [ class "option-list"]
                [ ul[] (viewMeanings model model.wordMeanings)]
              
              -- Div where the user can input his answer
              ,div [ class "quiz-input"]
                [ label [] [ text (if model.userFoundword then ("Got it! It is indeed " ++ (Maybe.withDefault ""model.wordToGuess)) else "") ]
                ,input [ value model.userInput, onInput UserInput, placeholder "Write your answer here"] []
                ]

              -- Footer of the quiz box, contains the buttons to show the answer and quit the game
              ,div [  class "quiz-footer"]
                [ button [class "show-answer-btn", onClick ShowAnswerBoxChecked ] [ text "Show Answer"]
                , button [class "quit-btn", onClick QuitGame] [ text "Quit"]
                ]                  
            ]
            -- Quiz Result, displayed when the user found the word or checked the showAnswer box
            , div [class (getQuizResultClass model)]
                [ h2 [] [ text (if model.showAnswerBoxChecked then "The Answer was :" else "Well Played !!")]
                , span [class "solution"] [text (Maybe.withDefault "?" model.wordToGuess)]
                , span [class "score"] [text ("Your Score : " ++ String.fromInt model.score)]
                , div [class "buttons"] 
                  [ button [class "go-Home-btn", onClick QuitGame] [ text "Go Home"]
                  , button [class "next", onClick NewGame] [ text "Next Word"]
                  ]
                ]
        ]
      -- Home Section, displayed when the game is not running
      , section [class "home"]
          [ div [class "home-content"]
            [ h1 [] [text "Guess it !"]
            , p [] [text "A game where you have to guess the word from its definition"]
            , button [onClick ShowPopup, class "start-btn"] [ text "Start Game" ]
            ]
          ]
      ]
    ]
  -- Popup, displayed when the user clicks on the start game button
  -- Contains the rules of the game and the difficulty choice
  , case model.showPopup of
      False ->
        text ""
      True ->
        div [ class "popup-info"]
          [ -- Rules
            h2 [] [ text "Rules" ]
          , span [class "info"] [ text "You have to guess the word from its definition" ]
          , span [class "info"] [ text "You can check the word if you are stuck" ]
          , span [class "info"] [ text "More options to come !" ]
          
          -- Difficulty choice
          , div [class "diff-choice"]
            [ h3 [] [ text "Choose your difficulty" ]
            , div [class "diff-btn-group"]
              [ button [class (getEasyBtnClass model), onClick SetDiffEasy] [ text "Easy" ]
              , button [class (getHardBtnClass model), onClick SetDiffHard] [ text "Hard" ]
              ]
            ]
          -- Buttons to exit the popup or start the game
          , div [class "btn-group"]
            [ button [onClick HidePopup, class "info-btn exit-btn"] [ text "Exit" ]
            , button [onClick StartGame, class "info-btn continue-btn"] [ text "Continue" ]
            ]
          ]
  ]

-- Used to get the class of the main element and adapt its display style
getMainClass : Model -> String
getMainClass model =
  case model.showPopup of
    False ->
      "main"
    True ->
      "main active"

-- Used to get the class of the quiz box and adapt its display style
getQuizBoxClass : Model -> String
getQuizBoxClass model =
  case model.startGame of
    False ->
      "quiz-box"
    True ->
      case model.showAnswerBoxChecked of
        False ->
          case model.userFoundword of
            False ->
              "quiz-box active"
            True ->
              "quiz-box"
        True ->
          "quiz-box"

-- Used to get the class of the buttons to choose the difficulty and adapt their display style
getEasyBtnClass : Model -> String
getEasyBtnClass model =
  case model.difficulty of
    "Easy" ->
      "diff-btn-easy active"
    "Hard" ->
      "diff-btn-easy"
    _ ->
      "diff-btn-easy"
getHardBtnClass : Model -> String
getHardBtnClass model =
  case model.difficulty of
    "Easy" ->
      "diff-btn-hard"
    "Hard" ->
      "diff-btn-hard active"
    _ ->
      "diff-btn-hard"

-- Used to get the class of the quiz section and adapt its display style
getquizSectionClass : Model -> String
getquizSectionClass model =
  case model.startGame of
    False ->
      "quiz-section"
    True ->
      "quiz-section active"

-- Used to get the class of the quiz result and adapt its display style
getQuizResultClass : Model -> String
getQuizResultClass model =
  case model.showAnswerBoxChecked of
    False ->
      case model.userFoundword of
        False ->
          "quiz-result"
        True ->
          "quiz-result active"
    True ->
      "quiz-result active"

-- Generates the HTML to display the meanings of a word in function of the difficulty
viewMeanings : Model -> List JsonDecoder.Meaning -> List (Html Msg)
viewMeanings model listMeaning =
  case model.difficulty of
    "Easy" ->
      viewMeaningsEasy listMeaning

    "Hard" ->
      viewMeaningsHard model.partOfSpeachUsed.partOfSpeech model.definitionUsed.definition
    _ ->
      viewMeaningsEasy listMeaning

-- Generates the HTML to display the meanings of a word in easy mode
viewMeaningsHard : String -> String -> List (Html Msg)
viewMeaningsHard partOfSpeach definition =
  [ h2 [class "random-def"] [ text (partOfSpeach ++ " : " ++ definition) ]]

-- Generates the HTML to display the meanings of a word in hard mode
viewMeaningsEasy : List JsonDecoder.Meaning -> List (Html Msg)
viewMeaningsEasy listMeaning =
  case listMeaning of
    [] ->
      [text ""]

    (meaning :: rest) ->
      [ li [ class "meaning"] 
        [ text "Meaning"
        , ol [ class "part-of-speach"] (viewPartOfSpeachs meaning.meanings)
        ]
      ] ++ viewMeaningsEasy rest

-- Generates the HTML to display all the partofspeach of a meaning
viewPartOfSpeachs : List JsonDecoder.PartOfSpeach -> List (Html Msg)
viewPartOfSpeachs partOfSpeachs =
  case partOfSpeachs of
    [] ->
      [text ""]

    (partOfSpeach :: rest) ->      
      
      [ li [] 
        [ text partOfSpeach.partOfSpeech
        , ol [ class "definition"] (viewDefinitions partOfSpeach.definitions)      
        ]
      ] ++ viewPartOfSpeachs rest

-- Generates the HTML to display all the definitions of a partofspeach
viewDefinitions : List JsonDecoder.Definition -> List (Html Msg)
viewDefinitions definitions =
  List.map (\definition -> li[] [text definition.definition]) definitions

-- HTTP


-- function load the list of words from the txt file
getWordsList : Cmd Msg
getWordsList =
  Http.get
    { url = "mots.txt"
    , expect = Http.expectString GotWordsList
    }

-- function to ask the API for the meanings of a word thanks to an HTTP request to dictionaryapi
askApi : String -> Cmd Msg
askApi word =
  Http.get
    { url = "https://api.dictionaryapi.dev/api/v2/entries/en/" ++ word
    , expect = Http.expectJson GotMeanings JsonDecoder.mainDecoder
    }
